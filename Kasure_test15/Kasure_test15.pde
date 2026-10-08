import android.view.MotionEvent;

/*
このプログラムでは, PGraphicsを用いる
PGraphicsとは, メイン描画画面の他に別のバッファで動作する描画領域を扱うためのクラス

Kasure_test14からの変更点
 1. 墨の仕様
    - 画をまたいで墨が減っていき, 「INK」ボタンで補充する
    - 減り方をゆるやかにした（inkDecay 0.0018 -> 0.0005）
    - 速く書くほど掠れやすくした
 2. 掠れの生成方法を「ランダムな穴」から「毛（筋）のモデル」に変更
    - 筆を線の幅方向に並んだ毛の集まりとみなし, 毛ごとに墨が切れているか（=白い筋になるか）をnoiseで決める
    - ストロークの途中で筋が始まったり終わったりする
    - 筋の位置がゆっくり揺れて, 寄ったり離れたりする
    - 筆の縁ほど掠れやすい（片側を少し強く）
    - 運筆方向によって線の太さが変わる（横画は細め, 縦画は太め）
 3. 入筆の雫形, はね・はらいの抜け, とめの丸みを追加

 ※ ブラシ画像のx軸が運筆方向, y軸が線の幅方向.
   同じ行（=同じ毛）が穴になり続けると, そこが白い筋になる.
   1フレームだけ墨が戻ってもブラシの長さ分は塗りつぶされるので, 筋の切り替わりはnoiseでゆっくり変える.
*/

PGraphics canvas;  // PGraphicsの新しいキャンバス

// ブラシ
int brushSizePx = 70;
PImage dynBrush;    // 毎フレーム作り直す掠れブラシ
int[] basePixels;   // 穴のないブラシのピクセル

// 毛のモデル
int bristleCount = 26;
float[] bristleY = new float[bristleCount];     // 毛の位置（ブラシ画像のy）
float[] bristleW = new float[bristleCount];     // 毛の太さ = 筋の太さ
float[] bristleSeed = new float[bristleCount];  // 毛ごとのnoiseの種
boolean needNewBristles = true;  // 次のフレームで毛を作り直すか
float dryFreq = 1.0 / 150;    // 筋が出たり消えたりする細かさ（小さいほど長い筋）
float driftFreq = 1.0 / 300;  // 筋が揺れる細かさ
float driftAmp = 3;           // 筋が揺れる大きさ（ブラシ画像上のpx）
float edgeBias = 0.8;         // 縁ほど掠れやすくする強さ
float sideBias = 0.25;        // 片側だけ少し掠れやすくする強さ
float entryWetLength = 60;    // 書き始めからこの距離までは掠れにくい

// 墨
float inkAmount = 1.0;
float inkDecay = 0.0005;
float inkDry = 0.9;          // 墨が空の時の掠れやすさ
float speedSmoothed = 0;     // 1フレームあたりの移動量（なめらかにしたもの）
float speedDryMin = 15;      // この速さから掠れ始める（px/frame）
float speedDryFull = 60;     // この速さで速さによる掠れが最大
float speedDryMax = 0.4;     // 速さによる掠れの最大値

// 運筆方向による太さの変化
float nibAngle = radians(30);  // 筆の穂の向き
float nibInfluence = 0.35;     // 太さが変わる割合

// ブラシの角度
float brushAngle = 0;     // ブラシ画像の回転角（折り返しで反転しないようにPI単位でたたんである）
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
float strokeLength = 0;  // ストローク内で進んだ距離（noiseの入力）
float lastBrushSize = 0;

// 入筆（雫形）
boolean headPending = false;
float headSize = 0;
float strokeStartX, strokeStartY;
float entryTailDir = radians(-135);  // 雫のとがりの向き（左上から筆が入る）
float entryTailLen = 0.6;
float headScale = 1.1;  // 線の幅に対する雫の大きさ

// とめ
boolean stopRequested = false;
float stopX, stopY, stopR, stopDir;

