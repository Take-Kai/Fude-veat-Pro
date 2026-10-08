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

    // ACTION_MOVE / ACTION_UP では touchMoved() / touchEnded() を直接呼ばない
    // 下の super.surfaceTouchEvent() を通すとProcessingが描画スレッドで呼んでくれるので,
    // ここでも呼ぶと1回の移動で2回実行されてしまう（しかもこちらはUIスレッド）
    case MotionEvent.ACTION_MOVE:
      touched = false;
      
      if (justStarted) {
        justStarted = false;
        return super.surfaceTouchEvent(event);
      }
      
      break;

    case MotionEvent.ACTION_UP:
      touched = false;
      break;
  }

  return super.surfaceTouchEvent(event); 
  
}
