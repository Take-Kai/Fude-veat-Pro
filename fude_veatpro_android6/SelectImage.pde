void selectImage() {
  int margin = 20;
  int wakuWidth = 400;
  int wakuHeight = 400;
  int xPosition = margin;
  int yPosition = margin;
  int imagePerRow = (width - margin) / (wakuWidth + margin);
  
  if (imagePerRow > 3) imagePerRow = 3;
  
  for (int i = 0; i < images.length && images[i] != null; i++) {
    if (mouseX >= xPosition && mouseX <= xPosition + wakuWidth && 
        mouseY >= yPosition && mouseY <= yPosition + wakuHeight) {
      selectedImageIndex = i;
      println("画像 " + i + " が選択されました");
      showImageInfo(i);
      return;
    }
    
    xPosition += wakuWidth + margin;
    if ((i + 1) % imagePerRow == 0) {
      xPosition = margin;
      yPosition += wakuHeight + margin;
    }
  }
  
  selectedImageIndex = -1;
}
