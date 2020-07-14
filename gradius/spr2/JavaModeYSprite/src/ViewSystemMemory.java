

import java.awt.Graphics;
import java.awt.Graphics2D;
import java.awt.event.KeyEvent;
import java.awt.event.KeyListener;
import java.awt.event.MouseEvent;
import java.awt.event.MouseListener;
import java.awt.image.BufferedImage;
import java.awt.image.DataBufferByte;
import java.util.ArrayList;
import java.util.List;
import java.util.Timer;
import java.util.TimerTask;
import javax.imageio.ImageIO;
import javax.swing.JFrame;
import javax.swing.JPanel;
import javax.swing.SwingUtilities;

/**
 *
 * @author leonardo
 */
public class ViewSystemMemory extends JPanel implements MouseListener, KeyListener {
    
    private BufferedImage image;
    private byte[] data;
    
    private BufferedImage frame;
    
    public ViewSystemMemory() {
        try {
            image = ImageIO.read(View.class.getResourceAsStream("sprite.bmp"));
            data = ((DataBufferByte) image.getRaster().getDataBuffer()).getData();
            frame = new BufferedImage(image.getWidth(), image.getHeight(), BufferedImage.TYPE_INT_RGB);
        }
        catch (Exception e) {
            e.printStackTrace();
            System.exit(-1);
        }
        
        addMouseListener(this);
        addKeyListener(this);
        
        /*
        new Timer().scheduleAtFixedRate(new TimerTask() {
            @Override
            public void run() {
                update();
                repaint();
            }
        }, 100, 1000 / 60);
*/
    }
    
    private int getImagePixel(int x, int y) {
        int color = data[x + y * image.getWidth()] & 0xff;
        return color;
    }
    
    @Override
    protected void paintComponent(Graphics g) {
        super.paintComponent(g);
        Graphics2D g2d = (Graphics2D) g;
        draw((Graphics2D) frame.getGraphics());
        g2d.scale(10, 10);
        g2d.drawImage(image, 0, 0, null);
        g2d.drawImage(frame, 17, 0, null);
    }
    
    public void update() {
    }
    
    public void draw(Graphics2D g) {
        
        // 16x16 start,length,data0,data1,...,datan (2 bits)
        
        //int currentColor = image.getRGB(0, 0);
        //int count = 1;
        //for (int y = 0; y < frame.getHeight(); y++) {
        //    for (int x = 0; x < frame.getWidth(); x++) {
        //        if (currentColor != image.getRGB(x, y)) {
        //            currentColor = image.getRGB(x, y);
        //            count++;
        //        }
        //    }
        //}
        //System.out.println("size in bytes: " + count);

        // 0, space size, n (copy size cx), d0, d1, ..., dn, 0, space size 
        
        //for (int start = 0; start < 4; start++) {
        int virtualScreenWidth = 328;
        
            List<Integer> spriteCode = new ArrayList<>();
            int start = 0;
            for (int y = 0; y < frame.getHeight(); y++) {
                for (int x = start; x < frame.getWidth(); x += 4) {
                    frame.setRGB(4 * start + x / 4, y, image.getRGB(x, y));
                    System.out.print(getImagePixel(x, y) + ",");
                    spriteCode.add(getImagePixel(x, y));
                }
                for (int i = 0; i < (virtualScreenWidth / 4 - 4); i++) {
                    //System.out.print("36" + ",");
                    spriteCode.add(36);
                }
            }
            
            String code = "";
            boolean isTransp = false;
            
            List<Integer> nonTranspBytes = new ArrayList<>();
            
            if (spriteCode.get(0) == 36) {
                code += "0,";
                isTransp = true;
            }
            else {
                code += "1,";
                isTransp = false;
            }
            
            int count = 0;
            for (int i = 0; i < spriteCode.size(); i++) {
                int pixel = spriteCode.get(i);
                
                if (isTransp) {
                    if (pixel == 36) {
                        count++;
                    }
                    
                    if (pixel != 36 || i == spriteCode.size() - 1) {
                        code += count + ",";

                        if (pixel != 36) {
                            nonTranspBytes.clear();
                            nonTranspBytes.add(pixel);
                            count = 1;
                            isTransp = false;
                        }
                        
                        if (pixel != 36 && i == spriteCode.size() - 1) {
                            code += count + ",";
                            for (int b : nonTranspBytes) {
                                code += b + ",";
                            }
                        }
                        
                        continue;
                    }
                }

                if (!isTransp) {
                    if (pixel != 36) {
                        nonTranspBytes.add(pixel);
                        count++;
                    }
                    
                    if (pixel == 36 || i == spriteCode.size() - 1) {
                        code += count + ",";
                        for (int b : nonTranspBytes) {
                            code += b + ",";
                        }
                        
                        if (pixel == 36) {
                            count = 1;
                            isTransp = true;
                        }
                        
                        if (pixel == 36 && i == spriteCode.size() - 1) {
                            code += count + ","; // last transparent 
                        }
                        continue;
                    }
                }
            }
            
            code += "0"; // end of sprite encoding
            
            System.out.print("code: " + code);
        //}
        //System.exit(0);
    }
    
    public static void main(String[] args) {
        SwingUtilities.invokeLater(new Runnable() {
            @Override
            public void run() {
                ViewSystemMemory view = new ViewSystemMemory();
                JFrame frame = new JFrame();
                frame.setTitle("");
                frame.getContentPane().add(view);
                frame.setSize(934, 662);
                frame.setLocationRelativeTo(null);
                frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
                frame.setResizable(false);
                frame.setVisible(true);
                view.requestFocus();
            }
        });
    }    

    @Override
    public void mouseClicked(MouseEvent e) {
        //path2.add(new Point(e.getX(), e.getY()));
        //System.out.println("path2.add(new Point(" + e.getX() + ", " + e.getY() + "));");
    }

    @Override
    public void mousePressed(MouseEvent e) {
    }

    @Override
    public void mouseReleased(MouseEvent e) {
    }

    @Override
    public void mouseEntered(MouseEvent e) {
    }

    @Override
    public void mouseExited(MouseEvent e) {
    }

    @Override
    public void keyTyped(KeyEvent e) {
    }

    @Override
    public void keyPressed(KeyEvent e) {
        if (e.getKeyCode() == KeyEvent.VK_0) {
        }
        if (e.getKeyCode() == KeyEvent.VK_1) {
        }
        if (e.getKeyCode() == KeyEvent.VK_R) {
        }
    }

    @Override
    public void keyReleased(KeyEvent e) {
    }
    
}
