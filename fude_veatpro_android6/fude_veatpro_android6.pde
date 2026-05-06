//各種必要な変数の定義、setup、draw等メインのタブ

import android.view.MotionEvent;

//各種フラグ
String scene = "title";              //現在のシーンをtitle,play,galleryで判別
boolean isTouched = false;           //タッチされているか
boolean isdrugged = false;           //ドラッグ中か
boolean start_pointed = false;       //入筆タッチされたか
boolean write_started = false;       //入筆→描画になったか
boolean get_play_image = true;       //play画面背景画像読み込み
boolean weight_set = false; //play画面で筆の太さ調節機能OnOff

//筆跡角度
float write_deg = 0;         //現在の進行方向
float fude_deg = 0;          //現在の筆の角度
float start_write_deg = 0;   //書き始めの進行方向
float start_fude_deg = 0;    //書き始めの筆の角度
float p_write_deg = 0;       //１フレーム前の進行方向
float p_fude_deg = 0;        //１フレーム前の筆の角度
float easing = 0.2;          //角度変化しやすさ
float startX = 0,startY = 0; //書き始め位置
float spread = 0;            //筆を押し付けた時の毛先の広がり
float p_spread = 0;          //１フレーム前の毛先の広がり

//圧力検知
float pressure = 0;          //圧力
float weight = 0;            //線の太さ
float p_weight = 0;          //１フレーム前の線の太さ
int w = 1;

//タッチ位置補正（圧力に応じて少しずれる）
float p_revX = 0;
float p_revY = 0;
float revX = 0;
float revY = 0;

//停止判定
boolean stopped = false;     //
int stopTime = 0;            //
int stopTimeThreshold = 500; //
float stopThreshold = 0.16;  //
float moveThreshold = 2;     //
int pmillis = 0;             //
int lastTouchTime = 0;       //

//掠れ表現用
PVector prevPos;              // 前回のクリック位置を保存するためのベクトル
float someStrokeWeight = 5;   // 何本も描画される線の太さ
float mainStrokeWeight = 15;  // 全体としての線の太さ
float numLines = 15;          // 複数の短い線の数。これを描画することで筆のボサボサ感を表現
float alpha = 255;            // 線全体の透明度（時間経過に伴う減少）
boolean isDrawing = false;    // 描画中かどうかのフラグ
float minAlpha = 100;         // 線全体の最小アルファ値
float minNumLines = 5;
int lastUpdateTime = 0;
float distance = 0;           //書き進めた距離（墨補充でリセットされる）
float distance1 = 0;         //一画ごとの書き進めた距離（筆を離すたびにリセットされる）
boolean kasure = false;       //掠れるがスピードや圧力次第ではまだ書ける
boolean noink_kasure = false; //墨が０なので一切書けない
float ink_meter = 700;


//保存閲覧関連
float infoX;  // ポップアップの座標たち
float infoY;
float infoW;
float infoH;
int btnX = (int)(infoX + infoW/2 - 48);
int btnY = (int)(infoY + infoH/2 - 300);
boolean galleryNeedsReload = true;  // ギャラリーを開きたい時にtrueになる
boolean isInfoVisible = false;      // ポップアップが見えているか
ArrayList<Integer> imageIds = new ArrayList<Integer>();  // 削除用
ArrayList<String> imageDates;
boolean isDrawingMode = true;

//その他
int help_page = 1;

float prevX = -1;
float prevY = -1;
boolean touched = false;

boolean justStarted = false;

PrintWriter logWriter;
boolean isLogging = false;



void setup()
{ 
  //色定義
  colorMode(HSB,360,100,100,100);    //カラーモード（色相、彩度、明度、透明度）
  color red = color(0,100,100,30);   //赤
  color trans = color(0,100,100,0);  //透明
  
  //ボタン定義
  tb_start = new Button(trans,1350,150,400,200);    //tb→タイトルボタン
  tb_gallery = new Button(trans,1350,450,400,200);
  tb_end = new Button(trans,1350,750,400,200);
  tb_help = new Button(trans,1715,28,70,70);
  pb_fude = new Button(trans,1440,970,200,90);      //pb→プレイボタン
  pb_reset = new Button(trans,1440,820,200,90);
  pb_end = new Button(trans,1680,970,200,90);
  pb_save = new Button(trans,1680,820,200,90);
  pb_ink = new Button(trans,1440,80,440,200);
  gb_end = new Button(red,10,10,100,50);            //gb→ギャラリーボタン
  gb_back = new Button(red, width-180, 20, 150, 50);
  gb_closeInfo = new Button(red, 1680, 970, 45, 45);
  gb_delete = new Button(red, 1800, 900, 200, 90);
  gb_send = new Button(red, 1500, 800, 100, 90);
  hb_end = new Button(trans,20,1080,330,90);            //hb→チュートリアルボタン
  hb_next = new Button(trans,1150,1060,150,100);
  hb_back = new Button(trans,620,1060,150,100);
  
  //画像読み込み
  title_image = loadImage("title_scene.png");                //タイトル画面背景
  play_image = loadImage("play_scene.png");                  //プレイ画面背景
  makimono_button_image = loadImage("makimono_button.png");  //巻物ボタン画像
  fude_shape = loadImage("fude_shape.png");                  //筆跡パターン画像
  kaishi = loadImage("kaishi.png");                          //「開始」文字透過画像
  syuuryou = loadImage("syuuryou.png");                      //「終了」
  sakuhinneturann = loadImage("sakuhinneturann.png");        //「作品閲覧」
  sakujo = loadImage("sakujo.png");                          //「削除」
  hozonn = loadImage("hozonn.png");                          //「保存」
  fude = loadImage("fude.png");                              //「筆」
  help1 = loadImage("help1.png");                            //ヘルプ画面
  help2 = loadImage("help2.png");                            //ヘルプ画面
  help3 = loadImage("help3.png");                            //ヘルプ画面
  help4 = loadImage("help4.png");                            //ヘルプ画面
  help5 = loadImage("help5.png");                            //ヘルプ画面
  help6 = loadImage("help6.png");                            //ヘルプ画面
  
  //掠れ
  prevPos = new PVector(mouseX, mouseY);   // 最初の位置を保存
  lastUpdateTime = millis();               // 現在の時刻を保存
  
  fullScreen();
  
  // 保存閲覧用
  connectToDatabase();
  titleInput = new TextBox(400, 20, 200, 40);
  requestPermission("android.permission.WRITE_EXTERNAL_STRAGE");
}

