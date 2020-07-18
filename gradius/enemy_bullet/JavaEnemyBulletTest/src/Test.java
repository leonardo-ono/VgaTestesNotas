/**
 *
 * @author admin
 */
public class Test {

    public static void main(String[] args) {
        System.out.println("test!");
        
        int[] sinTable = new int[256];
        double div = (2 * Math.PI) / 255.0;
        for (int i = 0; i < 256; i++) {
            double angle = i * div;
            double sin = Math.sin(angle);
            int sinInt = ((byte) (int) (sin * 128)) & 0xff;
            //if (sinInt < 0) {
            //    sinInt = 256 + sinInt;
            //}
            // sinInt = sinInt >> 8;
            sinTable[i] = sinInt;
            System.out.println("angle " + Math.toDegrees(angle) + " sin=" + sin + " sinInt=" + sinInt);
        }
        System.out.println("" + ((63 * 100) >> 7));
        
        System.out.println(((byte) 255) + 10);
    }
    
}
