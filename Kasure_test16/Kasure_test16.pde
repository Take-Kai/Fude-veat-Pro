import android.view.MotionEvent;

/*
Kasure_test15からの変更点
 ブラシ画像を重ねて押す方式をやめ, 筆が通った範囲のピクセルを1つずつ「墨が付くか」判定する方式に変更.

 - 画面に固定した「紙の凹凸（grain）」と, そのピクセルに当たる毛に残っている墨の量を比べ,
   墨の方が多い時だけ黒くする
 - 墨の量は0~1の連続値なので, 掠れかけの部分は紙の凹凸に沿ったザラザラになり,
   墨が減るほど「黒地に白い筋」から「白地に黒い毛の跡」へ少しずつ変わる
 - 紙の凹凸は画面に固定なので, 同じ場所を何度なぞっても模様が塗りつぶされない
 - 墨の濃さはinkBuf（画面サイズの配列）に計算し, 描き換えた範囲だけcanvasに反映する
   ※ PImageのupdatePixels(x, y, w, h)で一部だけ更新すると, Processing Androidのバグで落ちる
     （Texture.setが画面全体の配列を範囲の大きさの配列として扱ってしまう）.
     なので, 決まった大きさの小さい画像patchに範囲をコピーし, patch全体を更新してcanvasに貼る
 - 雫形はやめ, 入筆は筆圧の上がり方で太さを作る
 - とめは, その場で筆を押し付けて墨がたまった跡として描く

 ※ 線の幅方向の位置 u（-1 ~ 1）で, どの毛に当たるかを決めている.
   毛ごとの墨の量をnoiseで決め, 毛と毛の間は補間して「幅方向の墨の量」profileを作る.
*/

// 墨の層. 黒 + アルファ（墨の濃さ）. 画面と同じ大きさの配列で計算する
int[] inkBuf;
PGraphics canvas;  // 表示用. inkBufの描き換えた範囲だけここに反映する
PImage patch;      // inkBufの一部をcanvasに貼るための小さい画像
int patchSize = 128;
// 描き換えた範囲（まだcanvasに反映していない）
int dirtyX0, dirtyY0, dirtyX1, dirtyY1;
boolean dirty = false;

// 紙の凹凸. grainSize × grainSize を画面に敷き詰めて使う. 値は0~1に一様に分布
int grainSize = 256;
float[] grain;

// 毛のモデル
int maxBristles = 80;
int bristleCount = 36;
float[] bristleU = new float[maxBristles];     // 毛の位置（線の幅方向. -1 ~ 1）
float[] bristleSeed = new float[maxBristles];  // 毛ごとのnoiseの種
float bristleJitter = 0.35;   // 毛の位置のばらつき（毛の間隔に対する割合）
float crisp = 0.4;            // 0だと毛と毛の間をなめらかに補間, 1だと一番近い毛の値そのまま
float dryFreq = 1.0 / 150;    // 墨の量が変わる細かさ（小さいほど長い筋）
float dryFreqFine = 1.0 / 30; // 細かい途切れ
float fineAmount = 0.3;       // 細かい途切れの割合
float levelVariation = 2.0;   // 毛ごとの墨の量のばらつき
float driftFreq = 1.0 / 300;  // 毛が揺れる細かさ
float driftAmp = 0.04;        // 毛が揺れる大きさ（線の幅に対する割合）
float sideBias = 0.25;        // 片側だけ少し掠れやすくする強さ
float innerWeight = 0.7;      // 内側の毛の掠れやすさ（全体の掠れの強さ）
float contourWidth = 0.12;    // 輪郭として掠れにくくする幅（線の幅の片側に対する割合）
float contourDry = 0.3;       // 輪郭の毛の掠れやすさ（1で内側と同じ）. 書道の掠れは輪郭がはっきりしているものが多い
float contourFadeStart = 0.4; // 掠れやすさがこれを超えると, 輪郭も少しずつ掠れるようになる
float contourFadeEnd = 1.0;   // 掠れやすさがこれを超えると, 輪郭も内側と同じように掠れる
                              // （墨が少ない時まで輪郭だけ残ると, 中が空洞の線になってしまうため）
float entryWetLength = 60;    // 書き始めからこの距離までは掠れにくい

// 幅方向の墨の量（線分の始点と終点）
int profileRes = 128;
float[] prof1 = new float[profileRes];
float[] prof2 = new float[profileRes];

