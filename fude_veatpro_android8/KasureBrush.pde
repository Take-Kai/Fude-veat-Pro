// 掠れ線を描く処理（Kasure_test16の方式）
//
// 筆が通った範囲のピクセルを1つずつ「墨が付くか」判定する.
// 画面に固定した「紙の凹凸」+「毛1本ごとのムラ」と, そのピクセルに当たる毛に残っている墨の量を比べ,
// 墨の方が多い時だけ黒くする.
//
// 掠れ線にするかどうかの判定は scene_play.pde（kasure / noink_kasure）のまま.
// 掠れの強さはKasure_test16ではスライダーで決めていたが, ここでは墨残量メーター（ink_meter）から決める.
//
// 描画について
//  - 墨の濃さはinkBuf（画面サイズの配列）に計算し, 描き換えた範囲だけ画面に描く
//  - このシステムは画面に直接描き重ねていくので, 同じ範囲を毎フレーム描き直すと半透明の部分が濃くなってしまう.
//    なので, 画面にすでに描いた濃さ（shownBuf）を覚えておき, 増えた分だけを描く
//  - PImageのupdatePixels(x, y, w, h)で一部だけ更新するとProcessing Androidのバグで落ちるので,
//    決まった大きさの小さい画像patchにコピーし, patch全体を更新して描く


// 墨の層
int[] inkBuf;        // 黒 + アルファ（墨の濃さ）. 画面と同じ大きさ
byte[] shownBuf;     // 画面にすでに描いた墨の濃さ
PImage patch;        // inkBufの一部を画面に描くための小さい画像
int patchSize = 128;
int dirtyX0, dirtyY0, dirtyX1, dirtyY1;  // 描き換えた範囲（まだ画面に描いていない）
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
float entryWetLength = 60;    // 書き始めからこの距離までは掠れにくい

// 幅方向の墨の量（線分の始点と終点）
int profileRes = 128;
float[] prof1 = new float[profileRes];
float[] prof2 = new float[profileRes];
float[] levelTmp = new float[maxBristles];
float[] posTmp = new float[maxBristles];

// 細い毛1本1本のムラ（運筆方向に長く伸びる）
float[] hairVal = new float[profileRes];
float[] hairSeed = new float[profileRes];
float[] hair1 = new float[profileRes];
float[] hair2 = new float[profileRes];
float hairFreq = 1.0 / 40;  // 毛の跡が途切れる細かさ
float hairBreak = 0.8;      // 毛の跡の途切れやすさ
float paperWeight = 0.35;   // 紙の凹凸の割合（残りは毛のムラ）

// 墨の付き方
float softK = 6;  // 墨の濃さの立ち上がり（大きいほどくっきり, 小さいほどぼんやり）

// 掠れの強さ. Kasure_test16のスライダーの代わりに, 墨残量メーターから毎フレーム決める
float sliderDry = 0;       // 掠れやすさ（0~1）
float sliderCoarse = 0.3;  // 毛の粗さ（0~1. 大きいほど毛が少なく太い筋になる）
float dryMax = 1.4;        // sliderDryが1の時の掠れやすさ
float dryAtKasureStart = 0.3;     // 墨の減りで掠れ線になった直後のsliderDry
float coarseAtKasureStart = 0.3;  // 墨の減りで掠れ線になった直後のsliderCoarse
float coarseAtEmpty = 0.7;        // 墨が空の時のsliderCoarse
float kasureDistance = 6000;      // scene_play.pdeで, この距離を超えると掠れ線になる
float noInkDistance = 18000;      // scene_play.pdeで, この距離で墨が空になる

// 速さによる掠れ. scene_play.pdeでは速さ170を超えると掠れ線になる
float kasureSpeed = 0;
float speedDryMin = 80;    // この速さから掠れ始める（px/frame）
float speedDryFull = 250;  // この速さで速さによる掠れが最大
float speedDryMax = 1.0;   // 速さによる掠れの最大値

// ブラシの角度
float brushAngle = 0;     // 線の幅方向を決める角度（折り返しで反転しないようにPI単位でたたんである）
float motionAngle = 0;    // 実際の運筆方向
float angleEasing = 0.2;  // 角度の追従しやすさ
boolean angleInitialized = false;

float kasureS = 0;  // ストローク内で進んだ距離（noiseの入力）


// setupで呼ぶ
void initKasure() {
  inkBuf = new int[width * height];
  shownBuf = new byte[width * height];
  patch = createImage(patchSize, patchSize, ARGB);
  createGrain();
}


// 画面をリセットした時に呼ぶ
void clearKasureLayer() {
  if (inkBuf == null) return;
  for (int i = 0; i < inkBuf.length; i++) {
    inkBuf[i] = 0;
    shownBuf[i] = 0;
  }
  dirty = false;
}


// 墨残量メーターから掠れの強さを決める（Kasure_test16のスライダーの代わり）
void updateKasureSliders() {
  float r = constrain(ink_meter / 700.0, 0, 1);  // 1:満タン, 0:空
  float rStart = 1 - kasureDistance / noInkDistance;  // 墨の減りで掠れ線になる時の残量
  if (r >= rStart) {
    // まだ墨がある. 掠れ線になるのは速く書いた時だけ
    sliderDry = 0;
    sliderCoarse = coarseAtKasureStart;
  } else {
    float t = 1 - r / rStart;  // 0（掠れ始め）~ 1（空）
    sliderDry = lerp(dryAtKasureStart, 1, t);
    sliderCoarse = lerp(coarseAtKasureStart, coarseAtEmpty, t);
  }
}


