import android.view.MotionEvent;

/* 
このプログラムでは, PGraphicsを用いる
PGraphicsとは, メイン描画画面の他に別のバッファで動作する描画領域を扱うためのクラス
たくさんの図形を同時に描画したりするなど, 毎フレームの処理が重い場合はこれを用いるとgood らしい
*/

PGraphics canvas;  // PGraphicsの新しいキャンバス
PImage brush;  // 掠れのイメージ
PImage startBrush;  // 書き始めがジャギジャギになるのを防ぐために最初だけに書くやつ

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

// 最初と最後の線のジャギジャギ感をなくす用
boolean strokeStarting = false;
int strokeFrameCount = 0;
float pressureSmoothing = 0;
float dist = 0;

float inkAmount = 1.0;
float inkDecay = 0.0018;

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
float jitter = 5;
float jx = random(-jitter, jitter);
float jy = random(-jitter, jitter);


void setup() {
  // size(820, 820, P3D);  // ウィンドウサイズ, P3Dレンダラ
  fullScreen(P3D);
  canvas = createGraphics(width, height, P3D);  // キャンバスを生成
  background(255);

  brush = createKasureBrush(70);  // 掠れのイメージをcreateKasureBrush関数で生成. 70はピクセル数.
  startBrush = createStartBrush(70);
  
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
  
  if (overClearButton()) {
    clearCanvas();
    // canvas.background(255);
    return;
  }
  
  holeCount = int(map(sliderHole, 0, 1, 0, 600));
  holeRadiusMax = map(sliderRadius, 0, 1, 1.0, 6.0);
  
  if (holeCount != prevHoleCount || holeRadiusMax != prevRadiusMax) {
    brush = createKasureBrush(70);
    prevHoleCount = holeCount;
    prevRadiusMax = holeRadiusMax;
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
}


// 掠れを生成する処理. ここ大事
PImage createKasureBrush(int size) {
  PImage img = createImage(size, size, ARGB);    // イメージを用意
  img.loadPixels();  // imgをピクセル配列化

  // ピクセル配列の長さ分全部黒く塗る
  for (int i = 0; i < img.pixels.length; i++) {
    img.pixels[i] = color(0, 0, 0, 255);
  }

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

      // sizeの35%の範囲より外だったら
      if (r > size * 0.35) {
        // 透明にする
        img.pixels[y*size + x] = color(0, 0, 0, 0);
      }
    }
  }
  
  // holeCount = 550;  // 穴の数
  for (int i = 0; i < holeCount; i++) {
    // sizeの範囲内でランダムな座標を選び, これを穴の中心にする
    int hx = int(random(size));
    int hy = int(random(size));
    
    // int holeRadius = int(random(1.5, 3.5));  // 穴の大きさ. 最小1px, 最大4.3px
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
          // 円の内側か外側か
          if (d <= holeRadius) {
            // 内側だったらピクセルを透明にする
            img.pixels[py*size + px] = color(0, 0, 0, 0);
          }
        }
      }
    }
  }

  img.updatePixels();  // 変更したピクセルの内容をimgに反映させる
  return img;
}