// 細い毛1本1本のムラ. 紙の凹凸だけだと掠れがザラザラ（木炭のよう）になるので,
// 運筆方向に長く伸びるムラを混ぜて, 掠れが筆の毛の跡（細い筋）になるようにする
float[] hairVal = new float[profileRes];
float[] hairSeed = new float[profileRes];
float[] hair1 = new float[profileRes];
float[] hair2 = new float[profileRes];
float hairFreq = 1.0 / 40;  // 毛の跡が途切れる細かさ
float hairBreak = 0.8;      // 毛の跡の途切れやすさ
float paperWeight = 0.35;   // 紙の凹凸の割合（残りは毛のムラ）

// 墨の付き方
float softK = 6;      // 墨の濃さの立ち上がり（大きいほどくっきり, 小さいほどぼんやり）
float edgeRough = 0;  // 線の縁を紙の凹凸でガタガタさせる幅（px）. 0で輪郭がはっきりする


// 墨
float inkAmount = 1.0;
float inkDecay = 0.0004;
float inkDry = 1.0;          // 墨が空の時の掠れやすさ
float speedSmoothed = 0;     // 1フレームあたりの移動量（なめらかにしたもの）
float speedDryMin = 15;      // この速さから掠れ始める（px/frame）
float speedDryFull = 60;     // この速さで速さによる掠れが最大
float speedDryMax = 0.4;     // 速さによる掠れの最大値

// 運筆方向による太さの変化
float nibAngle = radians(30);  // 筆の穂の向き
float nibInfluence = 0.35;     // 太さが変わる割合

// ブラシの角度
float brushAngle = 0;     // 線の幅方向を決める角度（折り返しで反転しないようにPI単位でたたんである）
float motionAngle = 0;    // 実際の運筆方向
float turnRate = 0;       // 1pxあたりの曲がり具合
float angleEasing = 0.2;  // 角度の追従しやすさ
boolean angleInitialized = false;

float px, py;  // 前のマウス位置
boolean first = true;  // 最初のクリックで初期化するためのフラグ

// 筆圧検知用
float pressure = 0;
float touchSize = 0;
boolean stopped = false;
int stopTime = 0;
int stopTimeThreshold = 500;
float stopThreshold = 0.16;
float moveThreshold = 2;
int pmillis = 0;
int lastTouchTime = 0;

// ストローク
int strokeFrameCount = 0;
float strokeLength = 0;   // ストローク内で進んだ距離（noiseの入力）
float lastBrushSize = 0;
float lastWidth = -1;

// とめ
boolean stopRequested = false;
float stopX, stopY, stopR;
float stopWet = -0.15;  // とめは墨がたまるので少し掠れにくくする

// はね・はらい
boolean tailRequested = false;
float tailX, tailY, tailAngle, tailTurn, tailSize, tailSpeed;
float tailMinSpeed = 6;     // これより速く離したら抜く（px/frame）
float tailSpeedFactor = 3;  // 抜く長さ = 速さ × これ
float tailMaxRatio = 1.5;   // 抜く長さの上限（ブラシの大きさに対する割合）
float tailSegLen = 6;
float tailDryExtra = 0.6;   // 抜けの先ほど掠れる

// ブラシの大きさ
int brushSizePx = 70;

// スライダー用
float sliderDry = 0.4;     // 墨満タンでの掠れやすさ
float sliderCoarse = 0.4;  // 毛の粗さ（右ほど毛が少なく太い筋になる）
boolean draggingDry = false;
boolean draggingCoarse = false;
float uiX, uiW, uiY1, uiY2;

// ボタン
float clearBtnX, clearBtnY, inkBtnX, inkBtnY;
float btnW = 220;
float btnH = 80;


void setup() {
  fullScreen(P3D);
  background(255);

  initInk();
  initCanvas();

  clearBtnX = width * 0.7;
  clearBtnY = height * 0.9;
  inkBtnX = width * 0.5;
  inkBtnY = height * 0.9;
}


// 墨の層と紙の凹凸を用意する
void initInk() {
  inkBuf = new int[width * height];
  createGrain();
}


// 表示用のcanvasを用意する
void initCanvas() {
  canvas = createGraphics(width, height, P3D);
  canvas.beginDraw();
  canvas.clear();
  canvas.endDraw();
  patch = createImage(patchSize, patchSize, ARGB);
}


