package net.emiliollbb.durango;

import java.awt.image.BufferedImage;
import java.io.File;
import java.util.List;

import javax.imageio.ImageIO;

public class ImageGenerator {

	public static void generateTiles(List<Tile> tiles, final List<String> files) throws Exception {
		for(String s : files) {
			final File file = new File(s);
			final BufferedImage image = ImageIO.read(file);
			
			for(int row=0; row < 16; row++) {
				for(int col=0; col<16; col++) {
					Tile t = new Tile(image, row, col);
					if(!tiles.contains(t)) {
						tiles.add(t);
					}
				}
			}
		}				
	}
	
	public static int findTile(List<Tile> tiles, Tile tile) {
		int i=0;
		for(Tile t : tiles) {
			if(t.equals(tile)) {
				return i;
			}
			i++;
		}
		return -1;
	}
	
	public static byte[] convertToDurango(String s) throws Exception {
		final File file = new File(s);
		final BufferedImage image = ImageIO.read(file);
		byte pixels[] = new byte[8192];
		int i=0;
		
		for(int row=0; row < image.getHeight(); row++) {
			for(int col=0; col<image.getWidth(); col+=2) {
				pixels[i++]=Palette.getColorByte(image.getRGB(col, row), image.getRGB(col+1, row));				
			}			
		}
		return pixels;				
	}
	
	public static String getHexString(byte[] pixels) {
		StringBuilder sb = new StringBuilder(500);		
		for(int i=0; i<pixels.length; i++) {
			if(i%32==0) {
				sb.append(".byt ");
			}
			sb.append(String.format("$%02X",pixels[i])).append(',');
			if(i%32==31) {
				sb.append("\n");
			}
		}		
		return sb.toString();
	}
	
		
	public static void main(final String args[]) throws Exception {
		byte[] pixels = convertToDurango("/tmp/pong.png");
		byte [] encoded = new RLEEncoder().encode(2, pixels);
		System.out.println("----- IMAGE ------");
		System.out.println(getHexString(encoded));
		System.out.println("\n----- ----- ------");				
	}
}
