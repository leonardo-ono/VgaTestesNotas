/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package javaconvertbmptoasm;

import java.awt.image.BufferedImage;
import java.awt.image.ColorModel;
import java.awt.image.DataBufferByte;
import java.io.File;
import java.util.Arrays;
import javax.imageio.ImageIO;

/**
 *
 * @author admin
 */
public class JavaConvertBmpToAsm {

    /**
     * @param args the command line arguments
     */
    public static void main(String[] args) throws Exception {
        BufferedImage img = ImageIO.read(new File("D:/vga/black.bmp"));
        ColorModel colorModel = img.getColorModel();
        // System.out.println(colorModel);
        DataBufferByte dataBuffer = (DataBufferByte) img.getRaster().getDataBuffer();
        byte[] data = dataBuffer.getData();
        
        System.out.println("; size: (" + img.getWidth() + ", " + img.getHeight() + ")");
        int page = 0;
        int cont = 0;
        int maxCont = 16;

        //System.out.println("; page=" + page);
        //System.out.println("img_page_" + page + ":");
        System.out.println("img_width dw " + img.getWidth());
        System.out.println("img_height dw " + img.getHeight());
        System.out.println("img:");
        System.out.print("   db ");
        
        for (int i = 0; i < data.length; i++) {
            if (true || (i % 4) == page) {
                int c = data[i] & 0xff;
                String cstr = "000" + Integer.toHexString(c);
                cstr = cstr.substring(cstr.length() - 3, cstr.length()) + "h";
                if (cont < maxCont) {
                    System.out.print(cstr + ", ");
                    cont++;
                }
                else if (cont == maxCont) {
                    System.out.println(cstr);
                    System.out.print("   db ");
                    cont = 0;
                }
            }
        }
        System.out.println();
    }
    
}