// 描き換えた範囲を記録する
void markDirty(int x0, int y0, int x1, int y1) {
  if (!dirty) {
    dirtyX0 = x0; dirtyY0 = y0; dirtyX1 = x1; dirtyY1 = y1;
    dirty = true;
  } else {
    dirtyX0 = min(dirtyX0, x0); dirtyY0 = min(dirtyY0, y0);
    dirtyX1 = max(dirtyX1, x1); dirtyY1 = max(dirtyY1, y1);
  }
}


// 描き換えた範囲をpatchSizeごとに区切ってcanvasに貼る
void flushDirty() {
  if (!dirty) return;
  dirty = false;

  canvas.beginDraw();
  canvas.blendMode(REPLACE);  // 重ねて濃くならないように, そのまま置き換える
  canvas.noStroke();
  canvas.textureMode(IMAGE);

  for (int ty = dirtyY0; ty <= dirtyY1; ty += patchSize) {
    for (int tx = dirtyX0; tx <= dirtyX1; tx += patchSize) {
      int tw = min(patchSize, dirtyX1 - tx + 1);
      int th = min(patchSize, dirtyY1 - ty + 1);

      patch.loadPixels();
      for (int row = 0; row < th; row++) {
        arrayCopy(inkBuf, (ty + row) * width + tx, patch.pixels, row * patchSize, tw);
      }
      patch.updatePixels();  // patch全体を更新する（一部だけの更新はバグで落ちる）

      canvas.beginShape(QUADS);
      canvas.texture(patch);
      canvas.vertex(tx, ty, 0, 0);
      canvas.vertex(tx + tw, ty, tw, 0);
      canvas.vertex(tx + tw, ty + th, tw, th);
      canvas.vertex(tx, ty + th, 0, th);
      canvas.endShape();
      canvas.flush();  // 次にpatchを書き換える前に確定させる
    }
  }

  canvas.blendMode(BLEND);
  canvas.endDraw();
}


void draw() {
  background(255);
  image(canvas, 0, 0);  // 墨の層を表示

  uiX = width * 0.05;
  uiW = width * 0.4;
  uiY1 = height * 0.85;
  uiY2 = height * 0.92;

  drawSlider(uiX, uiY1, uiW, sliderDry, "dryness");
  drawSlider(uiX, uiY2, uiW, sliderCoarse, "coarseness");
  drawButton(clearBtnX, clearBtnY, "CLEAR");
  drawButton(inkBtnX, inkBtnY, "INK");
  drawInkMeter();

  if (mousePressed && overButton(clearBtnX, clearBtnY)) {
    clearCanvas();
    return;
  }
  if (mousePressed && overButton(inkBtnX, inkBtnY)) {
    inkAmount = 1.0;  // 墨をつける
  }

  if (mousePressed && !isOverUI()) {
    if (first) {
      beginStroke(mouseX, mouseY);
      first = false;
    }

    drawLineWithBrush(px, py, mouseX, mouseY);
    px = mouseX;
    py = mouseY;
  } else {
    first = true;  // 離したら次回の初回処理をリセット
  }

  // とめ・はね・はらいが予約されていたら描く
  if (stopRequested) {
    pressAt(stopX, stopY, stopR);
    stopRequested = false;
  }
  if (tailRequested) {
    drawTail();
    tailRequested = false;
  }

  // このフレームで描き換えた範囲をcanvasに反映する（次のフレームで表示される）
  flushDirty();
}


// ストロークの始まり. 毛を作り直して毎回違う掠れにする
void beginStroke(float x, float y) {
  px = x;
  py = y;
  strokeFrameCount = 0;
  strokeLength = 0;
  speedSmoothed = 0;
  lastWidth = -1;
  angleInitialized = false;
  initBristles();
}