// はね・はらい
boolean tailRequested = false;
float tailX, tailY, tailAngle, tailTurn, tailSize, tailSpeed;
float tailMinSpeed = 6;     // これより速く離したら抜く（px/frame）
float tailSpeedFactor = 3;  // 抜く長さ = 速さ × これ
float tailMaxRatio = 1.5;   // 抜く長さの上限（ブラシの大きさに対する割合）
float tailSegLen = 6;
float tailDryExtra = 0.6;   // 抜けの先ほど掠れる

// 抜けるピクセルをほんの少しだけずらす（ストロークに沿ってゆっくり揺らす）
float jitter = 2;
float jitterScale = 0.01;
float noiseSeedOffset = 0;

// スライダー用
float sliderDry = 0.4;    // 墨満タンでの掠れやすさ
float sliderWidth = 0.5;  // 筋の太さ
boolean draggingDry = false;
boolean draggingWidth = false;
float uiX, uiW, uiY1, uiY2;
float prevSliderWidth = -1;

// ボタン
float clearBtnX, clearBtnY, inkBtnX, inkBtnY;
float btnW = 220;
float btnH = 80;


void setup() {
  fullScreen(P3D);
  canvas = createGraphics(width, height, P3D);  // キャンバスを生成
  background(255);

  PImage base = createBaseBrush(brushSizePx);
  base.loadPixels();
  basePixels = base.pixels.clone();
  dynBrush = createImage(brushSizePx, brushSizePx, ARGB);

  clearBtnX = width * 0.7;
  clearBtnY = height * 0.9;
  inkBtnX = width * 0.5;
  inkBtnY = height * 0.9;
}


void draw() {
  background(255);
  image(canvas, 0, 0);  // 現在のcanvasの内容を表示

  uiX = width * 0.05;
  uiW = width * 0.4;
  uiY1 = height * 0.85;
  uiY2 = height * 0.92;

  drawSlider(uiX, uiY1, uiW, sliderDry, "dryness");
  drawSlider(uiX, uiY2, uiW, sliderWidth, "streakWidth");
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

  // 新しいストロークが始まった時と, 筋の太さが変わった時に毛を作り直す
  // （タッチイベントは別スレッドで来るので, 作り直しはdraw内で行う）
  if (needNewBristles || sliderWidth != prevSliderWidth) {
    initBristles();
    prevSliderWidth = sliderWidth;
    needNewBristles = false;
  }

  if (mousePressed && !isOverUI()) {
    if (first) {
      px = mouseX;
      py = mouseY;
      strokeStartX = mouseX;
      strokeStartY = mouseY;
      headPending = true;
      headSize = 0;
      first = false;
    }

    drawLineWithBrush(px, py, mouseX, mouseY);  // 補間処理
    px = mouseX;
    py = mouseY;
  } else {
    first = true;  // 離したら次回の初回処理をリセット
  }

  // とめ・はね・はらいが予約されていたらcanvasに描く
  if (stopRequested) {
    canvas.beginDraw();
    drawBlob(stopX, stopY, stopR, stopDir, 0.2);
    canvas.endDraw();
    stopRequested = false;
  }
  if (tailRequested) {
    drawTail();
    tailRequested = false;
  }
}


// ブラシの形（穴なし）を作る
PImage createBaseBrush(int size) {
  PImage img = createImage(size, size, ARGB);
  img.loadPixels();

  for (int y = 0; y < size; y++) {
    for (int x = 0; x < size; x++) {
      // 中心からの距離. y方向を0.2倍して横に細長い形にしている
      float dx = (x - size/2) * 1.0;
      float dy = (y - size/2) * 0.2;
      float r = sqrt(dx*dx + dy*dy);

      if (r > size * 0.35) {
        img.pixels[y*size + x] = color(0, 0, 0, 0);
      } else {
        img.pixels[y*size + x] = color(0, 0, 0, 255);
      }
    }
  }

  img.updatePixels();
  return img;
}


// 毛の位置・太さ・noiseの種をランダムに決める. ストロークごとに呼ぶので毎回違う掠れになる
void initBristles() {
  float wMax = map(sliderWidth, 0, 1, 1.5, 6.0);
  for (int j = 0; j < bristleCount; j++) {
    bristleY[j] = random(brushSizePx);
    bristleW[j] = random(1.0, wMax);
    bristleSeed[j] = random(10000);
  }
}


