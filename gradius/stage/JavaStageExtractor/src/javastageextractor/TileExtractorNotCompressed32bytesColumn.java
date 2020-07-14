package javastageextractor;

import java.awt.Dimension;
import java.awt.Graphics;
import java.awt.Graphics2D;
import java.awt.image.BufferedImage;
import java.awt.image.DataBufferInt;
import java.io.File;
import java.nio.ByteBuffer;
import java.security.MessageDigest;
import java.util.HashMap;
import java.util.Map;
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
public class TileExtractorNotCompressed32bytesColumn extends JPanel  {

    private BufferedImage image;
    private BufferedImage outImage;

    public TileExtractorNotCompressed32bytesColumn() {
        try {
            //image = ImageIO.read(new File("D:/javaGradius/tmx/stage_1_shadow.png"));
            image = ImageIO.read(new File("D:/javaGradius/tmx/stage_1_shadow_with_stars.png"));
            
            outImage = new BufferedImage(328, 5 * 8, BufferedImage.TYPE_INT_RGB);
        }
        catch (Exception e) {
            e.printStackTrace();
            System.exit(-1);
        }
    }

    @Override
    protected void paintComponent(Graphics g) {
        super.paintComponent(g); //To change body of generated methods, choose Tools | Templates.
        Graphics2D g2d = (Graphics2D) g;
        g2d.scale(2, 2);
        
        Graphics og = outImage.getGraphics();
        
        int width = image.getWidth();
        int height = 168; //image.getHeight();
        
        //int[][] map = new int[height / 8][width / 8];
        int[][] map = new int[32][width / 8]; // --> usar 32 bytes row para poder obter a posição depois usando <<
        
        System.out.println(getMD5(image));
        Map<String, BufferedImage> tiles = new HashMap<>();
        Map<String, Integer> tileIds = new HashMap<>();
        
        int mapSize = 0;
        int x = 0;
        int y = 0;
        int lastTileId = 0;
        for (int row = 0; row < height / 8; row++) {
            for (int col = 0; col < width / 8; col++) {
                BufferedImage subimage = image.getSubimage(col * 8, row * 8, 8, 8);
                String md5 = getMD5(subimage);
                Integer tileId = tileIds.get(md5);
                if (tileId == null) {
                    tileId = lastTileId++;
                    tiles.put(md5, subimage);
                    tileIds.put(md5, tileId);
                    // System.out.println("col: " + col + " row: " + row);
                    g.drawImage(subimage, x, y, null);
                    og.drawImage(subimage, x, y, null);
                    x += 8;
                    if (x > 327) {
                        y += 8;
                        x = 0;
                    }
                }
                //System.out.print(tileId + ",");
                map[row][col] = tileId;
                mapSize++;
            }
            //System.out.println("");
        }

        // not compressed format
        
        for (int col = 0; col < map[0].length; col++) {
            String line = "";
            for (int row = 0; row < map.length; row++) {
                int c = map[row][col];
                line += c + ",";
            }
            line = line.substring(0, line.length() - 1);
            System.out.println("   db " + line + " ; column " + col);
        }
//        
//        int compressedSize = 0;
//        
//        int zeroCount = 0;
//        for (int col = 0; col < map[0].length; col++) {
//            String line = "";
//            for (int row = 0; row < map.length; row++) {
//                int c = map[row][col];
//                if (c == 0) {
//                    //zeroCount++;
//                    while (c == 0) {
//                        zeroCount++;
//                        row++;
//                        if (row >= map.length) {
//                            break;
//                        }
//                        c = map[row][col];
//                        if (c != 0) {
//                            row--;
//                        }
//                    }
//                    
//                    line += "0," + zeroCount + ",";
//                    compressedSize += 2;
//                    zeroCount = 0;
//                }
//                else {
//                    line += c + ",";
//                    compressedSize += 1;
//                }
//            }
//            line = line.substring(0, line.length() - 1);
//            System.out.println("   db " + line + " ; column " + col);
//        }
//        
//        System.out.println();
//        System.out.println("last tile id: " + lastTileId);
//        System.out.println("map size: " + mapSize);
//        System.out.println("compressed size: " + compressedSize);
        
        try {
            ImageIO.write(outImage, "png", new File("D:/javaGradius/tmx/stage_1_tileset_shadow.png"));
        }
        catch (Exception e) {
            e.printStackTrace();
            System.exit(-1);
        }
    }

    public static String getMD5(BufferedImage originalImage) {
        StringBuilder sb = new StringBuilder();
        try {
            //BufferedImage image = originalImage; // new BufferedImage(originalImage.getWidth(), originalImage.getHeight(), BufferedImage.TYPE_INT_RGB);
            BufferedImage image = new BufferedImage(originalImage.getWidth(), originalImage.getHeight(), BufferedImage.TYPE_INT_RGB);
            MessageDigest md5 = MessageDigest.getInstance("md5");

            image.getGraphics().drawImage(originalImage, 0, 0, null);
            int[] intImageData = ((DataBufferInt) image.getRaster().getDataBuffer()).getData();
            ByteBuffer b = ByteBuffer.allocate(4 * intImageData.length);
            b.position(0);
            for (int i = 0; i < intImageData.length; i++) {
                b.putInt(intImageData[i]);
            }
            byte[] imageData = b.array();
            //byte[] byteImageData = ((DataBufferByte) image.getData(rect).getDataBuffer()).getData();
            byte[] byteKey =  md5.digest(imageData);
            //convert the byte to hex format
            for (int i = 0; i < byteKey.length; i++) {
              sb.append(Integer.toString((byteKey[i] & 0xff) + 0x100, 16).substring(1));
            }
            // System.out.println("Digest(in hex format): " + sb.toString());
        }
        catch (Exception ex) {
            Logger.getLogger(TileExtractorNotCompressed32bytesColumn.class.getName()).log(Level.SEVERE, null, ex);
            System.exit(-1);
        }
        return sb.toString();
    }

    public static void main(String[] args) throws Exception {
        SwingUtilities.invokeLater(new Runnable() {
            @Override
            public void run() {
                TileExtractorNotCompressed32bytesColumn view = new TileExtractorNotCompressed32bytesColumn();
                view.setPreferredSize(new Dimension(800, 600));
                JFrame frame = new JFrame();
                frame.setTitle("Java Gradius Tile extractor");
                frame.getContentPane().add(view);
                frame.setResizable(false);
                frame.pack();
                frame.setLocationRelativeTo(null);
                frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
                frame.setVisible(true);
                view.requestFocus();
            }
        });
    }
        
}