// 紙の凹凸を作る. 細かい凹凸 + 少し大きいムラ + ほんの少しのランダム
// 端と端がつながるように4か所の値を混ぜ, 最後に0~1に一様に分布するように直す
void createGrain() {
  int T = grainSize;
  grain = new float[T * T];

  for (int y = 0; y < T; y++) {
    for (int x = 0; x < T; x++) {
      float wx = x / float(T);
      float wy = y / float(T);
      float v = grainRaw(x, y) * (1 - wx) * (1 - wy)
              + grainRaw(x - T, y) * wx * (1 - wy)
              + grainRaw(x, y - T) * (1 - wx) * wy
              + grainRaw(x - T, y - T) * wx * wy;
      grain[y * T + x] = v + random(-0.04, 0.04);
    }
  }

  // ヒストグラムで0~1に一様に分布させる
  // こうすると「墨の量0.3 = 3割のピクセルに墨が付く」になる
  float mn = 1e9, mx = -1e9;
  for (int i = 0; i < grain.length; i++) {
    mn = min(mn, grain[i]);
    mx = max(mx, grain[i]);
  }
  int bins = 1024;
  int[] hist = new int[bins];
  for (int i = 0; i < grain.length; i++) {
    int b = constrain(int((grain[i] - mn) / (mx - mn) * (bins - 1)), 0, bins - 1);
    hist[b]++;
  }
  float[] cdf = new float[bins];
  int acc = 0;
  for (int b = 0; b < bins; b++) {
    acc += hist[b];
    cdf[b] = acc / float(grain.length);
  }
  for (int i = 0; i < grain.length; i++) {
    int b = constrain(int((grain[i] - mn) / (mx - mn) * (bins - 1)), 0, bins - 1);
    grain[i] = cdf[b];
  }
}


float grainRaw(float x, float y) {
  return 0.65 * noise(x * 0.35, y * 0.35) + 0.35 * noise(x * 0.07 + 100, y * 0.07 + 100);
}


// 毛の位置とnoiseの種を決める
void initBristles() {
  bristleCount = constrain(round(map(sliderCoarse, 0, 1, 56, 14)), 2, maxBristles);
  float spacing = 2.0 / bristleCount;
  for (int j = 0; j < bristleCount; j++) {
    bristleU[j] = -1 + spacing * (j + 0.5) + random(-bristleJitter, bristleJitter) * spacing;
    bristleSeed[j] = random(10000);
  }
  for (int k = 0; k < profileRes; k++) {
    hairVal[k] = random(1);
    hairSeed[k] = random(10000);
  }
}


// 距離sの地点での細い毛のムラ（0~1）をoutに入れる
void computeHair(float[] out, float s) {
  for (int k = 0; k < profileRes; k++) {
    out[k] = constrain(hairVal[k] + (noise(hairSeed[k], s * hairFreq) - 0.5) * hairBreak, 0, 1);
  }
}


// 今の掠れやすさ. 0で掠れなし, 1を超えるとほとんどの毛が掠れる
float currentDryness() {
  float base = map(sliderDry, 0, 1, 0, 0.6);
  // 墨が多いうちはほとんど掠れず, 少なくなってから急に掠れる
  float ink = pow(1 - inkAmount, 2) * inkDry;
  float speed = constrain(map(speedSmoothed, speedDryMin, speedDryFull, 0, speedDryMax), 0, speedDryMax);
  return base + ink + speed;
}


// 掠れを生成する処理. ここ大事
// 距離sの地点での, 線の幅方向の墨の量（0~1）をoutに入れる
float[] levelTmp = new float[maxBristles];
float[] posTmp = new float[maxBristles];

void computeProfile(float[] out, float s, float dry) {
  // 墨が少なくなるほど, 輪郭を守る効果を弱める
  float cDry = lerp(contourDry, 1, constrain(map(dry, contourFadeStart, contourFadeEnd, 0, 1), 0, 1));
  // 書き始めは少しだけ墨が付きやすい. 強くしすぎると墨が少ない時に頭だけ黒い丸になる
  float entry = 0.75 + 0.25 * constrain(s / entryWetLength, 0, 1);

  // 毛ごとの位置と墨の量
  for (int j = 0; j < bristleCount; j++) {
    float u = bristleU[j] + (noise(bristleSeed[j] + 500, s * driftFreq) - 0.5) * 2 * driftAmp;
    // 縁の毛ほど掠れやすい
    // 輪郭の毛は掠れにくく, 内側の毛は掠れやすい. 片側だけ少し強く
    float inner = constrain((1 - abs(u)) / contourWidth, 0, 1);
    float weight = innerWeight * lerp(cDry, 1, inner) * (1 + sideBias * u);
    float n = (1 - fineAmount) * noise(bristleSeed[j], s * dryFreq)
            + fineAmount * noise(bristleSeed[j] + 77.7, s * dryFreqFine);
    posTmp[j] = u;
    // 1を超える分は「墨に余裕がある」. 本物の墨は, かなり減るまで真っ黒のまま
    levelTmp[j] = constrain(1.6 - dry * weight * 2.0 * entry + (n - 0.5) * levelVariation, 0, 1);
  }

  // 幅方向の各位置で, 左右の一番近い毛の値を補間する
  for (int k = 0; k < profileRes; k++) {
    float u = -1 + 2 * k / float(profileRes - 1);
    int L = -1, R = -1;
    float dL = 1e9, dR = 1e9;
    for (int j = 0; j < bristleCount; j++) {
      float d = posTmp[j] - u;
      if (d <= 0 && -d < dL) { dL = -d; L = j; }
      if (d >= 0 && d < dR) { dR = d; R = j; }
    }
    float v;
    if (L < 0) v = levelTmp[R];
    else if (R < 0) v = levelTmp[L];
    else if (L == R) v = levelTmp[L];
    else {
      float t = dL / (dL + dR);
      float smooth = lerp(levelTmp[L], levelTmp[R], t);
      float nearest = (t < 0.5) ? levelTmp[L] : levelTmp[R];
      v = lerp(smooth, nearest, crisp);
    }
    out[k] = v;
  }
}


