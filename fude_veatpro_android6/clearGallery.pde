void clearGallery() {
  if (images != null) {
    for (int i = 0; i < images.length; i++) {
      images[i] = null;
    }
  }
  if (imagePaths != null) {
    imagePaths.clear();
  }
  println("ギャラリーの内容をクリアしました");
}
