

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
 * 2.5D Plasma Effect.
 * 
 * @author Leonardo Ono (ono.leo@gmail.com);
 */
public class View extends JPanel implements MouseMotionListener, KeyListener {
    
    private final Point mouse = new Point();
    private final Point cannonPosition = new Point(164, 192);
    
    private final int[][] cannonAnimationIndex = new int[25][128];
    
    public View() {
    }
    
    public void start() {
        addMouseMotionListener(this);
        addKeyListener(this);
        precalculateCannonAnimationIndex();
    }
    
    private void precalculateCannonAnimationIndex() {
        for (int y = 0; y < 25; y += 1) {
            for (int x = 0; x < 128; x += 1) {
                int animationIndex = calculateIndex(x, y, 64, 24);
                cannonAnimationIndex[y][x] = animationIndex;
            }
        }        
    }
    
    @Override
    protected void paintComponent(Graphics g) {
        super.paintComponent(g);
        draw((Graphics2D) g);
    }
    
    private Color[] colors = { Color.RED, Color.GREEN, Color.BLUE, Color.ORANGE, Color.CYAN, Color.MAGENTA };
    
    private void draw(Graphics2D g) {
        g.translate(0, 20);
        g.scale(2, 2);
        g.clearRect(0, 0, getWidth(), getHeight());
        int cannonCol = cannonPosition.x / 8;
        int cannonRow = cannonPosition.y / 8;
        int mouseRow = mouse.y / 8;
        int mouseCol = mouse.x / 8;
        for (int y = 0; y < 25; y += 1) {
            for (int x = 0; x < 41; x += 1) {
                int colorIndex = cannonAnimationIndex[24 - (cannonRow - y)][64 - (cannonCol - x)];
                g.setColor(colors[colorIndex]);
                g.drawString("" + colorIndex, x * 8, y * 8 + 8);
                g.setColor(Color.BLACK);
                g.drawRect(x * 8, y * 8, 8, 8);
                if (x == mouseCol && y == mouseRow) {
                    g.fillRect(x * 8, y * 8, 8, 8);
                    g.setColor(Color.WHITE);
                    colorIndex = cannonAnimationIndex[24 - (cannonRow - mouseRow)][64 - (cannonCol - mouseCol)];
                    g.drawString("" + colorIndex, x * 8, y * 8 + 8);
                }
            }
        }
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
                View view = new View();
                view.setPreferredSize(new Dimension(700, 500));
                JFrame frame = new JFrame();
                frame.setTitle("Cannon");
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
            cannonPosition.x -= 8;
        }
        else if (e.getKeyCode() == KeyEvent.VK_RIGHT) {
            cannonPosition.x += 8;
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
        for (int y = 0; y < 25; y += 1) {
            String line = "   db ";
            for (int x = 0; x < 128; x += 1) {
                int animationIndex = cannonAnimationIndex[y][x];
                line += animationIndex + ",";
            }
            line = line.substring(0, line.length() - 1);
            System.out.println(line);
        }          
    }
    
}
