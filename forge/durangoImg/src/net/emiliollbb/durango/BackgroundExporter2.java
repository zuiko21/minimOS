package net.emiliollbb.durango;

import java.awt.image.BufferedImage;
import java.io.File;
import java.io.IOException;

import javax.imageio.ImageIO;

public class BackgroundExporter2 {

	

	public static void main(final String args[]) throws IOException {
		final File file = new File("/tmp/boat1.png");
		//final File file = new File("/tmp/palette.png");
		final BufferedImage image = ImageIO.read(file);
		int addr = 0x6000;
		for(int row=0; row < image.getHeight(); row++) {
			for(int col=0; col<image.getWidth(); col+=2) {
				System.out.print("mem[");
				System.out.print(String.format("0x%02X",addr++));
				System.out.print("]=");
				System.out.print(String.format("0x%02X", 
						Palette.getColorByte(image.getRGB(col, row), image.getRGB(col+1, row))));
				System.out.print(';');
				if(addr%16==15) {
					//System.out.println();
				}
			}			
		}
	}
	
}
