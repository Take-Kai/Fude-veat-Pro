//deg_reset関数
//write_degを0以上～360未満内に修正する

float deg_reset(float deg){
  
  while (!(360 > deg && deg >= 0))
  {
    if(deg == 360)
      deg = 0;
    if (deg > 360)
      deg -= 360;
    if (0 > deg)
      deg += 360;
  }
  
  return deg;
}
