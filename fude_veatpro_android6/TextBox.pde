import android.view.inputmethod.InputMethodManager;
import java.io.FileInputStream;

// テキストボックスのクラス
class TextBox {
  String text = "";
  int x, y, w, h;
  boolean active = false;
  long cursorBlinkTimer = 0;  // カーソル点滅用のタイマー
  boolean cursorVisible = true;
  
  TextBox(int x, int y, int w, int h) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
  }
  
  void display() {
    stroke(0);
    fill(active ? color(230) : 255);
    // fill(255);
    rect(x, y, w, h, 5);
    fill(0);
    textAlign(LEFT, CENTER);
    textSize(14);
    
    String displayText = text;
    if (active && cursorVisible) {
      displayText += "|";  // これカーソルね
    }
    text(text, x + 10, y + h / 2);
    
    // カーソルの点滅タイミング
    if (millis() - cursorBlinkTimer > 500) {
      cursorVisible = !cursorVisible;
      cursorBlinkTimer = millis();
    }
  }
  
  void keyPressed(char key, int keyCode) {
    // テキストボックスがアクティブな時にキー入力処理
    // if (titleInput != null && titleInput.isActive()) {
      // titleInput.onKeyPressed(key);
      
      
  // キーボード入力を処理
  if (active) {
    // バックスペースキーの処理
    // if (key == BACKSPACE && text.length() > 0) {
     if ((keyCode == 67) && text.length() > 0){
      text = text.substring(0, text.length() - 1);
    } 
    // 特殊キー（ENTERやRETURN）のチェック
    else if (keyCode == 66) {
    // else if (key == ENTER || key == RETURN) {
      println(key + "が押されました");
      hideKeyboard();
      active = false;
    }
    else if (key != BACKSPACE && key != ENTER && key != RETURN && key != CODED) {
      text += key;
    }
    println("現在のテキスト: " + text);
  }
 }
  
  // マウスがテキストボックスをクリックしたかを判定
  void onMousePressed() {
    if (mouseX >= x && mouseX <= x + w && mouseY >= y && mouseY <= y + h) {
      println("テキストボックスに入力が可能です");
      active = true;
      showKeyboard();
    } else {
      active = false;
      hideKeyboard();
    }
  }
  
  /*
  // キーボード入力を処理
  if (active) {
    // バックスペースキーの処理
    // if (key == BACKSPACE && text.length() > 0) {
      if ( key == BACKSPACE) {
        println(key + "が押されました");
      text = text.substring(0, text.length() - 1);
    } 
    // 特殊キー（ENTERやRETURN）のチェック
    else if (key == ENTER || key == RETURN) {
      println(key + "が押されました");
      hideKeyboard();
      active = false;
    }
    else if (key != BACKSPACE && key != ENTER && key != RETURN && key != CODED) {
      text += key;
    }
    println("現在のテキスト: " + text);
  }
}
*/

  boolean isActive() {
    return active;
  }
  
  // キーボード表示
  void showKeyboard() {
    InputMethodManager imm = (InputMethodManager) getActivity().getSystemService(Context.INPUT_METHOD_SERVICE);
    if (imm != null) {
      imm.showSoftInput(getActivity().getCurrentFocus(), InputMethodManager.SHOW_IMPLICIT);
      // imm.toggleSoftInput(InputMethodManager.SHOW_FORCED, 0); // imm.toggleは将来なくなる可能性があるメソッドらしい
    }
  }
  
  // キーボード非表示
  void hideKeyboard() {
    InputMethodManager imm = (InputMethodManager) getActivity().getSystemService(Context.INPUT_METHOD_SERVICE);
    if (imm != null) {
      imm.hideSoftInputFromWindow(getActivity().getWindow().getDecorView().getWindowToken(), 0);
    }
  }
  
  // テキストを取得
  String getText() {
    return text;
  }
}
