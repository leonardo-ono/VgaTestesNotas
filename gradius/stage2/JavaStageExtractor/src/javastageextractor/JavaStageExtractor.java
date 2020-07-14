/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package javastageextractor;

import java.awt.Color;
import java.awt.image.BufferedImage;
import java.io.File;
import javax.imageio.ImageIO;

/**
 *
 * @author admin
 */
public class JavaStageExtractor {

    /**
     * @param args the command line arguments
     */
    public static void main(String[] args) throws Exception {
        String path = "D:/javaGradius/video/video/";
        int startFrame = 142;
        int endFrame = 3209;
        int stepFrame = 256; //576;
        int imageCount = 0;
        BufferedImage stage01 = new BufferedImage(13 * 570, 480, BufferedImage.TYPE_INT_RGB);
        for (int i = startFrame; i <= endFrame + 256; i += stepFrame) {
            String index = "00000" + i;
            index = index.substring(index.length() - 5, index.length());
            String filename = "videoplayback " + index + ".jpg";
            BufferedImage image = ImageIO.read(new File(path + filename));
            System.out.println("leu imagem " + index + " count: " + imageCount);
            
            int dx1 = 570 * imageCount;
            int dy1 = 0;
            int dx2 = dx1 + 570;
            int dy2 = 480;

            int sx1 = 42;
            int sy1 = 0;
            int sx2 = sx1 + 570;
            int sy2 = 480;
            //stage01.getGraphics().drawImage(image, 654 * imageCount, 0, null);
            stage01.getGraphics().drawImage(image, dx1, dy1, dx2, dy2, sx1, sy1, sx2, sy2, null);
            stage01.getGraphics().setColor(Color.WHITE);
            stage01.getGraphics().drawLine(dx2 - 1, 0, dx2 - 1, 480);
            imageCount++;
        }
        ImageIO.write(stage01, "png", new File("D:/javaGradius/video/stage1.png"));
    }
    
}
