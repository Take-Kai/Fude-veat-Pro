// タッチした位置にある作品を選んで, 情報を開く
// 配置は DisplayGallery.pde と同じ. スクロールした分（scrollOffset）も考える
void selectImage() {
  if (images == null) return;

  for (int i = 0; i < images.length && images[i] != null; i++) {
    float x = galleryLeft + (i % cardsPerRow) * (cardW + cardGapX);
    float y = galleryTop + (i / cardsPerRow) * cardRowStep + scrollOffset;
    if (mouseX >= x && mouseX <= x + cardW &&
        mouseY >= y && mouseY <= y + cardH) {
      selectedImageIndex = i;
      println("画像 " + i + " が選択されました");
      isInfoVisible = true;
      return;
    }
  }

  selectedImageIndex = -1;
}
