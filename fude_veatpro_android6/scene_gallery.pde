//scene gallery
//ギャラリーシーンの処理を書く。未実装。

void gallery()
{
  pushMatrix();
  background(255);
  
  loadImages();
  displayGallery();
  
  gb_end.set();  //ギャラリー終了ボタン配置
  gb_back.set();
  gb_delete.set();
  
  popMatrix();
  
  if (isInfoVisible && gb_closeInfo != null) {
    showImageInfo(selectedImageIndex);
  }
  
}
