// この関数で全てのタッチイベントを手動で管理
boolean surfaceTouchEvent(MotionEvent event){
  pressure = event.getPressure();

  int action = event.getAction();
  switch (action) {
    case MotionEvent.ACTION_DOWN:
      stopped = false;  // タッチ開始時にフラグをリセット
      stopTime = 0;
      pmillis = millis();
      
      touched = true;
      
      justStarted = true;
      
      prevX = event.getX();
      prevY = event.getY();
      break;

    case MotionEvent.ACTION_MOVE:
      touchMoved();  // タッチ移動時に描画処理を行う
      touched = false;
      
      if (justStarted) {
        justStarted = false;
        return super.surfaceTouchEvent(event);
      }
      
      break;

    case MotionEvent.ACTION_UP:
      touchEnded();  // タッチ終了時に再び描画を可能に
      touched = false;
      break;
  }

  return super.surfaceTouchEvent(event); 
  
}
