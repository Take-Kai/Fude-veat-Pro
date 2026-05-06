void stopLogging() {
  if (logWriter != null) {
    logWriter.flush();
    logWriter.close();
    logWriter = null;
  }
  isLogging = false;
}