// 今の掠れやすさ. 0で掠れなし, 1を超えるとほとんどの毛が掠れる
float currentDryness() {
  float base = map(sliderDry, 0, 1, 0, 0.6);
  float ink = (1 - inkAmount) * inkDry;
  float speed = constrain(map(speedSmoothed, speedDryMin, speedDryFull, 0, speedDryMax), 0, speedDryMax);
  return base + ink + speed;
}


// 掠れを生成する処理. ここ大事
// 距離sの地点での毛の状態からブラシ画像を作り直す
void updateBrush(float s, float dry) {
  int size = brushSizePx;
  dynBrush.loadPixels();
  arrayCopy(basePixels, dynBrush.pixels);

  float entry = constrain(s / entryWetLength, 0, 1);  // 書き始めは墨がたっぷり

  for (int j = 0; j < bristleCount; j++) {
    // 縁の毛ほど掠れやすい. yn = -1(片側の縁) ~ 1(反対側の縁)
    float yn = bristleY[j] / size * 2 - 1;
    float weight = 1 - edgeBias * 0.5 + edgeBias * yn * yn + sideBias * yn;
    float local = dry * weight * entry;

    // noiseがlocalより小さい区間だけ, この毛は墨が切れている
    float v = constrain(map(noise(bristleSeed[j], s * dryFreq), 0.25, 0.75, 0, 1), 0, 1);
    if (v >= local) continue;

    // 筋の位置をゆっくり揺らす
    float y = bristleY[j] + (noise(bristleSeed[j] + 500, s * driftFreq) - 0.5) * 2 * driftAmp;
    int y0 = max(0, round(y - bristleW[j] / 2));
    int y1 = min(size - 1, round(y + bristleW[j] / 2));

    // この毛の行を透明にする
    for (int yy = y0; yy <= y1; yy++) {
      for (int x = 0; x < size; x++) {
        dynBrush.pixels[yy*size + x] = 0;
      }
    }
  }

  dynBrush.updatePixels();
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
// ブラシは左右対称に近いので, 180°回すと筋の並びが反転してしまうため
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


// 2点間（x1, y1）, （x2, y2）の間に線を補間する関数
void drawLineWithBrush(float x1, float y1, float x2, float y2) {
  float d = dist(x1, y1, x2, y2);  // 2点間の距離
  speedSmoothed = lerp(speedSmoothed, d, 0.3);

  // 墨を減らす. 筆圧が強いほど早く減る
  float pInk = constrain(pressure, 0.08, 0.21);
  inkAmount -= d * inkDecay * map(pInk, 0.08, 0.21, 0.4, 1.0);
  inkAmount = constrain(inkAmount, 0, 1);

  updateMotion(x2 - x1, y2 - y1);

  float brushSize = sizeFromPressure(pressure);
  lastBrushSize = brushSize;

  canvas.beginDraw();

  // 書き始めの数フレームの最大の大きさで雫形を描く
  if (headPending) {
    headSize = max(headSize, brushSize);
    if (strokeLength >= 15 || strokeFrameCount >= 5) {
      drawEntryHead();
      headPending = false;
    }
  }

  int steps = max(2, int(d * 0.7));  // 距離に応じて補間する回数を決める
  // 書き始めの数フレームだけ処理を行う間隔を狭める = 密度が高くなる
  if (strokeFrameCount < 6) {
    steps *= 3;
  }

  stampSegment(x1, y1, x2, y2, brushSize, brushSize, steps, 0);

  canvas.endDraw();
  strokeFrameCount++;
}


// (x1, y1)から(x2, y2)までブラシを押していく. canvas.beginDraw()の中で呼ぶ
// size1 -> size2 に大きさを変えながら押す. dryExtraは追加の掠れやすさ
void stampSegment(float x1, float y1, float x2, float y2, float size1, float size2, int steps, float dryExtra) {
  float d = dist(x1, y1, x2, y2);
  updateBrush(strokeLength + d * 0.5, currentDryness() + dryExtra);

  float ws = widthScale();
  // 運筆方向に垂直な向き（ずらす方向）
  float nx = -sin(brushAngle);
  float ny = cos(brushAngle);

  canvas.imageMode(CENTER);
  for (int i = 0; i <= steps; i++) {
    float t = i / float(steps);
    float x = lerp(x1, x2, t);
    float y = lerp(y1, y2, t);

    // ストロークに沿ってなめらかに揺らす
    float s = strokeLength + d * t;
    float offset = (noise(noiseSeedOffset + s * jitterScale) - 0.5) * 2 * jitter;

    float sz = lerp(size1, size2, t);

    // ブラシの横方向（画像のx軸）が運筆方向を向くように回転させて押す
    canvas.pushMatrix();
    canvas.translate(x + nx * offset, y + ny * offset);
    canvas.rotate(brushAngle);
    canvas.image(dynBrush, 0, 0, sz, sz * ws);
    canvas.popMatrix();
  }

  strokeLength += d;
  // 次にdynBrushを書き換える前に, ここまでの描画を確定させる
  canvas.flush();
}


// 入筆の雫形
void drawEntryHead() {
  float R = headSize * widthScale() * 0.5 * headScale;
  float cx = strokeStartX + cos(motionAngle) * R * 0.3;
  float cy = strokeStartY + sin(motionAngle) * R * 0.3;
  drawBlob(cx, cy, R, entryTailDir, entryTailLen);
}


// 縁が少しガタガタした雫形. tailDirの向きにとがる. canvas.beginDraw()の中で呼ぶ
void drawBlob(float cx, float cy, float R, float tailDir, float tailLen) {
  if (R < 1) return;
  float seed = random(1000);
  canvas.noStroke();
  canvas.fill(0);
  canvas.beginShape();
  int n = 72;
  for (int i = 0; i < n; i++) {
    float th = TWO_PI * i / n;
    float c = cos(th - tailDir);
    float r = R * (1 + tailLen * pow(max(0, c), 6));
    r *= 1 + (noise(seed + cos(th) * 1.5, seed + sin(th) * 1.5) - 0.5) * 0.18;
    canvas.vertex(cx + cos(th) * r, cy + sin(th) * r);
  }
  canvas.endShape(CLOSE);
}


// はね・はらい. 離した時の向きと曲がり具合のまま, 小さくしながら少し先まで押す
void drawTail() {
  float len = constrain(tailSpeed * tailSpeedFactor, 0, tailSize * tailMaxRatio);
  if (len < 4 || tailSize < 2) return;

  canvas.beginDraw();
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
    float s1 = tailSize * pow(1 - t0, 1.3);
    float s2 = tailSize * pow(1 - t1, 1.3);
    stampSegment(x, y, x2, y2, s1, s2, max(2, int(tailSegLen * 0.7)), t1 * tailDryExtra);

    x = x2;
    y = y2;
  }
  canvas.endDraw();
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
  if (overKnob(uiX, uiY2, uiW, sliderWidth)) draggingWidth = true;
}


