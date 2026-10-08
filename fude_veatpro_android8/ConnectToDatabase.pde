// データベースにアクセスする処理

SQLiteDatabase db;
DatabaseHelper dbHelper;

void connectToDatabase() {
  try {
    dbHelper = new DatabaseHelper(getContext());
    db = dbHelper.getWritableDatabase();
    println("データベースに接続しました");
  } catch (Exception e) {
    e.printStackTrace();
    println("データベースへの接続に失敗しました");
  }
}
