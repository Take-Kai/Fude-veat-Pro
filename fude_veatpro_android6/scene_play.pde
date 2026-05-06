//scene play
//書道画面（プレイ画面）の処理を書く。

void play()
{
  image(play_image, 0, 0, 1920, 1200);  //背景画像セット
  pb_fude.set();    //各種ボタンセット
  pb_reset.set();
  pb_end.set();
  pb_save.set();
  pb_ink.set();
  image(makimono_button_image, 1420, 800, 240, 130);//左上  削除
  image(makimono_button_image, 1660, 800, 240, 130);//右上　保存
  image(makimono_button_image, 1420, 950, 240, 130);//左下　筆
  image(makimono_button_image, 1660, 950, 240, 130);//右下　終了
  image(sakujo,1470,815,200,80);
  image(hozonn,1710,815,200,80);
  image(syuuryou,1710,965,200,80);
  image(fude,1470,965,200,80);
  textSize(20);
  strokeWeight(0);
  stroke(0);
  fill(0);
  if(mouseX <= 1400)
    weight_set = false;
  if(weight_set){
    stroke(0);
    strokeWeight(5);
    fill(75,30,65,50);//黄緑
    rect(1420,420,460,300);//黄緑四角表示
    line(1450,450,1450,500);
    line(1550,450,1550,500);
    line(1650,450,1650,500);
    line(1750,450,1750,500);
    line(1850,450,1850,500);
    fill(0);
    textSize(30);
    beginShape();
    vertex(1450,475);
    vertex(1850,460);
    vertex(1850,490);
    endShape(CLOSE);
    if(mousePressed && 440 < mouseY && mouseY < 510 && 1400 < mouseX)
      w = ((mouseX-1400)/100)+1;
    if(w<1)w=1;
    if(w>5)w=5;
    strokeWeight(0);
    textSize(25);
    for(int i=1; i<6; i++)
      text(i,1340+100*i,530);
    fill(255);
    strokeWeight(3);
    ellipse(1400+50*(2*w-1),475,20,20);
  }
  
  //墨残量メーター
  if(distance > 6000)
    fill(0,0,30,100);
  else
    fill(0);
  strokeWeight(0);
  rect(68,180+700-ink_meter,20,ink_meter);

  // 一定時間タッチがない場合にリセット処理
  if (millis() - lastTouchTime > stopTimeThreshold) {
    stopped = false;
  }

  float dx = mouseX-pmouseX;
  float dy = mouseY-pmouseY;
    
  //リアルタイムで進行方向検出
  write_deg = deg_get(dx,dy,p_write_deg);
  write_deg = deg_reset(write_deg);
  float r_fude_deg = write_deg + 180;
  r_fude_deg = deg_reset(r_fude_deg);
  float t_fude_deg = ((start_fude_deg + r_fude_deg)/2);
  t_fude_deg = deg_reset(t_fude_deg);
  
  //角度修正
  if (180 > fude_deg) {
    if (t_fude_deg > fude_deg+180) {
      t_fude_deg = -(360 - t_fude_deg);
    }
  } else {
    if (fude_deg-180 > t_fude_deg) {
      fude_deg = -(360 - fude_deg);
    }
  }
  
  if(abs(fude_deg-write_deg) > 70)
    fude_deg += (t_fude_deg - fude_deg) * easing;
  
  t_fude_deg = deg_reset(t_fude_deg);
  fude_deg = deg_reset(fude_deg);
  float fude_rad = radians(fude_deg);

  if (isTouched) {
    
    // 描画開始時、前回の位置をリセット
    if (!isDrawing) {
      prevPos = new PVector(mouseX, mouseY);
      isDrawing = true;
    }
    
    // マウスの動かす速度を計算
    float speed = dist(mouseX, mouseY, prevPos.x, prevPos.y);
    distance += speed;
    distance1 += speed;
    distance = constrain(distance,0,18000);
    ink_meter = (700 + ((-700*distance)/18000));
    
    if(speed < 170)
      kasure = false;
    if(speed > 170 || distance > 6000)
      kasure = true;
    if(distance >= 18000)
      noink_kasure = true;
    
    // 全体のベースアルファ値を決定（時間経過で薄くなる）
    float baseAlpha = map(speed, 0, 10, 150, 255);  // 速く動かすと薄くなるが、濃淡はランダムに設定
    baseAlpha = constrain(baseAlpha, minAlpha, 255);  // 基準値を範囲内に収める
    
    //書き始め処理
    if (!write_started) {
      if (!start_pointed) {
        startX = mouseX;
        startY = mouseY;
        start_pointed = true;  //書き始め１点
      }     
      if (dist(startX, startY, mouseX, mouseY)>25) {
        write_deg = deg_get(mouseX-startX, mouseY-startY, 0);
        start_write_deg = write_deg;
        start_fude_deg = start_write_deg +180;
        start_fude_deg = deg_reset(start_fude_deg);
        fude_deg = write_deg + 180;
        fude_deg = deg_reset(fude_deg);
        p_fude_deg = write_deg + 180;
        p_fude_deg = deg_reset(p_fude_deg);
        fude_rad = radians(fude_deg);
        write_started = true;
      }
    }

    if (isdrugged && write_started) {
      if (!stopped) { //動いている時
        weight = pow(pressure, 2) * (1100 + 250*w);
        //easing0～0.4とpressure0.21～0を対応
        easing = (0.4/sqrt(0.211))*sqrt(0.211-pressure);
        if(!noink_kasure && weight > 60 && speed < 80)
          kasure = false;
        stroke(0);
        strokeWeight(weight);
        
        revX = weight*0.65*sin(radians(fude_deg-90));
        revY = weight*0.65*cos(radians(fude_deg-90));
        
        //ただの黒線               
        if(!kasure && !noink_kasure && distance1 > 60) {
          line(pmouseX+p_revX, pmouseY+p_revY, mouseX+revX, mouseY+revY);
          println("普通の線");
        } else if (!justStarted) {
              println("かすれ");
              noStroke();
              
              // float distMoved = dist(mouseX, mouseY, pmouseX, pmouseY);
              // int steps = max(int(distMoved / 0.5), 1);
              
              if (kasure && !noink_kasure) {
                if (prevX != -1 && prevY != -1) {
                  float distMoved = dist(mouseX, mouseY, prevX, prevY);
                  int steps = max(int(distMoved / 1.5), 1);
                  for (int i = 0; i < steps; i++) {
                    float t = map(i, 0, steps, 0, 1);
                    float x = lerp(prevX, mouseX, t);
                    float y = lerp(prevY, mouseY, t);
                    drawBrushStroke(x, y, distMoved, prevX, prevY, mouseX, mouseY);
                }        
              }
              prevX = mouseX;
              prevY = mouseY;
           }
       }
    
        /*
        // numLinesの数だけランダムにずれた線を描画
        for (int i = 0; i < numLines; i++) {
          // ランダムなオフセットを設定して、線のぶれを表現
          //float offsetX = random(-mainStrokeWeight, mainStrokeWeight);
          //float offsetY = random(-mainStrokeWeight, mainStrokeWeight);
          float offsetX = random(-weight*3/7,weight*3/7);
          float offsetY = random(-weight*3/7,weight*3/7);
      
          // より強調されたランダムなアルファ値を生成し、濃淡を作成
          float lineAlpha = 0;
          if(!kasure)
            lineAlpha = (baseAlpha/2);
          else
            lineAlpha = random(10, baseAlpha);  // 30からベースアルファまでの範囲でランダム
          lineAlpha = constrain(lineAlpha, minAlpha, 255);  // アルファ値を強調
          stroke(0, lineAlpha * (alpha / 255));  // 線全体のアルファ値を掛け合わせて透明度を決定
          
          // ランダムな線の太さ
          float randomStrokeWeight = 0;
          if(!kasure)
            randomStrokeWeight = weight/30;
          else
            randomStrokeWeight = random(1, someStrokeWeight);
          // strokeWeight(mainStrokeWeight);
          strokeWeight(randomStrokeWeight);
          stroke(0, lineAlpha * (alpha / 255));

          
          // かすれ線を描画          
          if(!noink_kasure && distance1 > 50){
            line(prevPos.x + offsetX, prevPos.y + offsetY, mouseX + offsetX, mouseY + offsetY);
            line(prevPos.x + offsetX + p_revX, prevPos.y + offsetY + p_revY, mouseX + offsetX + revX, mouseY + offsetY + revY);
          }          
          
        }
        */

        if (write_started) {
          if (weight > 10) {          
            if(distance1 < 50 && distance < 3000)
              spread = weight * 0.15;
            else{
              spread = weight * 0.25; 
              if(spread < 8)
                spread *= 0.5;
            }
          
            //雫形透過画像
            pushMatrix();
            translate(mouseX + revX, mouseY + revY);
            rotate(-fude_rad+radians(90));            
            if(!kasure && !noink_kasure)
              image(fude_shape, -(weight/2), -weight, weight, (weight/0.7));                    
            popMatrix();            
            
            if(!kasure && !noink_kasure && distance1 > 50){
              
              strokeWeight(weight/12);
              stroke(0);
              
              //毛先の広がりを考慮
              for(float i=1; i>0; i-=0.15)
                fude_line(i, fude_deg, p_fude_deg);                           
              for(float i=1; i>0; i-=0.15)
                fude_line(i, fude_deg + spread, p_fude_deg + p_spread);          
              for(float i=1; i>0; i-=0.15)
                fude_line(i, fude_deg + (spread/2), p_fude_deg + (p_spread/2));      
              for(float i=1; i>0; i-=0.15)
                fude_line(i,fude_deg - spread, p_fude_deg - p_spread);        
              for(float i=1; i>0; i-=0.15)
                fude_line(i,fude_deg - (spread/2), p_fude_deg - (p_spread/2)); 
              
              fill(0);              
              
              //側面補間
              beginShape();
              vertex(pmouseX-((p_weight/2.1)*sin(radians(p_fude_deg)))+p_revX, pmouseY-((p_weight/2.1)*cos(radians(p_fude_deg)))+p_revY);
              vertex(pmouseX+(p_weight*cos(radians(p_fude_deg+p_spread)))+p_revX, pmouseY-(p_weight*sin(radians(p_fude_deg+p_spread)))+p_revY);
              vertex(mouseX+(weight*cos(radians(fude_deg+spread)))+revX, mouseY-(weight*sin(radians(fude_deg+spread)))+revY);
              vertex(mouseX-((weight/2.1)*sin(radians(fude_deg)))+revX, mouseY-((weight/2.1)*cos(radians(fude_deg)))+revY);
              endShape(CLOSE);
              
              beginShape();
              vertex(pmouseX+((p_weight/2.1)*sin(radians(p_fude_deg)))+p_revX, pmouseY+((p_weight/2.1)*cos(radians(p_fude_deg)))+p_revY);
              vertex(pmouseX+(p_weight*cos(radians(p_fude_deg-p_spread)))+p_revX, pmouseY-(p_weight*sin(radians(p_fude_deg-p_spread)))+p_revY);
              vertex(mouseX+(weight*cos(radians(fude_deg-spread)))+revX, mouseY-(weight*sin(radians(fude_deg-spread)))+revY);
              vertex(mouseX+((weight/2.1)*sin(radians(fude_deg)))+revX, mouseY+((weight/2.1)*cos(radians(fude_deg)))+revY);
              endShape(CLOSE);
              
            }
          }
        }

        pmillis = millis();
        lastTouchTime = millis();
      }
      p_write_deg = write_deg;
      p_fude_deg = fude_deg;
      p_weight = weight;
      p_spread = spread;
      p_revX = revX;
      p_revY = revY; 
    }
    // 前回のマウス位置を更新
    prevPos.set(mouseX, mouseY);

    // 時間経過に伴い全体のアルファ値を減少させる（掠れ表現）
    alpha -= map(speed, 0, 10, 0.3, 2.0);  // スピードに応じて減少率を変える
    alpha = constrain(alpha, minAlpha, 255);  // 最小値まで減少
  
    //text(weight,10,50);
  
    if (millis() - lastUpdateTime >= 1000) {
      numLines = max(numLines - 1, minNumLines);
      lastUpdateTime = millis();
    }
  } else {
    isDrawing = false;
    prevX = -1;
    prevY = -1;
  }
}
