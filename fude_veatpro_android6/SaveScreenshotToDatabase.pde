TextBox titleInput;

void saveScreenshotToDatabase() {
    if (db == null) {
        println("データベースに接続されていません");
        return;
    }

    String title = titleInput.getText();

    if (title.isEmpty()) {
        println("タイトルを入力してください");
        return;
    }

    PImage screenshot = get(170, 0, 1220, 1200);  // 描画画面を取得

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
    } catch (Exception e) {
        e.printStackTrace();
        println("データの保存に失敗しました");
    }
}
