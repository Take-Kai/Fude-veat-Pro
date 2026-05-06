//角度変化 deg_get関数
//dx,dyから１フレームごとに筆を書き進めている角度（運筆方向）を計算する

float deg_get(float dx, float dy, float p_write_deg){
  
  int direction = 0;  //1～4　象限
  
  float at_rad = atan(dy/dx);
  float at_deg = degrees(at_rad);
  float t_write_deg = 0;    //目標角
  
  //象限判定
  if (dx >= 0)
  {
    if (dy >= 0)
      direction = 4;
    else
      direction = 1;
  } else {
    if (dy >= 0)
      direction = 3;
    else
      direction = 2;
  }
  
  //手振れ対策
  if (dist(0,0,dx,dy) < 2.5)
    direction = 5;

  switch(direction) {
  case 1:
    //println("右上");
    t_write_deg = -at_deg;
    break;
  case 2:
    //println("左上");
    t_write_deg = 180-at_deg;
    break;
  case 3:
    //println("左下");
    t_write_deg = 180-at_deg;
    break;
  case 4:
    //println("右下");
    t_write_deg = 360-at_deg;
    break;
  case 5:
    //println("停止");
    t_write_deg = p_write_deg;
    break;
  default:
    println("-------error-------");
    break;
  }
  
  return t_write_deg;
}
