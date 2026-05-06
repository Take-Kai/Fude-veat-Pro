//scene title
//タイトル画面の処理を書く

void title()
{
  image(title_image,0,0,1920,1200);          //タイトル画面背景
  image(makimono_button_image,1300,150);     //ボタン画像配置
  image(makimono_button_image,1300,450);     
  image(makimono_button_image,1300,750);     
  image(kaishi,1425,210,375,150);            //文字配置
  image(sakuhinneturann,1390,520,375,150);   
  image(syuuryou,1425,810,375,150);        
  tb_start.set();                            //ボタン配置
  tb_gallery.set();
  tb_end.set();
  tb_help.set();
  strokeWeight(8);
  fill(0,0,100,0);
  stroke(75,30,35,100);//黄緑
  ellipse(1750,62.5,70,70);
  strokeWeight(5);
  textSize(50);
  fill(75,30,35,100);
  text("?",1738,77.5);
}