// 線分(x1, y1)-(x2, y2)を筆が通った時に, 範囲内のピクセルに墨を付ける
// w1, w2は始点と終点の線の幅, s1, s2は始点と終点のストローク内の距離
// dry1, dry2は追加の掠れやすさ（マイナスだと掠れにくい）
void depositSegment(float x1, float y1, float x2, float y2, float w1, float w2,
                    float s1, float s2, float dry1, float dry2) {
  float base = currentDryness();
  computeProfile(prof1, s1, base + dry1);
  computeProfile(prof2, s2, base + dry2);
  computeHair(hair1, s1);
  computeHair(hair2, s2);

  float len = dist(x1, y1, x2, y2);
  float ex = 1, ey = 0;
  if (len > 0.001) {
    ex = (x2 - x1) / len;
    ey = (y2 - y1) / len;
  }
  // 線の幅方向. ブラシの角度から決めるので, 折り返しても毛の並びが反転しない
  float nx = -sin(brushAngle);
  float ny = cos(brushAngle);

  float maxR = max(w1, w2) / 2 + 1;
  int bx0 = max(0, floor(min(x1, x2) - maxR));
  int bx1 = min(width - 1, ceil(max(x1, x2) + maxR));
  int by0 = max(0, floor(min(y1, y2) - maxR));
  int by1 = min(height - 1, ceil(max(y1, y2) + maxR));
  if (bx0 > bx1 || by0 > by1) return;

  int[] pix = inkBuf;
  float sharp = 1 + 1 / softK;  // 墨の量1で必ず真っ黒になるように

  for (int y = by0; y <= by1; y++) {
    for (int x = bx0; x <= bx1; x++) {
      float dx = x + 0.5 - x1;
      float dy = y + 0.5 - y1;

      // 線分上の一番近い点
      float t = (len > 0.001) ? (dx * ex + dy * ey) / len : 0;
      float tc = constrain(t, 0, 1);
      float rx = x + 0.5 - (x1 + (x2 - x1) * tc);
      float ry = y + 0.5 - (y1 + (y2 - y1) * tc);
      float r = sqrt(rx * rx + ry * ry);
      float hw = lerp(w1, w2, tc) * 0.5;
      if (r > hw || hw < 0.5) continue;

      // 縁を紙の凹凸でガタガタさせる（edgeRoughが0なら何もしない）
      float paper = grain[(y % grainSize) * grainSize + (x % grainSize)];
      if (edgeRough > 0 && r > hw - min(edgeRough, hw * 0.3) * paper) continue;

      // 線の幅方向のどこに当たるか -> どの毛か
      float u = constrain((rx * nx + ry * ny) / hw, -1, 1);
      int k = int((u + 1) * 0.5 * (profileRes - 1));
      float c = lerp(prof1[k], prof2[k], tc);


      // 紙の凹凸 + 毛のムラ より墨の量が多ければ墨が付く
      float hair = lerp(hair1[k], hair2[k], tc);
      float g = paperWeight * paper + (1 - paperWeight) * hair;
      float a = constrain((c * sharp - g) * softK, 0, 1);
      a *= constrain(hw - r, 0, 1);  // 輪郭の1pxだけなめらかに（ギザギザ防止）
      if (a <= 0) continue;

      int na = int(a * 255);
      int idx = y * width + x;
      if (na > (pix[idx] >>> 24)) {
        pix[idx] = na << 24;  // 黒 + アルファ
      }
    }
  }

  markDirty(bx0, by0, bx1, by1);
}


