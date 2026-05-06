// 選択された画像のインデックス（-1は未選択の状態）
int selectedImageIndex = -1;

// 作品数カウント
int imageCount = 0;

// スクロールするため
float scrollOffset = 0;
float maxScroll = 0;
float scrollSpeed = 40;

void displayGallery() {
  imageCount = 0;
  int margin = 20;
  float yPosition = margin + scrollOffset;
  float xPosition = margin;
  int wakuWidth = 400;
  int wakuHeight = 400;
  int imagesPerRow = (width - margin) / (wakuWidth + margin);
  
  if (imagesPerRow > 3) imagesPerRow = 3;
  
  for (int i = 0; i < images.length && images[i] != null; i++) {
    String title = imagePaths.get(i);
    PImage img = images[i];
    
    float aspectRatio = (float) img.width / img.height;
    float displayWidth = wakuWidth - 40;
    float displayHeight = wakuHeight;
    
    // サムネサイズ調整
    if (displayHeight > wakuHeight - 20) {
      displayHeight = wakuHeight - 20;
      displayWidth = (wakuHeight - 20) * aspectRatio;
    }
    
    // 選択された時の枠の色
    if (i == selectedImageIndex) {
      stroke(255, 0, 0);
      strokeWeight(4);
    } else {
      stroke(180);
      strokeWeight(1);
    }
    
    // 画像カード描画
    fill(250);
    stroke(180);
    rect(xPosition - margin / 2, yPosition - margin / 2, wakuWidth + margin, wakuHeight + margin, 10);
    img.resize((int) displayWidth, (int) displayHeight);
    imageMode(CENTER);
    image(img, xPosition + wakuWidth / 2, yPosition + wakuHeight / 2);
    
    imageMode(CORNER);  // 表示バグ改善用
    
    // タイトル描画
    fill(0);
    textAlign(CENTER);
    textSize(30);
    text(title, xPosition + wakuWidth / 2, yPosition + wakuHeight + 3);
    
    // 配置位置の更新
    xPosition += wakuWidth + margin;
    if ((i + 1) % imagesPerRow == 0) {
      xPosition = margin;
      yPosition += wakuHeight + margin;
    }
  }
  
  // 行数カウント
  int rows = (int) ceil((float) imageCount / (float) imagesPerRow);
  
  // 作品たちの全部の高さを計算
  // float totalHeight = margin + rows * (wakuHeight + margin);
  float totalHeight = yPosition + wakuHeight;
  
  // スクロールできる限界を設定
  maxScroll = max(0, totalHeight - height);
  
  // スクロールできる範囲を制限
  scrollOffset = constrain(scrollOffset, -maxScroll, 0);
  
}
