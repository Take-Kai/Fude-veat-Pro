void deleteSelectedImage() {
  if (selectedImageIndex == -1) {
    println("削除する画像を選択してください");
    return;
  }

  try {
    // 削除したい画像をタップし, そのidを取得
    int idToDelete = imageIds.get(selectedImageIndex);
    
    println("削除しようとしているID = " + idToDelete);
    
    
    // db.delete("drawings", "id = ?", new String[] { str(idToDelete) });
    // int rows = db.delete("drawings", "id = ?", new String[] { String.valueOf(idToDelete) });
    
    SQLiteDatabase db = dbHelper.getWritableDatabase();
    int rows = db.delete("drawings", "id = ?", new String[]{ String.valueOf(idToDelete) });
    db.close();
    println("削除しました: ID = " + idToDelete);
    println("削除対象ID = " + idToDelete + " / 実際に削除された行数 = " + rows);

    
    
    if (rows > 0) {
      // loadImages();
      galleryNeedsReload = true;
      selectedImageIndex = -1;
      // galleryScene();
    }

    // selectedImageIndex = -1;

    // 再読み込み
    // loadImages();
    // galleryScene();
  } catch (Exception e) {
    e.printStackTrace();
    println("削除に失敗しました");
  }
}
