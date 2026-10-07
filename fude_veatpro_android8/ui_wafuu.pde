//和風UIの部品
//タイトル画面・プレイ画面と同じ雰囲気にするため, 今ある画像（和紙の背景, 巻物ボタン, 文字画像）を使う
//文字画像がないボタンは, dataに入っている筆文字のフォントで文字を書く

PFont kaishoFont;  // 筆文字のフォント（YujiSyuku）
// ※ 最初はHOT-Kaishokk（楷書体）を使っていたが, 1691文字しか入っておらず「戻」「了」「削」などが出なかったので,
//   今ある文字画像と雰囲気が近く, 文字数の多いYujiSyukuにした

// プレイ画面の右側パネルと同じ深緑（play_scene.png の色）
color panelColor;
color paperColor;     // 作品カードやポップアップの和紙色
color frameColor;     // 枠の色（こげ茶）

// 巻物ボタンの大きさ（プレイ画面と同じ）
int makiW = 240, makiH = 130;


void loadWafuuUI()
{
  kaishoFont = createFont("YujiSyuku-Regular.ttf", 48);
  panelColor = color(147, 20, 40, 100);
  paperColor = color(50, 8, 99, 100);
  frameColor = color(25, 45, 30, 100);
}


// 和紙の背景. タイトル画面の画像のうち, ロゴのない右側（x=1150〜）を画面いっぱいに広げて使う
void drawWashiBackground()
{
  image(title_image, 0, 0, width, height, 1150, 0, 1920, 1200);
}


// 巻物ボタン. 文字画像（labelImg）があればそれを, なければlabelTextを筆文字のフォントで書く
// 配置はプレイ画面の巻物ボタンと同じ（巻物 240×130 の上に, 文字を (+50, +15) の位置に置く）
void drawMakimono(float x, float y, PImage labelImg, String labelText)
{
  image(makimono_button_image, x, y, makiW, makiH);
  if (labelImg != null) {
    image(labelImg, x + 50, y + 15, 200, 80);
  } else {
    pushStyle();
    textFont(kaishoFont);
    fill(0, 0, 0, 100);
    textAlign(LEFT, CENTER);
    textSize(min(40, 140.0 / labelText.length()));  // 長い文字は巻物からはみ出さないように小さく
    text(labelText, x + 58, y + 55);
    popStyle();
  }
}


// 巻物ボタンの範囲内か
boolean overMakimono(float x, float y)
{
  return x + 20 <= mouseX && mouseX <= x + makiW - 10 && y + 10 <= mouseY && mouseY <= y + makiH - 10;
}


// 和紙のカード（作品の台紙やポップアップ）. 少し影をつける
void drawPaperCard(float x, float y, float w, float h)
{
  noStroke();
  fill(0, 0, 0, 18);  // 影
  rect(x + 8, y + 8, w, h, 6);
  fill(paperColor);
  stroke(frameColor);
  strokeWeight(3);
  rect(x, y, w, h, 6);
}
