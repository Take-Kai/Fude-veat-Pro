ArrayList<String> imagePaths;
PImage[] images;

void loadImages() {
  imagePaths = new ArrayList<>();
  imageDates = new ArrayList<>();
  images = new PImage[100];
  imageIds = new ArrayList<>();
  
  println("データベースから画像を読み込んでいます...");
  
  // SQLiteDatabase db = SQLiteDatabase.openDatabase("/data/data/processing.test.fude_veatpro_android6/databases/drawings.db", null, SQLiteDatabase.OPEN_READONLY);
  SQLiteDatabase db = dbHelper.getReadableDatabase();
  
  // データベースから画像データを取得
  Cursor cursor = db.rawQuery("SELECT id, title, date, image_data FROM drawings", null);
  
  int count = cursor.getCount();
  images = new PImage[count];
  
  int index = 0;
  
  while (cursor.moveToNext()) {
    String title = cursor.getString(cursor.getColumnIndex("title"));
    String date = cursor.getString(cursor.getColumnIndex("date"));
    byte[] imageData = cursor.getBlob(cursor.getColumnIndex("image_data"));
    int id = cursor.getInt(cursor.getColumnIndex("id"));
    
    PImage img = loadImageFromBytes(imageData);
    
    if (img != null && index < images.length) {
      images[index] = img;
      
      imageIds.add(id);
      imagePaths.add(title);
      imageDates.add(date);
      println("画像をロードしました: " + title);
      
      index++;
    } else {
      println("画像のロードに失敗しました: " + title);
    }
  }
  cursor.close();
  db.close();
}
