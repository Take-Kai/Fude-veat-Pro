//fude_line関数
//毛先が開く様子を過去フレームと現在フレームで線で補完する

void fude_line(float r,float deg,float p_deg)
{
  float cosine = cos(radians(deg));
  float sine = sin(radians(deg));
  float p_cosine = cos(radians(p_deg));
  float p_sine = sin(radians(p_deg));
  line(pmouseX+(r*p_weight*p_cosine)+(r*p_revX),
    pmouseY-(r*p_weight*p_sine)+(r*p_revY),
    mouseX+(r*weight*cosine)+(r*revX),
    mouseY-(r*weight*sine)+(r*revY));
}