// 2点間（x1, y1）, （x2, y2）の間に線を補間する関数
void drawLineWithBrush(float x1, float y1, float x2, float y2) {
  float d = dist(x1, y1, x2, y2);  // 2点間の距離
  int steps = max(2, int(d * 0.7));  // 距離に応じて補間する回数を決める
  
  inkAmount -= d * inkDecay * map(pressure, 0.08, 0.21, 0.4, 1.0);
  inkAmount = constrain(inkAmount, 0, 1);
  
  // println(pressure);
  
  canvas.beginDraw();  // PGraphicsに対して描画を開始
  canvas.imageMode(CENTER);  // imgの中央を基準に合わせる
  
  float baseSize = 70;
  
  // 書き始めだけ筆圧の増加をゆっくりにする
  if (strokeStarting) {
    float p0 = constrain(pressure, 0.05, 0.21);
    float startSize = baseSize * map(p0, 0.08, 0.21, 0.02, 1.0);
    
    // 穴がない筆跡を一度だけ書く
    // canvas.image(startBrush, x1, y1, startSize, startSize);
    
    strokeStarting = false;
  }
  
  
   float p = constrain(pressure, 0.08, 0.21);  // 筆圧の値を一旦固定する（ここいらないかも）
  // float p = constrain(touchSize, 0.0117, 0.09);  // 接触面積用
  
   float scale = map(p, 0.08, 0.21, 0.02, 1.5);  // 筆圧の値を0.02 ~ 1.5に変換
  // float scale = map(p, 0.0117, 0.09, 0.02, 2);  // 接触面積用
  float brushSize = baseSize * scale;  // 筆圧が強いとbrushSizeが大きくなる
  
  // 書き始めの数フレームだけ処理を行う間隔を狭める = 密度が高くなる
  if (strokeFrameCount == 0) {
    // steps *= 6;
  }
  if (strokeFrameCount < 6) {
    steps *= 3;
  }

  for (int i = 0; i <= steps; i++) {
    
    float t = i / float(steps);  // tは0~1まで変化する比率. t=0.1だと始点から10%書いたことになるみたいな
    float x = lerp(x1, x2, t);  // x1 -> x2に行くまでの道のりを等間隔に割る
    float y = lerp(y1, y2, t);

    // PImage dynBrush = generateDynamicBrush(inkAmount);
    // canvas.image(dynBrush, x, y, brushSize, brushSize);
     // これ大事 canvas.image(brush, x, y, brushSize, brushSize);  // 等間隔で掠れ表現が並べられる
     canvas.image(brush, x + jx, y + jy, brushSize, brushSize);

    
  }
  
  strokeFrameCount++;

  canvas.endDraw();  // 描画内容を確定（終了）
}



PImage createStartBrush(int size) {
  PImage img = createImage(size, size, ARGB);
  img.loadPixels();
  
  float radius = size * 0.5;
  float edgeNoise = size * 0.1;
  
  for (int y = 0; y < size; y++) {
    for (int x = 0; x < size; x++) {
      float dx = x - size/2;
      float dy = y - size/2;
      float r = sqrt(dx*dx + dy*dy);
      
      if (r < size * 0.75) {
        img.pixels[y*size + x] = color(0);
        continue;
      }
      
      if (dist < radius) {
        float noiseVal = random(-edgeNoise, edgeNoise);
        if (dist + noiseVal < radius) {
          img.pixels[y*size + x] = color(0);
        } else {
          img.pixels[y*size + x] = color(0, 0);
        }
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


void touchStarted() {
  
  if (overKnob(uiX, uiY1, uiW, sliderHole)) draggingHole = true;
  if (overKnob(uiX, uiY2, uiW, sliderRadius)) draggingRadius = true;
}


void touchMoved() {
  if (!stopped) {
     float weight = pow(pressure,2) * 2000;
     // println(pressure);
    // float weight = log(pressure) * 2000;
    // float weight = pow(pressure, 2) * 2000;
    // float weight = pressure * 2000;
    // stroke(0);
    // strokeWeight(weight);
    // line(pmouseX, pmouseY, mouseX, mouseY);
  }
  
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
    float squareSize = pow(pressure, 2) * 2000;
    noStroke();
    fill(0); 
    rect(mouseX - squareSize / 2, mouseY - squareSize / 2, squareSize, squareSize, squareSize / 4); 
    stopped = true;
    
    stroke(0);
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
      
      px = mouseX;
      py = mouseY;
      break;

    case MotionEvent.ACTION_MOVE:
      touchMoved();  // タッチ移動時に描画処理を行う
      break;

    case MotionEvent.ACTION_UP:
      touchEnded();  // タッチ終了時に再び描画を可能に
      break;
  }

  return super.surfaceTouchEvent(event); 
  
}