void draw()
{
  resetMatrix();
  
  if (isLogging) {
    logWriter.println(
    millis() + "," + pressure + "," + weight
    );
  }
  
  
  stroke(0,0,100,0);
  if(scene == "title")
    title();//title関数へ
  else if(scene == "play")
  {
    startLogging();
    if(get_play_image) //true＝画面リセットしたい
    {
      background(0,0,100,100);
      get_play_image = false; //リセットしたのでfalseに
    }
    play();//play関数へ
    titleInput.display();
  }
  else if(scene == "gallery")
    gallery();//gallery関数へ
  else if(scene == "help"){      
    help();
  }
}

void touchStarted()
{
  isTouched = true;
   if(scene == "title")//タイトル画面の時
   {
     if(tb_start.push(mouseX,mouseY))
       display_change("play");
     if(tb_gallery.push(mouseX,mouseY))
       display_change("gallery");
       isDrawingMode = false;
       galleryNeedsReload = true;
       clearDrawing();
     if(tb_end.push(mouseX,mouseY)){
       exit();//アプリ終了
       stopLogging();
     }
       
     if(tb_help.push(mouseX,mouseY)){
       help_page = 1;
       display_change("help");
     }
   }
   else if(scene == "play")//習字画面の時
   {
     // タイトル入力欄を表示
     // titleInput.display();
     titleInput.onMousePressed();
     
     if(pb_end.push(mouseX,mouseY))
     {
       ink_meter = 700;
       distance = 0;
       kasure = false;
       noink_kasure = false;
       display_change("title");
       get_play_image = true;
       weight_set = false;
     }
     if(pb_reset.push(mouseX,mouseY))
     {
       get_play_image = true;  //画面リセットしたい
     }
     if(pb_save.push(mouseX,mouseY))
     {
       textSize(20);
       fill(0);
       text("Save",10,30);
       saveScreenshotToDatabase();
       titleInput.text = "";
     }
     if(pb_fude.push(mouseX,mouseY))
     {
       if(weight_set)
         weight_set = false;
       else if(!weight_set)
         weight_set = true;   
     }
     if(pb_ink.push(mouseX,mouseY))
     {
       ink_meter = 700;
       distance = 0;
       kasure = false;
       noink_kasure = false;
     }
   }
   else if(scene == "gallery")
   {
     if(gb_end.push(mouseX,mouseY)) {
       clearGallery();
       display_change("title");
     }
       
     else if (gb_back.push(mouseX,mouseY)) {
       isDrawingMode = true;
       println("描画画面に戻ります");
       clearGallery();
       titleInput.text = "";
       background(255);
     }
  
     else if (!isDrawingMode && gb_delete.push(mouseX,mouseY)) {
       deleteSelectedImage();
       //galleryScene();
     }
  
     else if (isInfoVisible && gb_closeInfo != null && gb_closeInfo.push(mouseX,mouseY)) {
       println("インフォメーションを閉じます");
       isInfoVisible = false;
       gb_closeInfo = null;
       galleryNeedsReload = true;
       return;
     }
  
     else if (isInfoVisible && gb_send != null && gb_send.push(mouseX, mouseY)) {
       println("PCにデータを送信します");
       saveImageToMediaStore(selectedImageIndex);
     }
     
     if (!isDrawingMode) {
       selectImage();
     }
   }
 
   else if(scene == "help")
   {
     if(hb_end.push(mouseX,mouseY))
       display_change("title");
     if(hb_next.push(mouseX,mouseY) && (help_page < 6))
       help_page++;
     if(hb_back.push(mouseX,mouseY) && (1 < help_page))
       help_page--;
   }
}

void touchMoved()
{
  isdrugged = true;
  if(scene == "play"){
    if(pb_ink.push(mouseX,mouseY))
     {
       ink_meter = 700;
       distance = 0;
       kasure = false;
       noink_kasure = false;
     }
  }
  
  if (scene == "gallery") {
    float dy = mouseY - pmouseY;
    scrollOffset += dy;
    scrollOffset = constrain(scrollOffset, -maxScroll, 0);
    
  }
}


void touchEnded()
{
  if(scene == "play"){
    if(pb_ink.push(mouseX,mouseY))
     {
       ink_meter = 700;
       distance = 0;
       kasure = false;
       noink_kasure = false;
     }
  }
  if(!kasure){
    spread = 0;
    p_spread = 0;
  }
  isdrugged = false;
  isTouched = false;
  start_pointed = false;
  write_started = false;
  stopped = false;
  stopTime = 0;
  distance1 = 0;
}


void keyPressed() {
  println("キーが押されました: " + key);
  println("キーコードが押されました: " + keyCode);
  if (titleInput != null & titleInput.isActive()) {
    titleInput.keyPressed(key, keyCode);
  }
}
