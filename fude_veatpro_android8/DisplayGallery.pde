// 選択された画像のインデックス（-1は未選択の状態）
int selectedImageIndex = -1;

// 作品数カウント
int imageCount = 0;

// スクロールするため
float scrollOffset = 0;
float maxScroll = 0;
float scrollSpeed = 40;

// 作品カードの配置（SelectImage.pde と共通）
int galleryLeft = 60;
int galleryTop = 50;
int cardW = 380, cardH = 380;
int cardGapX = 40;
int cardRowStep = cardH + 100;  // カードの下に題を書くので, その分あける
int cardsPerRow = 3;

void displayGallery() {
  imageCount = 0;

  if (images == null || images.length == 0 || images[0] == null) {
    fill(0, 0, 20, 100);
    textAlign(CENTER, CENTER);
    textSize(48);
    text("まだ作品がありません", galleryPanelX / 2, height / 2);
    maxScroll = 0;
    scrollOffset = 0;
    return;
  }

  for (int i = 0; i < images.length && images[i] != null; i++) {
    imageCount++;
    String title = imagePaths.get(i);
    PImage img = images[i];

    float x = galleryLeft + (i % cardsPerRow) * (cardW + cardGapX);
    float y = galleryTop + (i / cardsPerRow) * cardRowStep + scrollOffset;
    if (y > height || y + cardRowStep < 0) continue;  // 画面の外は描かない

    // 和紙の台紙
    drawPaperCard(x, y, cardW, cardH);

    // サムネイル（縦横比を保って台紙に収める. 大きさが変わった時だけ縮小する）
    float maxW = cardW - 40, maxH = cardH - 40;
    float s = min(maxW / img.width, maxH / img.height);
    int tw = max(1, (int) (img.width * s));
    int th = max(1, (int) (img.height * s));
    if (img.width != tw || img.height != th) img.resize(tw, th);
    imageMode(CENTER);
    image(img, x + cardW / 2, y + cardH / 2);
    imageMode(CORNER);

    // 選択された作品は朱色の枠
    if (i == selectedImageIndex) {
      noFill();
      stroke(0, 80, 70, 100);
      strokeWeight(6);
      rect(x - 6, y - 6, cardW + 12, cardH + 12, 8);
    }

    // 題
    fill(0, 0, 0, 100);
    textAlign(CENTER, CENTER);
    textSize(36);
    text(title, x + cardW / 2, y + cardH + 45);
  }

  // 作品たちの全部の高さを計算
  int rows = (int) ceil((float) imageCount / (float) cardsPerRow);
  float totalHeight = galleryTop + rows * cardRowStep;

  // スクロールできる限界を設定
  maxScroll = max(0, totalHeight - height);

  // スクロールできる範囲を制限
  scrollOffset = constrain(scrollOffset, -maxScroll, 0);
}