// 筆圧からブラシの大きさを求める
float sizeFromPressure(float pr) {
  float p = constrain(pr, 0.08, 0.21);
  // float p = constrain(touchSize, 0.0117, 0.09);  // 接触面積用
  return brushSizePx * map(p, 0.08, 0.21, 0.02, 1.5);
}


// 運筆方向による線の幅の倍率
float widthScale() {
  return 1 - nibInfluence + nibInfluence * abs(sin(brushAngle - nibAngle));
}


// currentからtargetへの差を-PI/2 ~ PI/2に収める
// 180°回すと毛の並びが反転してしまうため
float foldedDiff(float current, float target) {
  float diff = atan2(sin(target - current), cos(target - current));
  if (diff > HALF_PI) diff -= PI;
  if (diff < -HALF_PI) diff += PI;
  return diff;
}


// 運筆方向, ブラシの角度, 曲がり具合を更新する
void updateMotion(float dx, float dy) {
  float d = dist(0, 0, dx, dy);
  if (d < 2.5) return;  // 手振れ対策. 小さい動きでは角度を変えない

  float a = atan2(dy, dx);
  if (!angleInitialized) {
    brushAngle = a;
    motionAngle = a;
    turnRate = 0;
    angleInitialized = true;
    return;
  }

  float dA = atan2(sin(a - motionAngle), cos(a - motionAngle));
  turnRate = lerp(turnRate, dA / d, 0.3);
  motionAngle = a;

  brushAngle += foldedDiff(brushAngle, a) * angleEasing;
}


// 前の位置から今の位置まで筆を動かす
void drawLineWithBrush(float x1, float y1, float x2, float y2) {
  float d = dist(x1, y1, x2, y2);
  speedSmoothed = lerp(speedSmoothed, d, 0.3);

  // 墨を減らす. 筆圧が強いほど早く減る
  float pInk = constrain(pressure, 0.08, 0.21);
  inkAmount -= d * inkDecay * map(pInk, 0.08, 0.21, 0.4, 1.0);
  inkAmount = constrain(inkAmount, 0, 1);

  updateMotion(x2 - x1, y2 - y1);

  float brushSize = sizeFromPressure(pressure);
  float w = brushSize * widthScale();
  if (lastWidth < 0) lastWidth = w;

  depositSegment(x1, y1, x2, y2, lastWidth, w, strokeLength, strokeLength + d, 0, 0);

  strokeLength += d;
  lastWidth = w;
  lastBrushSize = brushSize;
  strokeFrameCount++;
}


// その場で筆を押し付けた跡（とめ）
// 真円だと貼り付けた図形のように見えるので, 運筆方向に少しだけ伸ばした形にする
void pressAt(float x, float y, float R) {
  float ex = cos(motionAngle);
  float ey = sin(motionAngle);
  depositSegment(x - ex * R * 0.4, y - ey * R * 0.4, x + ex * R * 0.15, y + ey * R * 0.15,
                 R * 1.9, R * 2, strokeLength, strokeLength + R * 0.55, stopWet, stopWet);
}


// はね・はらい. 離した時の向きと曲がり具合のまま, 細くしながら少し先まで筆を動かす
void drawTail() {
  float len = constrain(tailSpeed * tailSpeedFactor, 0, tailSize * tailMaxRatio);
  if (len < 4 || tailSize < 2) return;

  float x = tailX;
  float y = tailY;
  float a = tailAngle;
  int segs = max(1, int(len / tailSegLen));

  for (int k = 0; k < segs; k++) {
    float t0 = k / float(segs);
    float t1 = (k + 1) / float(segs);
    a += constrain(tailTurn, -0.03, 0.03) * tailSegLen;
    float x2 = x + cos(a) * tailSegLen;
    float y2 = y + sin(a) * tailSegLen;

    brushAngle += foldedDiff(brushAngle, a);
    float w1 = tailSize * widthScale() * pow(1 - t0, 1.3);
    float w2 = tailSize * widthScale() * pow(1 - t1, 1.3);
    depositSegment(x, y, x2, y2, w1, w2, strokeLength, strokeLength + tailSegLen,
                   t0 * tailDryExtra, t1 * tailDryExtra);

    strokeLength += tailSegLen;
    x = x2;
    y = y2;
  }
}


