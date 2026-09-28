import android.view.MotionEvent;

/*
このプログラムでは, PGraphicsを用いる
PGraphicsとは, メイン描画画面の他に別のバッファで動作する描画領域を扱うためのクラス
たくさんの図形を同時に描画したりするなど, 毎フレームの処理が重い場合はこれを用いるとgood らしい

Kasure_test13からの変更点
 1. ずらし(jitter)をストロークに沿ってなめらかに揺れるようにした（noise使用）
 2. ブラシを運筆方向に合わせて回転させるようにした
 3. ブラシを1ストロークごとに作り直し, 毎回違う掠れパターンにした
 4. inkAmount（墨の量）が減るほど穴が増えて掠れるようにした
 5. createStartBrushのバグ（distを参照していた）を修正

 ※ 掠れの筋は「同じ穴が同じ位置に押され続ける」ことで生まれるので,
   押すたびにランダムにずらしたり, 別のパターンに切り替えたりすると穴が埋まって掠れが消える.
   なのでずらしはゆっくり変化させ, パターンはストローク単位で変え,
   墨の量の変化は「前の段階の穴を全部含んだまま穴を追加する」画像を段階的に用意して切り替える.
*/

PGraphics canvas;  // PGraphicsの新しいキャンバス
PImage startBrush;  // 書き始めがジャギジャギになるのを防ぐために最初だけに書くやつ
boolean useStartBrush = false;  // 書き始め用ブラシを使うか

// 墨の量ごとのブラシ. inkBrushes[0]が墨満タン, 後ろに行くほど穴が多い
int inkLevels = 8;
PImage[] inkBrushes = new PImage[inkLevels];
int brushSizePx = 70;
boolean needNewPattern = false;  // 次のフレームでブラシを作り直すか

float px, py;  // 前のマウス位置
boolean first = true;  // 最初のクリックで初期化するためのフラグ

// 筆圧検知用
float pressure = 0;
boolean stopped = false;
int stopTime = 0;
int stopTimeThreshold = 500;
float stopThreshold = 0.16;
float moveThreshold = 2;
int pmillis = 0;
int lastTouchTime = 0;

// 止め（筆を止めた時の四角）の描画予約
// タッチ処理の中では位置と大きさだけ記録し, 描画はdraw内でcanvasに行う
boolean stopRequested = false;
float stopX, stopY, stopSize;

// 最初と最後の線のジャギジャギ感をなくす用
boolean strokeStarting = false;
int strokeFrameCount = 0;
float pressureSmoothing = 0;

float inkAmount = 1.0;
float inkDecay = 0.0018;
int inkHoleExtra = 700;  // 墨が0になった時に追加される穴の数

float touchSize = 0;

// 動的な変数holeCountとholeRadius
int holeCount = 0;
float holeRadiusMin = 1.5;
float holeRadiusMax = 3.5;

// スライダー用
float sliderHole = 0.3;
float sliderRadius = 0.5;
boolean draggingHole = false;
boolean draggingRadius = false;
float uiX, uiW, uiY1, uiY2;

int prevHoleCount = -1;
float prevRadiusMax = -1;

// 削除ボタン
float clearBtnX, clearBtnY;
float clearBtnW = 220;
float clearBtnH = 80;

// 抜けるピクセルをほんの少しだけずらす
// 押すたびにランダムにすると筋が消えるので, noiseでストロークに沿ってゆっくり揺らす
float jitter = 2;
float jitterScale = 0.01;  // 揺れの細かさ（小さいほどゆっくり）
float strokeLength = 0;  // ストローク内で進んだ距離（noiseの入力）
float noiseSeedOffset = 0;  // ストロークごとに揺れ方を変える

// ブラシの角度
float brushAngle = 0;
float angleEasing = 0.25;  // 角度の追従しやすさ
boolean angleInitialized = false;


void setup() {
  // size(820, 820, P3D);  // ウィンドウサイズ, P3Dレンダラ
  fullScreen(P3D);
  canvas = createGraphics(width, height, P3D);  // キャンバスを生成
  background(255);

  createInkBrushes(brushSizePx);  // 墨の量ごとの掠れブラシを生成
  startBrush = createStartBrush(brushSizePx);

  // 削除ボタン
  clearBtnX = width * 0.7;
  clearBtnY = height * 0.9;
}


