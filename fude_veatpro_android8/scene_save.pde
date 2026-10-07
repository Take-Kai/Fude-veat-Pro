//scene save
//作品タイトル入力画面の処理を書く
//書道画面で「保存」を押すとこの画面に来て, タイトルを入力してから保存する
//
//書道画面は画面に直接描き重ねているので, 書道画面の上に入力欄を重ねると作品が消えてしまう.
//なので「保存」を押した時に画面全体を覚えておき, 書道画面に戻る時に描き戻す

PImage saveWholeScreen;  // 書道画面全体（戻る時に描き戻す）
PImage saveArtwork;      // 保存する作品の部分
String saveMessage = "";
boolean restorePlayScreen = false;  // 書道画面に戻った最初のフレームで描き戻す

// 画面の配置. キーボードが画面の下半分（y=510くらいから下）を隠すので, 全部その上に置く
int previewX = 110, previewY = 50, previewW = 440, previewH = 433;  // 作品の縦横比（1220:1200）に合わせる
int saveBoxX = 1000, saveBoxY = 200, saveBoxW = 800, saveBoxH = 90;
int saveBtnY = 330;
int saveOkX = 1000, saveBackX = 1280;


// 書道画面で「保存」が押された時に呼ぶ
void openSaveScene() {
  saveWholeScreen = get();
  saveArtwork = get(170, 0, 1220, 1200);  // 描画画面を取得
  saveMessage = "";
  // 日本語で入力できるように, Android標準の入力欄を重ねて出す（TitleEditText.pde）
  showTitleEdit(saveBoxX, saveBoxY, saveBoxW, saveBoxH);
  scene = "save";
}


// 書道画面に戻る
void closeSaveScene() {
  hideTitleEdit();
  restorePlayScreen = true;
  scene = "play";
}


void saveScene()
{
  pushStyle();
  drawWashiBackground();  //和紙の背景
  textFont(kaishoFont);

  // 作品のプレビュー（和紙の台紙の上に置く）
  drawPaperCard(previewX - 20, previewY - 20, previewW + 40, previewH + 40);
  if (saveArtwork != null)
    image(saveArtwork, previewX, previewY, previewW, previewH);

  // 説明
  fill(0, 0, 0, 100);
  textAlign(LEFT, BASELINE);
  textSize(46);
  text("作品タイトルを入力してください", saveBoxX, saveBoxY - 30);

  // 入力欄の枠（文字はAndroid標準の入力欄が上に重なって表示する）
  stroke(frameColor);
  strokeWeight(4);
  fill(paperColor);
  rect(saveBoxX, saveBoxY, saveBoxW, saveBoxH, 5);

  // 巻物ボタン
  drawMakimono(saveOkX, saveBtnY, hozonn, null);  //「保存」
  drawMakimono(saveBackX, saveBtnY, null, "戻る");

  // メッセージ
  if (saveMessage.length() > 0) {
    fill(0, 80, 70, 100);  //朱色
    textAlign(LEFT, BASELINE);
    textSize(38);
    text(saveMessage, saveBoxX, saveBoxY - 100);  // 説明の上（キーボードに隠れない位置）
  }
  popStyle();
}


// タイトル入力画面でタッチされた時
void saveSceneTouched()
{
  if (overMakimono(saveOkX, saveBtnY)) {
    String title = titleEditText.trim();
    if (title.isEmpty()) {
      saveMessage = "タイトルを入力してください";
      focusTitleEdit();
      return;
    }
    if (saveScreenshotToDatabase(saveArtwork, title)) {
      closeSaveScene();
    } else {
      saveMessage = "保存に失敗しました";
    }
    return;
  }

  if (overMakimono(saveBackX, saveBtnY)) {
    closeSaveScene();
    return;
  }

}
