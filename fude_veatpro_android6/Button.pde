//ボタン変数定義とボタンクラス作成のタブ

//title button
Button tb_start;
Button tb_gallery;
Button tb_end;
Button tb_help;

//play button
Button pb_end;
Button pb_save;
Button pb_fude;
Button pb_reset;
Button pb_ink;

//gallery button
Button gb_end;
Button gb_back;
Button gb_delete;
Button gb_closeInfo;
Button gb_send;

//help button
Button hb_end;
Button hb_next;
Button hb_back;


//Button クラス　長方形型のボタンを作る
class Button{
  color bcolor;  //色
  int x;         //左上x
  int y;         //左上y
  int bwidth;    //ボタンの横幅
  int bheight;   //ボタンの縦幅
  
  Button(color tbcolor,int tx,int ty,int tbwidth,int tbheight){
    bcolor = tbcolor;
    x = tx;
    y = ty;
    bwidth = tbwidth;
    bheight = tbheight;
  }
  
  void set(){
    //ボタンを決められた位置に配置する　ボタンの判定位置の目視化
    //実は透明なボタンなら設置しなくても良い…
    fill(bcolor);
    rect(x,y,bwidth,bheight);
  }
  
  boolean push(float px,float py){
    //引数にタッチ位置のx,yを渡すと、ボタンの範囲内か判定する
    if(x <= px && px <= (x+bwidth)){
      if(y <= py && py <= (y+bheight))
        return true;
      else
        return false;
    }
    else
      return false;
  }
}
