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
 *
 * @author admin
 */
public class View extends JPanel implements MouseMotionListener {
    private static final int LAST_FRAME = 14; // 0~n
    private static final String IMG_PATH = "D:/vga/palette_anim/frames2/";
    private static final String OUT_DATA_FILE = "D:/vga/palette_anim/anim.dat";
    private static final String OUT_ASM_PAL_FILE = "D:/vga/palette_anim/pal_frames.asm";
    private BufferedImage[] images = new BufferedImage[LAST_FRAME + 1];
    
    private static final int PAL_BLACK = -16777216;
    private static final int PAL_WHITE = -1;
    
    private int[][] mix = new int[200][320];
    
    Map<Integer, Integer> palette = new HashMap<>();
    int paletteColor = 0;
    
    public View() {
    }

    public void start() {
        addMouseMotionListener(this);
        for (int i = 0; i < images.length; i++) {
            String frameNumber = "00" + i;
            frameNumber = frameNumber.substring(frameNumber.length() - 2, frameNumber.length());
            try {
                images[i] = ImageIO.read(new File(IMG_PATH + "frame_" + frameNumber + ".png"));
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
        for (int i = 0; i < LAST_FRAME + 1; i++) {
            int provMaxIndex = maxIndex;
            // update image
            for (int y = 0; y < 200; y++) {
                for (int x = 0; x < 320; x++) {
                    int color = images[i].getRGB(x, y);
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
                if (!usedColors.contains(mix[y][x])) {
                    usedColors.add(mix[y][x]);
                    palette.put(mix[y][x], paletteColor++);
                }
            }
        }
        
        int lastPaletteColor = paletteColor;
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

            pw.println("palette_frame_size dw " + lastPaletteColor);
            pw.println("palette_frames:");

            for (int i = 0; i < LAST_FRAME + 1; i++) {
                usedColors.clear();
                pw.println("");
                
                if (i == LAST_FRAME) {
                    pw.println("palette_last_frame:");
                }
                
                pw.println("palette_frame_" + i + ":");
                for (int y = 0; y < 200; y++) {
                    for (int x = 0; x < 320; x++) {
                        int color = images[i].getRGB(x, y);
                        if (color == PAL_WHITE) {
                            int usedIndex = mix[y][x];
                            usedColors.add(usedIndex);
                        }
                    }
                }

                // generate assembly code palette
                for (int c = 0; c < lastPaletteColor; c++) {
                        //pw.println("   db 0ffh, 0ffh, 0ffh ; " + c);
                    if (usedColors.contains(c)) {
                        pw.println("   db 0ffh, 0ffh, 0ffh ; " + c);
                    }
                    else {
                        pw.println("   db 000h, 000h, 000h ; " + c);
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
            for (int y = 0; y < 180; y++) { // <---- diminui o tamanho da imagem para caber em 64kb
                for (int x = 0; x < 320; x++) {
                    os.write(mix[y][x]);
                    //os.write(1); // <-------------
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
        //g2d.drawImage(images[0], 0, 0, null);
        
        for (int y = 0; y < 180; y++) { // <---- diminui o tamanho da imagem para caber em 64kb
            for (int x = 0; x < 320; x++) {
                int color = palette.get(mix[y][x]);
                g.setColor(new Color(color));
                g.drawLine(x, y, x, y);
            }
        }
            
        g.setColor(Color.BLACK);
        g.drawString("color index: " + selectedColorIndex, 30, 30);

    }
    
    public static void main(String[] args) {
        SwingUtilities.invokeLater(() -> {
            View view = new View();
            view.start();
            view.setPreferredSize(new Dimension(800, 600));
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
            System.out.println("color index: " + selectedColorIndex);
            repaint();
        }
        catch (ArrayIndexOutOfBoundsException ex) {
            // ignore
        }
    }
    
}
