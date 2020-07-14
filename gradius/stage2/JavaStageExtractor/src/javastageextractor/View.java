package javastageextractor;

import java.awt.Canvas;
import java.awt.Color;
import java.awt.Dimension;
import java.awt.Graphics2D;
import java.awt.event.KeyEvent;
import java.awt.event.KeyListener;
import java.awt.event.MouseEvent;
import java.awt.event.MouseListener;
import java.awt.image.BufferStrategy;
import java.awt.image.BufferedImage;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.Map.Entry;
import java.util.Properties;
import java.util.logging.Level;
import java.util.logging.Logger;
import javax.imageio.ImageIO;
import javax.swing.JFrame;
import javax.swing.JOptionPane;
import javax.swing.SwingUtilities;

/**
 * 2.5D Plasma Effect.
 * 
 * @author Leonardo Ono (ono.leo@gmail.com);
 */
public class View extends Canvas implements KeyListener, MouseListener {
    
    private static final int SCREEN_WIDTH = 640, SCREEN_HEIGHT = 400;
    private final BufferedImage offscreen;
    private BufferStrategy bs;
    private boolean running;
    
    private PrintWriter pw;
    private String outPropfile = "D:/javaGradius/video/enemies_1.txt";
    private String outGenFile = "D:/javaGradius/video/stage_generated.txt";
    
    String path = "D:/javaGradius/video/video/";
    int startFrame = 142;
    int endFrame = 3209;
    int currentFrame = startFrame;
    
    // 0~127=red 128~255=blue
    int powerUpId = 0;
    
    Properties p = new Properties();
    
    String enemyId = "fans";
    String enemyIdCopy = "";
    
    int fx = 0;
    int fy = 0;
    
    public View() {
        offscreen = new BufferedImage(320, 200, BufferedImage.TYPE_INT_RGB);
    }
    
    public void start() {
        addKeyListener(this);
        addMouseListener(this);

        try {
            p.load(new FileReader(outPropfile));
        } catch (Exception ex) {
            Logger.getLogger(View.class.getName()).log(Level.SEVERE, null, ex);
            System.exit(-1);
        }
        
        createBufferStrategy(2);
        bs = getBufferStrategy();
        running = true;
        new Thread(new Runnable() {
            @Override
            public void run() {
                while (running) {
                    update();
                    Graphics2D g = (Graphics2D) bs.getDrawGraphics();
                    draw(offscreen.createGraphics());
                    g.drawImage(offscreen, 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, 
                        0, 0, 320, 200, null);
                    
                    g.dispose();
                    bs.show();

                    try {
                        Thread.sleep(1000 / 60);
                    } catch (InterruptedException ex) {
                    }
                }
            }
        }).start();
    }

    private void update() {
    }
    
    private void draw(Graphics2D g) {
        String index = "00000" + currentFrame;
        index = index.substring(index.length() - 5, index.length());
        String filename = "videoplayback " + index + ".jpg";
        try {
            BufferedImage image = ImageIO.read(new File(path + filename));
            g.drawImage(image, 0, 0, 320, 200, null);
            g.drawString("x: " + (currentFrame - startFrame), 10, 10);
            g.drawString("enemyId: " + enemyId, 10, 20);
            g.drawString("powerUpId: " + powerUpId, 10, 30);
        } catch (IOException ex) {
            Logger.getLogger(View.class.getName()).log(Level.SEVERE, null, ex);
            System.exit(-1);
        }
        
        for (Entry entry : p.entrySet()) {
            String k = (String) entry.getKey();
            String[] v = ((String) entry.getValue()).split(",");
            int kx = Integer.parseInt(k.replace("x", ""));
            if (kx != (currentFrame - startFrame)) {
                continue;
            }
            int ky = Integer.parseInt(v[0]);
            
            fx = kx;
            fy = ky;
            
            kx = kx - (currentFrame - startFrame) + 290;
            String kname = v[1];
            enemyIdCopy = kname;
            
            int kpowerUpId = 0;
            try {
                kpowerUpId = Integer.parseInt(v[2]);
            }
            catch (Exception e) { }
            //powerUpId = kpowerUpId;
            
            g.setColor(Color.WHITE);
            g.drawRect(kx - 4, ky - 4, 8, 8);
            g.drawString(kname, kx - 50, ky - 8);
            g.setColor(Color.RED);
            g.drawString(kpowerUpId + "", kx-10, ky+16);
        }
    }
    