void draw() {
  background(255);
  image(canvas, 0, 0);  // 現在のcanvasの内容を表示

  uiX = width * 0.05;
  uiW = width * 0.4;
  uiY1 = height * 0.85;
  uiY2 = height * 0.92;

  drawSlider(uiX, uiY1, uiW, sliderHole, "holeCount");
  drawSlider(uiX, uiY2, uiW, sliderRadius, "holeRadius");

  drawClearButton();
  drawInkMeter();

  // 押している時だけ消す（test13は指を離した後も毎フレーム消えていた）
  if (mousePressed && overClearButton()) {
    clearCanvas();
    return;
  }

  holeCount = int(map(sliderHole, 0, 1, 0, 600));
  holeRadiusMax = map(sliderRadius, 0, 1, 1.0, 6.0);

  // スライダーが変わった時と, 新しいストロークが始まった時にブラシを作り直す
  // （タッチイベントは別スレッドで来るので, 作り直しはdraw内で行う）
  if (holeCount != prevHoleCount || holeRadiusMax != prevRadiusMax || needNewPattern) {
    createInkBrushes(brushSizePx);
    prevHoleCount = holeCount;
    prevRadiusMax = holeRadiusMax;
    needNewPattern = false;
  }

  if (mousePressed && !isOverUI()) {
    if (first) {
      px = mouseX;
      py = mouseY;
      first = false;
    }

    drawLineWithBrush(px, py, mouseX, mouseY);  // 補間処理
    px = mouseX;
    py = mouseY;
  } else {
    first = true;  // マウスを話したら次回クリック時の初回処理をリセット
  }

  // 止めが予約されていたらcanvasに描く
  if (stopRequested) {
    drawStop();
    stopRequested = false;
  }
}


// 止めの四角をcanvasに描く
void drawStop() {
  canvas.beginDraw();
  canvas.noStroke();
  canvas.fill(0);
  canvas.rect(stopX - stopSize / 2, stopY - stopSize / 2, stopSize, stopSize, stopSize / 4);
  canvas.endDraw();
}


