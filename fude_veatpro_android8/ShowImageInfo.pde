// 作品の情報（題名と作成日）と, 削除・書き出し・閉じるボタンを表示する

// 情報の枠とボタンの配置
float infoPanelW = 1000, infoPanelH = 520;
int infoBtnY = 660;
int infoDeleteX = 560, infoSendX = 840, infoCloseX = 1120;

void showImageInfo(int index) {
  if (index < 0 || index >= imagePaths.size()) return;

  pushStyle();

  String title = imagePaths.get(index);
  String date = imageDates.get(index);

  infoX = width / 2;
  infoY = height / 2;
  infoW = infoPanelW;
  infoH = infoPanelH;

  // 背景を少し暗くする
  noStroke();
  fill(0, 0, 0, 40);
  rect(0, 0, width, height);

  // 和紙の枠
  drawPaperCard(infoX - infoW / 2, infoY - infoH / 2, infoW, infoH);

  // 題名と作成日
  textFont(kaishoFont);
  fill(0, 0, 0, 100);
  textAlign(CENTER, CENTER);
  textSize(52);
  text("題名　" + title, infoX, infoY - 150);
  textSize(38);
  text("作成日　" + date, infoX, infoY - 70);

  // 巻物ボタン
  drawMakimono(infoDeleteX, infoBtnY, sakujo, null);  //「削除」
  drawMakimono(infoSendX, infoBtnY, null, "書き出し");  // 端末の Pictures/MyDrawings に保存
  drawMakimono(infoCloseX, infoBtnY, null, "閉じる");

  popStyle();
}


// 情報の枠の中をタッチしたか
boolean overInfoPanel() {
  return abs(mouseX - width / 2) <= infoPanelW / 2 && abs(mouseY - height / 2) <= infoPanelH / 2;
}


void closeImageInfo() {
  isInfoVisible = false;
  selectedImageIndex = -1;
}
