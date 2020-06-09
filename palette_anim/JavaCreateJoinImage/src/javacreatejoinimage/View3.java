/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package javacreatejoinimage;

import java.awt.Color;
import java.awt.Dimension;
import java.awt.Graphics;
import java.awt.Graphics2D;
import java.awt.event.MouseEvent;
import java.awt.event.MouseMotionListener;
import java.awt.image.BufferedImage;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.io.PrintWriter;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;
import javax.imageio.ImageIO;
import javax.swing.JFrame;
import javax.swing.JPanel;
import javax.swing.SwingUtilities;

/**
 * This works for ...\vga\palette_anim\test2\ project
 * even - 0~127
 * odd  - 128~255
 * @author admin
 */
public class View3 extends JPanel implements MouseMotionListener {
    
    
    // page 0
    private static final int PAGE = 0;
    private static final int START_IMAGE_INDEX = 0;
    private static final int END_IMAGE_INDEX = 6;

    // page 1
    //private static final int PAGE = 1;
    //private static final int START_IMAGE_INDEX = 7;
    //private static final int END_IMAGE_INDEX = 13;

    // page 2
    //private static final int PAGE = 2;
    //private static final int START_IMAGE_INDEX = 14;
    //private static final int END_IMAGE_INDEX = 20;
    
    // page 3
    //private static final int PAGE = 3;
    //private static final int START_IMAGE_INDEX = 21;
    //private static final int END_IMAGE_INDEX = 27;
    
    private static final int LAST_FRAME = 27; // 0~n
    private static final int SKIP_FRAMES = 1; // 0~n
    
    private static final String IMG_PATH = "D:/vga/palette_anim/frames4/";
    private static final String OUT_DATA_FILE = "D:/vga/palette_anim/test2/data/page_" + PAGE + ".dat";
    private static final String OUT_ASM_PAL_FILE = "D:/vga/palette_anim/test2/data/pal_" + PAGE + ".asm";
    private BufferedImage[] images = new BufferedImage[(LAST_FRAME + 1) / SKIP_FRAMES];
    
    private static final int PAL_BLACK = -16777216;
    private static final int PAL_WHITE = -1;
    
    private int[][] mix = new int[200][320];
    
    Map<Integer, Integer> palette = new HashMap<>();
    int paletteColor = 0;
    
    public View3() {
    }

    public void start() {
        addMouseMotionListener(this);
        for (int i = START_IMAGE_INDEX; i <= END_IMAGE_INDEX; i++) {
            String frameNumber = "" + (i * SKIP_FRAMES); // 00" + i;
            // frameNumber = frameNumber.substring(frameNumber.length() - 2, frameNumber.length());
            try {
                images[i] = ImageIO.read(new File(IMG_PATH + "Frame " + frameNumber + " (30ms) (combine).png"));
                System.out.println("loading image " + i + " frame: " +  frameNumber);
            } catch (IOException ex) {
                System.err.println("Load frame image error ! index=" + i);
                System.exit(-1);
            }
        }
        createMixImage();
        saveMixImageData();
    }
    
