

import java.awt.Color;
import java.awt.Graphics;
import java.awt.Graphics2D;
import java.awt.Point;
import java.awt.RenderingHints;
import java.awt.event.KeyEvent;
import java.awt.event.KeyListener;
import java.awt.event.MouseEvent;
import java.awt.event.MouseListener;
import java.awt.image.BufferedImage;
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
public class View extends JPanel implements MouseListener, KeyListener {
    
    private BufferedImage image;
    
    private BufferedImage frame;
    
    
    public View() {
        try {
            image = ImageIO.read(View.class.getResourceAsStream("sprite.png"));
            frame = new BufferedImage(image.getWidth(), image.getHeight(), BufferedImage.TYPE_INT_RGB);
        }
        catch (Exception e) {
            e.printStackTrace();
            System.exit(-1);
        }
        
        addMouseListener(this);
        addKeyListener(this);
        
        new Timer().scheduleAtFixedRate(new TimerTask() {
            @Override
            public void run() {
                update();
                repaint();
            }
        }, 100, 1000 / 60);
    }
    
    @Override
    protected void paintComponent(Graphics g) {
        super.paintComponent(g);
        Graphics2D g2d = (Graphics2D) g;
        draw((Graphics2D) frame.getGraphics());
        g2d.scale(10, 10);
        g2d.drawImage(frame, 0, 0, null);
    }
    
    public void update() {
    }
    
    public void draw(Graphics2D g) {
        Color mark1 = new Color(0, 0, 0, 128);
        Color mark2 = new Color(255, 255, 255, 128);
        int background = image.getRGB(0, 0);
        g.drawImage(image, 0, 0, null);
        int size = 4;
        for (int y = 0; y < frame.getHeight(); y++) {
            for (int x = 0; x < frame.getWidth(); x += size) {
                int count = 0;
                for (int i = 0; i < size; i++) {
                    if (frame.getRGB(x + i, y) != background) {
                        count++;
                    }
                }
                //if (count > 0 && count < 3) {
                //    g.setColor(mark2);
                //    g.drawLine(x, y, x + 3, y);
                //}
                if (count > 0) {
                    g.setColor(mark1);
                    g.drawLine(x, y, x + size - 1, y);
                }
                else {
                    System.out.println("count zero");
                }
            }
        }
    }
    
    public static void main(String[] args) {
        SwingUtilities.invokeLater(new Runnable() {
            @Override
            public void run() {
                View view = new View();
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
