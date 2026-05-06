void showImageInfo(int index) {
  if (index < 0 || index >= imagePaths.size()) return;
  
  pushStyle();
  
  String title = imagePaths.get(index);
  String date = imageDates.get(index);
  
  infoX = width / 2;
  infoY = height / 2;
  infoW = 600;
  infoH = 300;
  isInfoVisible = true;
  
  // int btnX = (int)(infoX + infoW/2 - 48);
  // int btnY = (int)(infoY + infoH/2 - 300);
  
  // 背景を少し暗くする
  rectMode(CORNER);
  noStroke();
  fill(0, 40);
  rect(0, 0, width, height);
  
  // ポップアップの影
  fill(0, 50);
  rectMode(CENTER);
  rect(infoX + 8, infoY + 8, infoW, infoH, 25);
  
  // メインポップアップ
  fill(250, 250, 245, 240);
  stroke(80);
  strokeWeight(2);
  rect(infoX, infoY, infoW, infoH, 25);
  
  // タイトルと作成日
  fill(0);
  textAlign(CENTER);
  textSize(34);
  text("タイトル: " + title, infoX, infoY - 40);
  text("作成日: " + date, infoX, infoY + 20);
  
  
  
  
  // 閉じるボタン
  // closeInfo = new Button("X", btnX, btnY, 45, 45);
  // printButton = new Button("Send to PC", (int)(infoX - infoW/2 + 80), btnY, 120, 45);
  
  /*
  fill(250, 250, 245, 240);
  stroke(80);
  strokeWeight(2);
  rectMode(CENTER);
  rect(infoX, infoY, infoW, infoH, 20);
  
  fill(0);
  textAlign(CENTER);
  textSize(32);
  text("タイトル: " + title, infoX, infoY - 40);
  text("作成日: " + date, infoX, infoY + 20);
  */
  
  // closeInfo.display();
  // printButton.display();
  
  gb_closeInfo.set();
  gb_send.set();
  
  // rectModeを戻す
  rectMode(CENTER);
  
  popStyle();
}