// ストロークの始まりに呼ぶ. 毛を作り直して毎回違う掠れにする
void kasureBeginStroke() {
  kasureS = 0;
  angleInitialized = false;
  updateKasureSliders();
  initBristles();
}


// 毎フレーム, 筆が動いた量を渡す（掠れ線を描かないフレームでも呼ぶ）
void kasureMove(float dx, float dy) {
  updateMotion(dx, dy);
  kasureS += dist(0, 0, dx, dy);
}


// 掠れ線を1フレーム分描く. w1, w2は始点と終点の線の太さ
void kasureSegment(float x1, float y1, float x2, float y2, float w1, float w2, float speed) {
  kasureSpeed = speed;
  updateKasureSliders();
  float d = dist(x1, y1, x2, y2);
  depositSegment(x1, y1, x2, y2, w1, w2, max(0, kasureS - d), kasureS, 0, 0);
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


// 今の掠れやすさ. 0で掠れなし, 1を超えるとほとんどの毛が掠れる
float currentDryness() {
  float base = sliderDry * dryMax;
  float speed = constrain(map(kasureSpeed, speedDryMin, speedDryFull, 0.2, speedDryMax), 0, speedDryMax);
  return base + speed;
}


// 距離sの地点での細い毛のムラ（0~1）をoutに入れる
void computeHair(float[] out, float s) {
  for (int k = 0; k < profileRes; k++) {
    out[k] = constrain(hairVal[k] + (noise(hairSeed[k], s * hairFreq) - 0.5) * hairBreak, 0, 1);
  }
}


// 距離sの地点での, 線の幅方向の墨の量（0~1）をoutに入れる
void computeProfile(float[] out, float s, float dry) {
  // 墨が少なくなるほど, 輪郭を守る効果を弱める
  float cDry = lerp(contourDry, 1, constrain(map(dry, contourFadeStart, contourFadeEnd, 0, 1), 0, 1));
  // 書き始めは少しだけ墨が付きやすい
  float entry = 0.75 + 0.25 * constrain(s / entryWetLength, 0, 1);

  // 毛ごとの位置と墨の量
  for (int j = 0; j < bristleCount; j++) {
    float u = bristleU[j] + (noise(bristleSeed[j] + 500, s * driftFreq) - 0.5) * 2 * driftAmp;
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

      // 線の幅方向のどこに当たるか -> どの毛か
      float u = constrain((rx * nx + ry * ny) / hw, -1, 1);
      int k = int((u + 1) * 0.5 * (profileRes - 1));
      float c = lerp(prof1[k], prof2[k], tc);

      // 紙の凹凸 + 毛のムラ より墨の量が多ければ墨が付く
      float paper = grain[(y % grainSize) * grainSize + (x % grainSize)];
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


// 描き換えた範囲の「増えた墨」だけを画面に描く. play()の最後で毎フレーム呼ぶ
void flushKasure() {
  if (!dirty) return;
  dirty = false;

  for (int ty = dirtyY0; ty <= dirtyY1; ty += patchSize) {
    for (int tx = dirtyX0; tx <= dirtyX1; tx += patchSize) {
      int tw = min(patchSize, dirtyX1 - tx + 1);
      int th = min(patchSize, dirtyY1 - ty + 1);

      patch.loadPixels();
      for (int row = 0; row < th; row++) {
        int idx = (ty + row) * width + tx;
        int pidx = row * patchSize;
        for (int col = 0; col < tw; col++) {
          int a = inkBuf[idx] >>> 24;
          int shown = shownBuf[idx] & 0xFF;
          int v = 0;
          if (a > shown) {
            // すでに描いた濃さshownの上に重ねて, 合計がaになる濃さ
            v = (a - shown) * 255 / (255 - shown);
            shownBuf[idx] = (byte) a;
          }
          patch.pixels[pidx] = v << 24;
          idx++;
          pidx++;
        }
      }
      patch.updatePixels();  // patch全体を更新する（一部だけの更新はバグで落ちる）

      image(patch, tx, ty, tw, th, 0, 0, tw, th);
    }
  }
}


// currentからtargetへの差を-PI/2 ~ PI/2に収める
// 180°回すと毛の並びが反転してしまうため
float foldedDiff(float current, float target) {
  float diff = atan2(sin(target - current), cos(target - current));
  if (diff > HALF_PI) diff -= PI;
  if (diff < -HALF_PI) diff += PI;
  return diff;
}


// 運筆方向とブラシの角度を更新する
void updateMotion(float dx, float dy) {
  float d = dist(0, 0, dx, dy);
  if (d < 2.5) return;  // 手振れ対策. 小さい動きでは角度を変えない

  float a = atan2(dy, dx);
  if (!angleInitialized) {
    brushAngle = a;
    motionAngle = a;
    angleInitialized = true;
    return;
  }

  motionAngle = a;
  brushAngle += foldedDiff(brushAngle, a) * angleEasing;
}
