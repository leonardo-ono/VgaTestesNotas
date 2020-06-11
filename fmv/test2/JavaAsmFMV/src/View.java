import java.awt.Color;
import java.awt.Dimension;
import java.awt.Graphics;
import java.awt.Graphics2D;
import java.awt.event.MouseEvent;
import java.awt.event.MouseMotionListener;
import java.awt.image.BufferedImage;
import java.io.File;
import java.io.IOException;
import java.util.logging.Level;
import java.util.logging.Logger;
import javax.imageio.ImageIO;
import javax.swing.JFrame;
import javax.swing.JPanel;
import javax.swing.SwingUtilities;

/**
 *
 * @author admin
 */
public class View extends JPanel implements MouseMotionListener {
    int startFrame = 1;
    int endFrame = 500;
    int currentframe = 1;
    
    String imagePath = "D:/vga/fmv/test2/anim/";
            
    private BufferedImage image = new BufferedImage(320, 200, BufferedImage.TYPE_INT_RGB);
    private BufferedImage image2 = new BufferedImage(320 / 4, 200 / 2, BufferedImage.TYPE_INT_RGB);
    private static final int PAL_BLACK = -16777216;
    private static final int PAL_WHITE = -1;
    
    public View() {
    }

    public void start() {
        addMouseMotionListener(this);
        draw((Graphics2D) image.getGraphics());
    }

    int totalLength = 0;
    int frame = 0;
    
    private void encodeImage() {
        System.out.print("    data_frame_" + ++frame + " dw ");        
        
        int length = 0;
        int currentPixel = image2.getRGB(0, 0);
        int count = 0;
        for (int y = 0; y < 100; y++) {
            for (int x = 0; x < 80; x++) {
                if (image2.getRGB(x, y) == currentPixel) {
                    count++;
                }
                
                if ((image2.getRGB(x, y) != currentPixel) || (y == 99 && x == 79)) {
                    System.out.print(count + ",");
                    count = 1;
                    currentPixel = image2.getRGB(x, y);
                    length++;
                }
            }
        }
        System.out.println("0");
        totalLength += length;
        
        //System.out.println("\nframe: " + ++frame);        
        //System.out.println("length: " + length);        
        //System.out.println("total length: " + totalLength);        
        //System.out.println("-----------------------------");        
    }
    
    @Override
    protected void paintComponent(Graphics g) {
        super.paintComponent(g); 

        draw((Graphics2D) image.getGraphics());
        encodeImage();
        
        Graphics2D g2d = (Graphics2D) g;
        //g2d.scale(0.25, 0.5);
        g2d.scale(4, 2);
        g2d.drawImage(image2, 0, 0, null);
        
        try {
            Thread.sleep(1000 / 15);
        } catch (InterruptedException ex) {
        }
        
        currentframe += 4;
        if (currentframe > endFrame) {
            System.exit(0);
        }
        
        repaint();
    }
    
    private void draw(Graphics2D g) {
        String imageFile = "0000" + currentframe;
        imageFile = imageFile.substring(imageFile.length() - 4, imageFile.length());
        imageFile += ".jpg";
        BufferedImage image = null;
        try {
            image = ImageIO.read(new File(imagePath + imageFile));
        } catch (IOException ex) {
            System.err.println("Could not load image file " + imageFile + " !");
            System.exit(-1);
        }
        
        Graphics i2g = image2.getGraphics();
        i2g.drawImage(image, 0, 0, 80, 100, this);
        i2g.setColor(Color.BLACK);
        i2g.fillOval(-1, -1, 2, 2);
        
        // convert to b&w
        for (int y = 0; y < 100; y++) {
            for (int x = 0; x < 80; x++) {
                if (image2.getRGB(x, y) == PAL_BLACK) {
                    image2.setRGB(x, y, PAL_BLACK);
                }
                else {
                    image2.setRGB(x, y, PAL_WHITE);
                }
            }
        }        
        
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

    @Override
    public void mouseMoved(MouseEvent e) {
    }
    
}