void drawSlider(float x, float y, float w, float value, String label) {
  stroke(0);
  line(x, y, x + w, y);

  float knobX = x + w * value;
  fill(0);
  ellipse(knobX, y, 40, 40);

  fill(0);
  textSize(32);
  text(label + ": " + nf(value, 1, 2), x,  y - 20);
}


// 墨の残量を表示
void drawInkMeter() {
  float mx = width * 0.5;
  float my = height * 0.85;
  float mw = width * 0.15;
  float mh = 30;

  noFill();
  stroke(0);
  rect(mx, my, mw, mh);
  noStroke();
  fill(0);
  rect(mx, my, mw * inkAmount, mh);

  textSize(32);
  text("ink: " + nf(inkAmount, 1, 2), mx, my - 20);
}


void drawButton(float x, float y, String label) {
  noStroke();
  fill(0);
  rect(x, y, btnW, btnH, 20);

  fill(255);
  textSize(28);
  textAlign(CENTER, CENTER);
  text(label, x + btnW/2, y + btnH/2);

  textAlign(LEFT, BASELINE);
}


boolean overButton(float x, float y) {
  return mouseX > x && mouseX < x + btnW &&
         mouseY > y && mouseY < y + btnH;
}


void touchStarted() {
  if (overKnob(uiX, uiY1, uiW, sliderDry)) draggingDry = true;
  if (overKnob(uiX, uiY2, uiW, sliderCoarse)) draggingCoarse = true;
}


void touchMoved() {
  if (isOverUI()) {
    if (draggingDry) {
      sliderDry = constrain((mouseX - uiX) / uiW, 0, 1);
    }
    if (draggingCoarse) {
      sliderCoarse = constrain((mouseX - uiX) / uiW, 0, 1);
    }
    return;
  }

  if (pressure >= stopThreshold && dist(pmouseX, pmouseY, mouseX, mouseY) < moveThreshold) {
    stopTime += millis() - pmillis;
  } else {
    stopTime = 0;
  }

  if (stopTime > stopTimeThreshold && !stopped) {
    // ここでは描かずに予約だけする（描画はdraw内）
    stopR = sizeFromPressure(pressure) * widthScale() * 0.5 * 1.05;
    stopX = mouseX;
    stopY = mouseY;
    stopRequested = true;
    stopped = true;
  }

  pmillis = millis();
  lastTouchTime = millis();
}


void touchEnded() {
  // 速く離した時ははね・はらいとして少し先まで抜く（とめた時は抜かない）
  if (!stopped && angleInitialized && strokeFrameCount > 2 && speedSmoothed > tailMinSpeed && !isOverUI()) {
    tailX = px;
    tailY = py;
    tailAngle = motionAngle;
    tailTurn = turnRate;
    tailSize = lastBrushSize;
    tailSpeed = speedSmoothed;
    tailRequested = true;
  }

  stopped = false;
  stopTime = 0;
  // 墨は画をまたいで減っていくので, ここではリセットしない（INKボタンで補充）

  draggingDry = false;
  draggingCoarse = false;
}


boolean overKnob(float x, float y, float w, float value) {
  float knobX = x + w * value;
  return dist(mouseX, mouseY, knobX, y) < width * 0.03;
}


boolean isOverUI() {
  return (mouseY > height * 0.8);
}


void clearCanvas() {
  for (int i = 0; i < inkBuf.length; i++) {
    inkBuf[i] = 0;
  }
  dirty = false;
  canvas.beginDraw();
  canvas.clear();
  canvas.endDraw();
}


// この関数で全てのタッチイベントを手動で管理
boolean surfaceTouchEvent(MotionEvent event) {
  pressure = event.getPressure();
  touchSize = event.getSize();

  int action = event.getAction();
  switch (action) {
    case MotionEvent.ACTION_DOWN:
      stopped = false;  // タッチ開始時にフラグをリセット
      stopTime = 0;
      pmillis = millis();
      // ストロークの初期化はdraw内のbeginStroke()で行う
      break;

    // ACTION_MOVE / ACTION_UP では touchMoved() / touchEnded() を直接呼ばない
    // 下の super.surfaceTouchEvent() を通すとProcessingが描画スレッドで呼んでくれる
  }

  return super.surfaceTouchEvent(event);
}
