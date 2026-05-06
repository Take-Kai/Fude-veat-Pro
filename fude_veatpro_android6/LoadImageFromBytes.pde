import java.io.FileOutputStream;

public PImage loadImageFromBytes(byte[] imageData) {
  try {
    File tempFile = File.createTempFile("image", ".png", getContext().getCacheDir());
    FileOutputStream fos = new FileOutputStream(tempFile);
    fos.write(imageData);
    fos.close();
    
    PImage img = loadImage(tempFile.getAbsolutePath());
    tempFile.delete();
    return img;
  } catch (Exception e) {
    e.printStackTrace();
    return null;
  }
}
