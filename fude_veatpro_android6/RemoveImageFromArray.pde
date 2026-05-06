import java.util.Arrays;

PImage[] removeImageFromArray(PImage[] arr, int index) {
  ArrayList<PImage> temp = new ArrayList<>(Arrays.asList(arr));
  temp.remove(index);
  return temp.toArray(new PImage[0]);
}