    private void createMixImage() {
        
        int maxIndex = 1;
        Set<Integer> usedColors = new HashSet<>();
        for (int i = START_IMAGE_INDEX; i < LAST_FRAME + 1; i += SKIP_FRAMES) {
            
            if ((i / SKIP_FRAMES) > END_IMAGE_INDEX) {
                break;
            }
            
            int provMaxIndex = maxIndex;
            // update image
            for (int y = 0; y < 200; y++) {
                for (int x = 0; x < 320; x++) {
                    int color = images[i / SKIP_FRAMES].getRGB(x, y);
                    if (color == PAL_WHITE) {
                        int newIndex = mix[y][x] + maxIndex;
                        mix[y][x] = newIndex;
                        if (newIndex > provMaxIndex) {
                            provMaxIndex = newIndex;
                        }
                    }
                }
            }

            maxIndex = provMaxIndex + 1;
            
            int lastIndex = 0;
            usedColors.clear();
            for (int y = 0; y < 200; y++) {
                for (int x = 0; x < 320; x++) {
                    usedColors.add(mix[y][x]);
                    if (mix[y][x] > lastIndex) {
                        lastIndex = mix[y][x];
                    }
                }
            }

            System.out.println("adicionando image " + i + ", cores utilizadas: " + usedColors.size() + " last index: " + lastIndex);
        }
        
        // fix colors index

        usedColors.clear();
        for (int y = 0; y < 200; y++) {
            for (int x = 0; x < 320; x++) {
                if (x==0 && y==0) {
                    if (!usedColors.contains(mix[y][160])) {
                        usedColors.add(mix[y][160]);
                        palette.put(mix[y][160], paletteColor++);
                    }
                }
                else {
                    if (!usedColors.contains(mix[y][x])) {
                        usedColors.add(mix[y][x]);
                        palette.put(mix[y][x], paletteColor++);
                    }
                }
            }
        }
        
        int lastPaletteColor = paletteColor;
        lastPaletteColor = 127;
        System.out.println("lastPaletteColor: " + lastPaletteColor);
        
        // rewrite image with new palette
        for (int y = 0; y < 200; y++) {
            for (int x = 0; x < 320; x++) {
                mix[y][x] = palette.get(mix[y][x]);
            }
        }

        // write palette assembly code
        try {
            PrintWriter pw = new PrintWriter(OUT_ASM_PAL_FILE);

            //pw.println("palette_frame_size dw " + (lastPaletteColor + 1));
            //pw.println("palette_frames:");

            for (int i = START_IMAGE_INDEX; i < LAST_FRAME + 1; i += SKIP_FRAMES) {
                
                if ((i / SKIP_FRAMES) > END_IMAGE_INDEX) {
                    break;
                }
                
                usedColors.clear();
                pw.println("");
                
                if ((i + SKIP_FRAMES >= LAST_FRAME + 1)
                        || (((i + SKIP_FRAMES) / SKIP_FRAMES) > END_IMAGE_INDEX)) {
                    // pw.println("palette_last_frame:");
                }
                
                pw.println("palette_frame_" + (i / SKIP_FRAMES) + ":");
                for (int y = 0; y < 200; y++) {
                    for (int x = 0; x < 320; x++) {
                        int color = images[i / SKIP_FRAMES].getRGB(x, y);
                        if (color == PAL_WHITE) {
                            int usedIndex = mix[y][x];
                            usedColors.add(usedIndex);
                        }
                    }
                }
                String pageStr = "000" + Integer.toHexString(PAGE).toLowerCase();
                pageStr = pageStr.substring(pageStr.length() - 3, pageStr.length()) + "h";
                
                // generate assembly code palette
                for (int c = 0; c <= lastPaletteColor; c++) {
                //for (int c = 0; c < 256; c++) {
                        //pw.println("   db 0ffh, 0ffh, 0ffh ; " + c);
                    int a =  (PAGE % 2) == 1 ? 128 : 0;

                    if (usedColors.contains(c)) {
                        pw.println("   db " + pageStr + ", 0ffh, 0ffh, 0ffh ; " + (a + c));
                    }
                    else {
                        pw.println("   db " + pageStr + ", 000h, 000h, 000h ; " + (a + c));
                    }
                    
                    palette.put(c, (int) (Integer.MAX_VALUE * Math.random()));
                }
            }
            pw.close();
        }
        catch (Exception e) {
            System.err.println("Error generating asm pal file !");
            System.exit(-1);
        }
    }

    
    private void saveMixImageData() {
        OutputStream os = null;
        try {
            os = new FileOutputStream(OUT_DATA_FILE);
            for (int y = 0; y < 200; y++) { // <---- diminui o tamanho da imagem para caber em 64kb
                for (int x = 0; x < 320; x++) {
                    if ((PAGE % 2) == 1) {
                        os.write(mix[y][x] + 128);
                    }
                    else {
                        os.write(mix[y][x]);
                        //os.write(1); // <-------------
                    }
                }
            }
            os.close();
        } catch (IOException ex) {
            System.err.println("error save mix image data !");
            System.exit(-1);
        } finally {
            try {
                os.close();
            } catch (IOException ex) {
                System.err.println("error save mix image data !");
                System.exit(-1);
            }
        }

        
    }
    
    @Override
    protected void paintComponent(Graphics g) {
        super.paintComponent(g); 
        Graphics2D g2d = (Graphics2D) g;
        g2d.drawLine(0, 0, getWidth(), getHeight());
        g2d.scale(2, 2);
        
        for (int y = 0; y < 180; y++) { // <---- diminui o tamanho da imagem para caber em 64kb
            for (int x = 0; x < 320; x++) {
                int color = palette.get(mix[y][x]);
                g.setColor(new Color(color));
                g.drawLine(x, y, x, y);
            }
        }

        // g2d.drawImage(images[0], 0, 0, null);
            
        g.setColor(Color.BLACK);
        g.drawString("2 color index: " + selectedColorIndex, 30, 30);

    }
    
    public static void main(String[] args) {
        SwingUtilities.invokeLater(() -> {
            View3 view = new View3();
            view.start();
            view.setPreferredSize(new Dimension(700, 480));
            JFrame frame = new JFrame();
            frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
            frame.getContentPane().add(view);
            frame.pack();
            frame.setLocationRelativeTo(null);
            frame.setVisible(true);
        });
    }

    @Override
    public void mouseDragged(MouseEvent e) {
    }

    private int selectedColorIndex = 0;
    
    @Override
    public void mouseMoved(MouseEvent e) {
        try {
            selectedColorIndex = mix[e.getY() / 2][e.getX() / 2];
            // System.out.println("images[0] color index: " + images[0].getRGB(e.getX() / 2, e.getY() / 2));
            repaint();
        }
        catch (ArrayIndexOutOfBoundsException ex) {
            // ignore
        }
    }
    
}
