//作品タイトルの入力欄（日本語入力用）
//
//Processingの画面はキー入力を1文字ずつしか受け取れないので, 日本語の変換入力ができない.
//なので, Android標準の入力欄（EditText）を, タイトル入力画面の入力欄の位置に重ねて表示する.
//入力欄の枠はProcessingで描き（scene_save.pde）, EditTextは背景を透明にして文字だけを表示する.

import android.app.Activity;
import android.widget.EditText;
import android.widget.FrameLayout;
import android.view.View;
import android.view.ViewGroup;
import android.view.Gravity;
import android.view.WindowManager;
import android.view.inputmethod.EditorInfo;
import android.graphics.Typeface;
import android.graphics.Color;
import android.text.TextWatcher;
import android.text.Editable;
import android.util.TypedValue;

EditText titleEdit;
volatile String titleEditText = "";  // 入力された文字（描画スレッドから読む）


// 入力欄を(x, y)にw×hの大きさで表示し, キーボードを出す
void showTitleEdit(final int x, final int y, final int w, final int h)
{
  titleEditText = "";
  final Activity act = getActivity();
  act.runOnUiThread(new Runnable() {
    public void run() {
      if (titleEdit == null) {
        titleEdit = new EditText(act);
        titleEdit.setSingleLine(true);
        titleEdit.setBackgroundColor(Color.TRANSPARENT);
        titleEdit.setTextColor(Color.BLACK);
        titleEdit.setTextSize(TypedValue.COMPLEX_UNIT_PX, h * 0.5);
        titleEdit.setPadding(20, 0, 20, 0);
        titleEdit.setGravity(Gravity.CENTER_VERTICAL);
        titleEdit.setImeOptions(EditorInfo.IME_ACTION_DONE);
        try {
          titleEdit.setTypeface(Typeface.createFromAsset(act.getAssets(), "YujiSyuku-Regular.ttf"));
        } catch (Exception e) {
          println("入力欄のフォントを読み込めませんでした");
        }
        titleEdit.addTextChangedListener(new TextWatcher() {
          public void beforeTextChanged(CharSequence s, int start, int count, int after) {}
          public void onTextChanged(CharSequence s, int start, int before, int count) {}
          public void afterTextChanged(Editable s) {
            titleEditText = s.toString();
          }
        });
        // キーボードが出ても画面がずれないようにする
        act.getWindow().setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_ADJUST_NOTHING);
        ViewGroup root = (ViewGroup) act.findViewById(android.R.id.content);
        root.addView(titleEdit, new FrameLayout.LayoutParams(w, h));
      }
      FrameLayout.LayoutParams lp = (FrameLayout.LayoutParams) titleEdit.getLayoutParams();
      lp.leftMargin = x;
      lp.topMargin = y;
      lp.width = w;
      lp.height = h;
      lp.gravity = Gravity.TOP | Gravity.LEFT;
      titleEdit.setLayoutParams(lp);
      titleEdit.setText("");
      titleEdit.setVisibility(View.VISIBLE);
      focusTitleEditOnUiThread();
    }
  });
}


// 入力欄にもう一度カーソルを置いてキーボードを出す（タイトルが空のまま保存を押された時など）
void focusTitleEdit()
{
  getActivity().runOnUiThread(new Runnable() {
    public void run() {
      focusTitleEditOnUiThread();
    }
  });
}


void focusTitleEditOnUiThread()
{
  if (titleEdit == null) return;
  titleEdit.requestFocus();
  InputMethodManager imm = (InputMethodManager) getActivity().getSystemService(Context.INPUT_METHOD_SERVICE);
  if (imm != null) imm.showSoftInput(titleEdit, InputMethodManager.SHOW_IMPLICIT);
}


// 入力欄とキーボードを隠す
void hideTitleEdit()
{
  getActivity().runOnUiThread(new Runnable() {
    public void run() {
      if (titleEdit == null) return;
      InputMethodManager imm = (InputMethodManager) getActivity().getSystemService(Context.INPUT_METHOD_SERVICE);
      if (imm != null) imm.hideSoftInputFromWindow(titleEdit.getWindowToken(), 0);
      titleEdit.clearFocus();
      titleEdit.setVisibility(View.GONE);
    }
  });
}