// ブラシの形（穴なし）を作る. 縦長の楕円
PImage createBaseBrush(int size) {
  PImage img = createImage(size, size, ARGB);    // イメージを用意
  img.loadPixels();  // imgをピクセル配列化

  // size × size のイメージを作りたいので, xとyそれぞれ全部調べる
  for (int y = 0; y < size; y++) {
    for (int x = 0; x < size; x++) {

      // size/2 = 中心の座標
      // 現在の位置x, yから中心の座標を引くことで中心からの距離を求めている
      float dx = (x - size/2) * 1.0;
      float dy = (y - size/2) * 0.2;  // 筆先の縦方向を少し潰す

      // 円の方程式 r = √(dx^2 + dy^2)
      // dxは中心からの距離×1なのでx方向に関してはそのまま
      // dyは中心からの距離×0.2をしているので, y方向の中心からの距離を縮めている
      // -> なのでイメージ的には楕円を作っている感じ
      float r = sqrt(dx*dx + dy*dy);

      // sizeの35%の範囲より内側は黒, 外側は透明
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


// imgにランダムな穴をcount個あける
void punchHoles(PImage img, int size, int count) {
  img.loadPixels();

  for (int i = 0; i < count; i++) {
    // sizeの範囲内でランダムな座標を選び, これを穴の中心にする
    int hx = int(random(size));
    int hy = int(random(size));

    int holeRadius = int(random(holeRadiusMin, holeRadiusMax));

    // -hrからhrの範囲を全部調べる
    for (int y = -holeRadius; y <= holeRadius; y++) {
      for (int x = -holeRadius; x <= holeRadius; x++) {

        // 中心からのオフセット分xとyを足す
        int px = hx + x;
        int py = hy + y;

        // ランダムにhxやhyを決めるのでsizeよりも外側だったらここをスキップ
        if (px >= 0 && px < size && py >= 0 && py < size) {
          // 円の方程式
          float d = sqrt(x*x + y*y);
          // 円の内側だったらピクセルを透明にする
          if (d <= holeRadius) {
            img.pixels[py*size + px] = color(0, 0, 0, 0);
          }
        }
      }
    }
  }

  img.updatePixels();  // 変更したピクセルの内容をimgに反映させる
}


// 掠れを生成する処理. ここ大事
// 墨の量の段階ごとにブラシを作る. 前の段階の穴を残したまま穴を足していくので,
// 墨が減っても今までの筋はそのまま続き, 新しい筋が増えていく
void createInkBrushes(int size) {
  PImage img = createBaseBrush(size);
  int made = 0;  // これまでにあけた穴の数

  for (int k = 0; k < inkLevels; k++) {
    float t = k / float(inkLevels - 1);  // 0(満タン) ~ 1(空)
    int target = holeCount + int(inkHoleExtra * pow(t, 1.5));
    punchHoles(img, size, target - made);
    made = target;
    inkBrushes[k] = img.copy();
  }
}


// 現在の墨の量に対応するブラシ
PImage currentBrush() {
  int k = round((1 - inkAmount) * (inkLevels - 1));
  k = constrain(k, 0, inkLevels - 1);
  return inkBrushes[k];
}


// ブラシの角度を運筆方向に近づける
void updateBrushAngle(float dx, float dy) {
  if (dist(0, 0, dx, dy) < 2.5) return;  // 手振れ対策. 小さい動きでは角度を変えない

  float target = atan2(dy, dx);
  if (!angleInitialized) {
    brushAngle = target;
    angleInitialized = true;
    return;
  }

  // 差を-PI/2 ~ PI/2に収める
  // ブラシは左右対称に近いので, 逆方向に戻る時に180°回転させると筋の位置が反転してしまうため
  float diff = atan2(sin(target - brushAngle), cos(target - brushAngle));
  if (diff > HALF_PI) diff -= PI;
  if (diff < -HALF_PI) diff += PI;

  brushAngle += diff * angleEasing;
}


// 2点間（x1, y1）, （x2, y2）の間に線を補間する関数
void drawLineWithBrush(float x1, float y1, float x2, float y2) {
  float d = dist(x1, y1, x2, y2);  // 2点間の距離
  int steps = max(2, int(d * 0.7));  // 距離に応じて補間する回数を決める

  // 筆圧が弱い時にinkAmountが増えないようにconstrainする
  float pInk = constrain(pressure, 0.08, 0.21);
  inkAmount -= d * inkDecay * map(pInk, 0.08, 0.21, 0.4, 1.0);
  inkAmount = constrain(inkAmount, 0, 1);

  updateBrushAngle(x2 - x1, y2 - y1);

  canvas.beginDraw();  // PGraphicsに対して描画を開始
  canvas.imageMode(CENTER);  // imgの中央を基準に合わせる

  float baseSize = brushSizePx;

  // 書き始めだけ穴のない筆跡を一度書く
  if (strokeStarting) {
    if (useStartBrush) {
      float p0 = constrain(pressure, 0.05, 0.21);
      float startSize = baseSize * map(p0, 0.08, 0.21, 0.02, 1.0);
      canvas.image(startBrush, x1, y1, startSize, startSize);
    }
    strokeStarting = false;
  }

  float p = constrain(pressure, 0.08, 0.21);  // 筆圧の値を一旦固定する
  // float p = constrain(touchSize, 0.0117, 0.09);  // 接触面積用

  float scale = map(p, 0.08, 0.21, 0.02, 1.5);  // 筆圧の値を0.02 ~ 1.5に変換
  // float scale = map(p, 0.0117, 0.09, 0.02, 2);  // 接触面積用
  float brushSize = baseSize * scale;  // 筆圧が強いとbrushSizeが大きくなる

  // 書き始めの数フレームだけ処理を行う間隔を狭める = 密度が高くなる
  if (strokeFrameCount < 6) {
    steps *= 3;
  }

  PImage brush = currentBrush();

  // 運筆方向に垂直な向き（ずらす方向）
  float nx = -sin(brushAngle);
  float ny = cos(brushAngle);

  for (int i = 0; i <= steps; i++) {

    float t = i / float(steps);  // tは0~1まで変化する比率. t=0.1だと始点から10%書いたことになるみたいな
    float x = lerp(x1, x2, t);  // x1 -> x2に行くまでの道のりを等間隔に割る
    float y = lerp(y1, y2, t);

    // ストロークに沿ってなめらかに揺らす
    float s = strokeLength + d * t;
    float offset = (noise(noiseSeedOffset + s * jitterScale) - 0.5) * 2 * jitter;

    // ブラシの横方向（画像のx軸）が運筆方向を向くように回転させて押す
    canvas.pushMatrix();
    canvas.translate(x + nx * offset, y + ny * offset);
    canvas.rotate(brushAngle);
    canvas.image(brush, 0, 0, brushSize, brushSize);
    canvas.popMatrix();
  }

  strokeLength += d;
  strokeFrameCount++;

  canvas.endDraw();  // 描画内容を確定（終了）
}


// 書き始め用の穴のないブラシ. 縁だけ少しガタガタさせる
PImage createStartBrush(int size) {
  PImage img = createImage(size, size, ARGB);
  img.loadPixels();

  float radius = size * 0.35;
  float edgeNoise = size * 0.05;

  for (int y = 0; y < size; y++) {
    for (int x = 0; x < size; x++) {
      float dx = x - size/2;
      float dy = y - size/2;
      float r = sqrt(dx*dx + dy*dy);  // test13ではここでグローバル変数distを見ていた

      float noiseVal = random(-edgeNoise, edgeNoise);
      if (r + noiseVal < radius) {
        img.pixels[y*size + x] = color(0);
      } else {
        img.pixels[y*size + x] = color(0, 0);
      }
    }
  }

  img.updatePixels();
  return img;
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


void touchStarted() {
  if (overKnob(uiX, uiY1, uiW, sliderHole)) draggingHole = true;
  if (overKnob(uiX, uiY2, uiW, sliderRadius)) draggingRadius = true;
}


void touchMoved() {
  if (isOverUI()) {
    if (draggingHole) {
      sliderHole = constrain((mouseX - uiX) / uiW, 0, 1);
    }

    if (draggingRadius) {
      sliderRadius = constrain((mouseX - uiX) / uiW, 0, 1);
    }

    return;
  }

  if (pressure >= stopThreshold && dist(pmouseX, pmouseY, mouseX, mouseY) < moveThreshold) {
    stopTime += millis() - pmillis;
  } else {
    stopTime = 0;
  }

  if (stopTime > stopTimeThreshold && !stopped) {
    // ここでは描かずに予約だけする（描画はdraw内のdrawStop）
    stopSize = pow(pressure, 2) * 2000;
    stopX = mouseX;
    stopY = mouseY;
    stopRequested = true;
    stopped = true;
  }

  pmillis = millis();
  lastTouchTime = millis();
}

void touchEnded() {
  stopped = false;
  stopTime = 0;
  inkAmount = 1.0;

  draggingHole = false;
  draggingRadius = false;
}


boolean overKnob(float x, float y, float w, float value) {
  float knobX = x + w * value;
  return dist(mouseX, mouseY, knobX, y) < width * 0.03;
}


boolean isOverUI() {
  return (mouseY > height * 0.8);
}


void drawClearButton() {
  fill(0);
  rect(clearBtnX, clearBtnY, clearBtnW, clearBtnH, 20);

  fill(255);
  textSize(28);
  textAlign(CENTER, CENTER);
  text("CLEAR", clearBtnX + clearBtnW/2, clearBtnY + clearBtnH/2);

  textAlign(LEFT, BASELINE);
}


boolean overClearButton() {
  return mouseX > clearBtnX &&
         mouseX < clearBtnX + clearBtnW &&
         mouseY > clearBtnY &&
         mouseY < clearBtnY + clearBtnH;
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

      // 書き始めのジャギジャギ感改善用
      strokeStarting = true;
      strokeFrameCount = 0;
      pressureSmoothing = 0;

      // ストロークごとの初期化
      strokeLength = 0;
      noiseSeedOffset = random(1000);  // 揺れ方を毎回変える
      angleInitialized = false;
      // この時点ではmouseYがまだ更新されていないのでevent.getY()で判定
      if (event.getY() <= height * 0.8) {
        needNewPattern = true;  // 毎回違う掠れパターンにする（作り直しはdraw内）
      }

      px = mouseX;
      py = mouseY;
      break;

    // ACTION_MOVE / ACTION_UP では touchMoved() / touchEnded() を直接呼ばない
    // 下の super.surfaceTouchEvent() を通すとProcessingが描画スレッドで呼んでくれるので,
    // ここでも呼ぶと1回の移動で2回実行されてしまう（しかもこちらはUIスレッド）
  }

  return super.surfaceTouchEvent(event);

}
