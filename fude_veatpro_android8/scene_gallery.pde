//scene gallery
//作品閲覧画面の処理を書く
//タイトル画面・プレイ画面と同じ和風の見た目にしている（ui_wafuu.pde）

// 右側のパネル（プレイ画面の右側と同じ深緑）
int galleryPanelX = 1440;
int galleryEndX = 1660, galleryEndY = 950;  //「終了」ボタン（プレイ画面の「終了」と同じ位置）

// 作品をタップしたかどうかの判定用（スクロールと区別する）
float galleryTouchX, galleryTouchY;
boolean galleryTouching = false;

void gallery()
{
  // 作品の読み込みは必要な時だけ（以前は毎フレーム読み込んでいた）
  if (galleryNeedsReload || images == null) {
    loadImages();
    galleryNeedsReload = false;
  }

  pushStyle();
  drawWashiBackground();  //和紙の背景
  textFont(kaishoFont);

  displayGallery();
  drawGalleryPanel();

  if (isInfoVisible) {
    showImageInfo(selectedImageIndex);
  }
  popStyle();
}


// 右側のパネル
void drawGalleryPanel()
{
  noStroke();
  fill(panelColor);
  rect(galleryPanelX, 0, width - galleryPanelX, height);
  stroke(0, 0, 0, 100);
  strokeWeight(6);
  line(galleryPanelX, 0, galleryPanelX, height);

  // 見出し「作品閲覧」. 巻物の上に文字画像を置く（タイトル画面と同じ組み合わせ）
  image(makimono_button_image, galleryPanelX + 30, 40, 420, 230);
  image(sakuhinneturann, galleryPanelX + 110, 95, 300, 120);

  // 作品数
  fill(0, 0, 100, 100);
  textAlign(CENTER, CENTER);
  textSize(40);
  int n = (imagePaths == null) ? 0 : imagePaths.size();
  text("作品数　" + n, galleryPanelX + (width - galleryPanelX) / 2, 340);
  textSize(30);
  text("作品をタッチすると", galleryPanelX + (width - galleryPanelX) / 2, 440);
  text("題名と日付が見られます", galleryPanelX + (width - galleryPanelX) / 2, 485);

  //「終了」ボタン
  drawMakimono(galleryEndX, galleryEndY, syuuryou, null);
}


// 作品閲覧画面でタッチされた時
void galleryTouched()
{
  galleryTouching = false;

  // 作品の情報が開いている時は, その中のボタンだけ反応する
  if (isInfoVisible) {
    if (overMakimono(infoDeleteX, infoBtnY)) {
      deleteSelectedImage();
      closeImageInfo();
    }
    else if (overMakimono(infoSendX, infoBtnY)) {
      println("PCにデータを送信します");
      saveImageToMediaStore(selectedImageIndex);
    }
    else if (overMakimono(infoCloseX, infoBtnY) || !overInfoPanel()) {
      closeImageInfo();  //「閉じる」か, 枠の外をタッチしたら閉じる
    }
    return;
  }

  //「終了」でタイトル画面へ
  if (overMakimono(galleryEndX, galleryEndY)) {
    clearGallery();
    display_change("title");
    return;
  }

  // 作品の選択は指を離した時に行う（スクロールしただけの時は選択しない）
  if (mouseX < galleryPanelX) {
    galleryTouchX = mouseX;
    galleryTouchY = mouseY;
    galleryTouching = true;
  }
}


// 作品閲覧画面で指を離した時
void galleryReleased()
{
  if (galleryTouching && dist(galleryTouchX, galleryTouchY, mouseX, mouseY) < 30) {
    selectImage();
  }
  galleryTouching = false;
}
