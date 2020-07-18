

import java.awt.Color;
import java.awt.Dimension;
import java.awt.Graphics;
import java.awt.Graphics2D;
import java.awt.Point;
import java.awt.event.KeyEvent;
import java.awt.event.KeyListener;
import java.awt.event.MouseEvent;
import java.awt.event.MouseMotionListener;
import javax.swing.JFrame;
import javax.swing.JPanel;
import javax.swing.SwingUtilities;

/**
 * 
 * @author Leonardo Ono (ono.leo@gmail.com);
 */
public class View16x16 extends JPanel implements MouseMotionListener, KeyListener {
    
    private final Point mouse = new Point();
    private final Point cannonPosition = new Point(164, 192);
    
    private final int[][] cannonAnimationIndex = new int[13][64];
    
    // fixed point math signed 8 bits
    private final int[][] bulletDirectionDX = new int[13][64];
    private final int[][] bulletDirectionDY = new int[13][64];
    
    public View16x16() {
    }
    
    public void start() {
        addMouseMotionListener(this);
        addKeyListener(this);
        precalculateCannonAnimationIndex();
    }
    
    private void precalculateCannonAnimationIndex() {
        for (int y = 0; y < 13; y += 1) {
            for (int x = 0; x < 64; x += 1) {
                int animationIndex = calculateIndex(x, y, 32, 12);
                cannonAnimationIndex[y][x] = animationIndex;
                bulletDirectionDX[y][x] = calculateDX(x, y, 32, 12);
                bulletDirectionDY[y][x] = calculateDY(x, y, 32, 12);
            }
        }        
    }
    

    private int calculateDX(int targetX, int targetY, int cannonX, int cannonY) {
        double vx = targetX - cannonX;
        double vy = targetY - cannonY - 0.001;
        double length = Math.sqrt(vx * vx + vy * vy);
        double dx = vx / length;
        int dxInt = ((byte) (int) (dx * 64)) & 0xff;
        return dxInt;
    }

        private int calculateDY(int targetX, int targetY, int cannonX, int cannonY) {
        double vx = targetX - cannonX;
        double vy = targetY - cannonY - 0.001;
        double length = Math.sqrt(vx * vx + vy * vy);
        double dy = vy / length;
        int dyInt = ((byte) (int) (dy * 64)) & 0xff;
        return dyInt;
    }

    @Override
    protected void paintComponent(Graphics g) {
        super.paintComponent(g);
        draw((Graphics2D) g);
    }
    
    private Color[] colors = { Color.RED, Color.GREEN, Color.BLUE, Color.ORANGE, Color.CYAN, Color.MAGENTA };
    
    private void draw(Graphics2D g) {
        g.scale(2, 2);
        
        g.setBackground(Color.DARK_GRAY);
        g.clearRect(0, 0, getWidth(), getHeight());
        g.setBackground(Color.WHITE);
        g.clearRect(0, 0, 320, 200);
        
        int cannonCol = cannonPosition.x / 16;
        int cannonRow = cannonPosition.y / 16;
        int mouseRow = mouse.y / 16;
        int mouseCol = mouse.x / 16;
        
        int bulletDX = bulletDirectionDX[12 - (cannonRow - mouseRow)][32 - (cannonCol - mouseCol)];
        int bulletDY = bulletDirectionDY[12 - (cannonRow - mouseRow)][32 - (cannonCol - mouseCol)];
        
        System.out.println("dx:" + bulletDX + " dy:" + bulletDY);
        
        int bulletX = cannonPosition.x * 64;
        int bulletY = cannonPosition.y * 64;
        for (int i = 0; i < 100; i++) {
            
            int bx = bulletX >> 6;
            int by = bulletY >> 6;
            g.setColor(Color.BLACK);
            g.fillOval(bx - 1, by - 1, 2, 2);
            
            bulletX += 4 * (byte) bulletDX;
            bulletY += 4 * (byte) bulletDY;
        }

        //System.out.println("bulletDX=" + bulletDX + " bulletDY=" + bulletDY);
        
        g.setColor(Color.BLUE);
        g.drawRect(mouse.x - 8, mouse.y - 8, 16, 16);
        g.setColor(Color.RED);
        g.drawRect(cannonPosition.x - 8, cannonPosition.y - 8, 16, 16);
    }
    
    private int calculateIndex(int targetX, int targetY, int cannonX, int cannonY) {
        double vx = targetX - cannonX;
        double vy = targetY - cannonY - 0.001;
        double angle = Math.atan2(vy, vx);
        //System.out.println("angle: " + Math.toDegrees(Math.PI + angle));
        return (int) (Math.toDegrees(Math.PI + angle) / 30);
    }
    
    public static void main(String[] args) {
        SwingUtilities.invokeLater(new Runnable() {
            @Override
            public void run() {
                View16x16 view = new View16x16();
                view.setPreferredSize(new Dimension(700, 500));
                JFrame frame = new JFrame();
                frame.setTitle("Enemy Bullet 16x16 lookup table for cannon-ship direction vector ");
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
    public void mouseDragged(MouseEvent e) {
    }

    @Override
    public void mouseMoved(MouseEvent e) {
        mouse.setLocation(e.getX() / 2, e.getY() / 2);
        repaint();
    }

    @Override
    public void keyTyped(KeyEvent e) {
    }

    @Override
    public void keyPressed(KeyEvent e) {
        if (e.getKeyCode() == KeyEvent.VK_LEFT) {
            cannonPosition.x -= 16;
        }
        else if (e.getKeyCode() == KeyEvent.VK_RIGHT) {
            cannonPosition.x += 16;
        }

        if (e.getKeyCode() == KeyEvent.VK_A) {
            printAsmTable();
        }

        repaint();
    }

    @Override
    public void keyReleased(KeyEvent e) {
    }

    private void printAsmTable() {
        for (int y = 0; y < 13; y += 1) {
            String line = "   db ";
            for (int x = 0; x < 64; x += 1) {
                int dx = bulletDirectionDX[y][x];
                int dy = bulletDirectionDY[y][x];
                //line += dx + ",";
                line += dy + ",";
            }
            line = line.substring(0, line.length() - 1);
            System.out.println(line);
        }          
    }
    
}
