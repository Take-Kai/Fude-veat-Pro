TextBox titleInput;

// 作品の画像とタイトルをデータベースに保存する. 成功したらtrue
// 画像はタイトル入力画面に行く前に取得しておいたもの（scene_save.pde）
boolean saveScreenshotToDatabase(PImage screenshot, String title) {
    if (db == null) {
        println("データベースに接続されていません");
        return false;
    }

    if (title.isEmpty()) {
        println("タイトルを入力してください");
        return false;
    }

    try {
        // 一時ファイルパスを指定
        String tempFilePath = getContext().getFilesDir() + "/screenshot.png";
        
        // ファイルに保存
        screenshot.save(tempFilePath);
        
        byte[] imageData = loadBytes(tempFilePath);
        
        // データベースに画像とタイトルを保存
        dbHelper.saveDrawing(title, imageData);
        println("保存成功: " + title);

        // 保存したファイルを削除（不要なファイルが残らないように）
        new File(tempFilePath).delete();
        return true;
    } catch (Exception e) {
        e.printStackTrace();
        println("データの保存に失敗しました");
        return false;
    }
}
