// 掠れ線を描画する処理

void drawBrushStroke(float x, float y, float speed, float px, float py, float mx, float my) {
  int particleCount = int(map(speed, 0, 20, 1, 5));
  float size = map(speed, 0, 20, 3, 1);
  float spread = map(speed, 0, 20, 3, 5);

  // 点で掠れを表現
  for (int i = 0; i < particleCount; i++) {
    float dx = random(-spread, spread);
    float dy = random(-spread, spread);
    float alpha = map(dist(0, 0, dx, dy), 0, spread, 255, 0);
    fill(0, alpha);
    ellipse(x + dx, y + dy, size, size);
  }

  // 線で掠れを表現
  int lineCount = int(map(speed, 0, 20, 16, 50)); // 速いと細い線が多めに
  float directionX = mx - px;
  float directionY = my - py;
  float len = sqrt(directionX * directionX + directionY * directionY);
  if (len != 0) {
    directionX /= len;
    directionY /= len;
  }

  stroke(0, 100);
  for (int i = 0; i < lineCount; i++) {
    float offsetX = random(-spread, spread);
    float offsetY = random(-spread, spread);
    float lineLength = random(3, map(speed, 0, 20, 10, 20));
    float alpha = map(speed, 0, 20, 200, 50);
    stroke(0, alpha);

    float startX = x + offsetX;
    float startY = y + offsetY;
    float endX = startX + directionX * lineLength;
    float endY = startY + directionY * lineLength;
    line(startX, startY, endX, endY);
  }

  noStroke();
}
