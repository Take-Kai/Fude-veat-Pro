void startLogging() {
  logWriter = createWriter("pressure_weight_log.csv");
  logWriter.println("time_ms,pressure,weight");
  isLogging = true;
}
