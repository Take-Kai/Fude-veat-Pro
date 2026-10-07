//scene help
//ヘルプ画面の処理を書く

void help()
{
  switch(help_page) {
  case 1:
    image(help1,0,0,1920,1200);
    break;
  case 2:
    image(help2,0,0,1920,1200);
    break;
  case 3:
    image(help3,0,0,1920,1200);
    break;
  case 4:
    image(help4,0,0,1920,1200);
    break;
  case 5:
    image(help5,0,0,1920,1200);
    break;
  case 6:
    image(help6,0,0,1920,1200);
    break;
  default:
    println("-------error-------");
    break;
  }
  hb_end.set();
  hb_next.set();
  hb_back.set();
}
