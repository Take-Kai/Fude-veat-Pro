//deg_reset関数
//write_degを0以上～360未満内に修正する

float deg_reset(float deg){
  
  //NaNや無限大が来ると下のwhileが終わらず固まるので0にする
  if (Float.isNaN(deg) || Float.isInfinite(deg))
    return 0;
  
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