    public static void main(String[] args) {
        SwingUtilities.invokeLater(new Runnable() {
            @Override
            public void run() {
                View view = new View();
                view.setPreferredSize(new Dimension(SCREEN_WIDTH, SCREEN_HEIGHT));
                JFrame frame = new JFrame();
                frame.setTitle("Java Gradius Stage Enemies Spawn Analyzer");
                frame.getContentPane().add(view);
                frame.setResizable(false);
                frame.pack();
                frame.setLocationRelativeTo(null);
                frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
                frame.setVisible(true);
                view.requestFocus();
                view.start();
            }
        });
    }

    @Override
    public void keyTyped(KeyEvent e) {
    }

    @Override
    public void keyPressed(KeyEvent e) {
        if (e.getKeyCode() == KeyEvent.VK_LEFT) {
            currentFrame--;
            if (currentFrame < startFrame) {
                currentFrame = startFrame;
            }
        }
        else if (e.getKeyCode() == KeyEvent.VK_RIGHT) {
            currentFrame++;
            if (currentFrame > endFrame) {
                currentFrame = endFrame;
            }
        }
        
        // get free red powerup id
        if (e.getKeyCode() == KeyEvent.VK_DELETE) {
            int posX = (currentFrame - startFrame);
            p.remove("x" + posX);
        }
        
        // get free red powerup id
        if (e.getKeyCode() == KeyEvent.VK_1) {
            int lastPowerUpId = 0;
            for (Entry entry : p.entrySet()) {
                String[] v = ((String) entry.getValue()).split(",");
                int kpowerUpId = 0;
                try {
                    kpowerUpId = Integer.parseInt(v[2]);
                }
                catch (Exception ex) { }
                if (kpowerUpId > lastPowerUpId && kpowerUpId < 128) {
                    lastPowerUpId = kpowerUpId;
                }
            }
            powerUpId = lastPowerUpId + 1;
        }

        // get free blue powerup id
        if (e.getKeyCode() == KeyEvent.VK_2) {
            int lastPowerUpId = 127;
            for (Entry entry : p.entrySet()) {
                String[] v = ((String) entry.getValue()).split(",");
                int kpowerUpId = 0;
                try {
                    kpowerUpId = Integer.parseInt(v[2]);
                }
                catch (Exception ex) { }
                if (kpowerUpId > lastPowerUpId && kpowerUpId >= 128) {
                    lastPowerUpId = kpowerUpId;
                }
            }
            powerUpId = lastPowerUpId + 1;
        }
        
        
        if (e.getKeyCode() == KeyEvent.VK_P) {
            try {
                powerUpId = Integer.parseInt(JOptionPane.showInputDialog("power up id (0~127=red 128~255=blue)"));
            }
            catch (Exception ex) {
                powerUpId = 0;
            }
        }

        if (e.getKeyCode() == KeyEvent.VK_I) {
            enemyId = JOptionPane.showInputDialog("enemy id");
            enemyId = enemyId.toLowerCase();
        }
        
        if (e.getKeyCode() == KeyEvent.VK_U) {
            enemyId = enemyIdCopy;
            enemyId = enemyId.toLowerCase();
        }

        if (e.getKeyCode() == KeyEvent.VK_R) {
            registerEnemy(fx * 2, fy * 2);
        }

        if (e.getKeyCode() == KeyEvent.VK_S) {
            try {
                PrintWriter ppw = new PrintWriter(outPropfile);
                p.store(ppw, "");
                ppw.close();
            } catch (Exception ex) {
                Logger.getLogger(View.class.getName()).log(Level.SEVERE, null, ex);
            }
            System.out.println("Property file '" + outPropfile + "' saved !");
        }
    }

    @Override
    public void keyReleased(KeyEvent e) {
    }

    @Override
    public void mouseClicked(MouseEvent e) {
        registerEnemy(e.getX(), e.getY());
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
    
    void registerEnemy(int x, int y) {
        // int posX = x + (currentFrame - startFrame);
        int posX = (currentFrame - startFrame);
        int posY = y / 2;
        p.put("x" + posX, posY + "," + enemyId + "," + powerUpId);
        System.out.println("registering enemy x" + posX + "=" + (posY + "," + enemyId + "," + powerUpId));
    }
    
    void generate() {
        try {
            pw = new PrintWriter(outGenFile);
        } catch (FileNotFoundException ex) {
            Logger.getLogger(View.class.getName()).log(Level.SEVERE, null, ex);
            System.exit(-1);
        }        
    }

}