void touchMoved() {
  if (isOverUI()) {
    if (draggingDry) {
      sliderDry = constrain((mouseX - uiX) / uiW, 0, 1);
    }
    if (draggingWidth) {
      sliderWidth = constrain((mouseX - uiX) / uiW, 0, 1);
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
    stopDir = motionAngle + PI;  // 来た方向に少しだけとがらせる
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
  draggingWidth = false;
}


boolean overKnob(float x, float y, float w, float value) {
  float knobX = x + w * value;
  return dist(mouseX, mouseY, knobX, y) < width * 0.03;
}


boolean isOverUI() {
  return (mouseY > height * 0.8);
}


void clearCanvas() {
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

      // ストロークごとの初期化
      strokeFrameCount = 0;
      strokeLength = 0;
      speedSmoothed = 0;
      noiseSeedOffset = random(1000);  // 揺れ方を毎回変える
      angleInitialized = false;
      // この時点ではmouseYがまだ更新されていないのでevent.getY()で判定
      if (event.getY() <= height * 0.8) {
        needNewBristles = true;  // 毎回違う掠れパターンにする（作り直しはdraw内）
      }

      px = mouseX;
      py = mouseY;
      break;

    // ACTION_MOVE / ACTION_UP では touchMoved() / touchEnded() を直接呼ばない
    // 下の super.surfaceTouchEvent() を通すとProcessingが描画スレッドで呼んでくれる
  }

  return super.surfaceTouchEvent(event);
}
