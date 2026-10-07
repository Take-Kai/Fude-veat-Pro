import android.content.Intent;
import android.net.Uri;
import android.widget.Toast;
import android.provider.MediaStore;
import android.os.Environment;


void saveImageToMediaStore(int index) {
  if (index < 0 || index >= imageIds.size()) {
    println("無効なインデックス");
    return;
  }

  try {
    // タイトルとデータを取得
    String title = imagePaths.get(index);
    byte[] imageData = null;

    SQLiteDatabase db = dbHelper.getReadableDatabase();
    Cursor cursor = db.rawQuery("SELECT image_data FROM drawings WHERE id = ?", new String[]{ String.valueOf(imageIds.get(index)) });
    if (cursor.moveToFirst()) {
      imageData = cursor.getBlob(cursor.getColumnIndex("image_data"));
    }
    cursor.close();
    db.close();

    if (imageData == null) {
      println("画像データが見つかりませんでした");
      return;
    }

    // 保存先ディレクトリを直接指定
    File picturesDir = new File(Environment.getExternalStorageDirectory(), "Pictures/MyDrawings");
    if (!picturesDir.exists()) {
      picturesDir.mkdirs();
    }

    File imageFile = new File(picturesDir, title + ".png");

    FileOutputStream fos = new FileOutputStream(imageFile);
    fos.write(imageData);
    fos.flush();
    fos.close();

    // MediaScannerでギャラリーに反映
    Intent intent = new Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE);
    Uri uri = Uri.fromFile(imageFile);
    intent.setData(uri);
    

    println("保存成功: " + imageFile.getAbsolutePath());
    Toast.makeText(getContext(), "保存しました: " + imageFile.getAbsolutePath(), Toast.LENGTH_SHORT).show();

  } catch (Exception e) {
    e.printStackTrace();
    println("MediaStore保存中にエラーが発生しました");
  }
}
