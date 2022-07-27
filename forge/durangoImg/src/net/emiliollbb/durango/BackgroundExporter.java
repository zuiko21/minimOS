package net.emiliollbb.durango;

import java.awt.image.BufferedImage;
import java.io.File;
import java.io.IOException;

import javax.imageio.ImageIO;

public class BackgroundExporter {

	

	public static void mainz(final String args[]) throws IOException {
		String name="background_00";
		 final File file = new File("/tmp/boat1.png");
		//final File file = new File("/tmp/palette.png");
		final BufferedImage image = ImageIO.read(file);
		
		System.out.println(name+":");
		System.out.println("LDA #$00");
		System.out.println("STA $10");
		System.out.println("LDY #$00");
		
		

		for(int row=0; row < image.getHeight(); row++) {
			for(int col=0; col<image.getWidth(); col+=2) {
				System.out.print("LDA #$");
				System.out.print(Integer.toHexString(Palette.getColorIndex(image.getRGB(col, row))));
				System.out.print(Integer.toHexString(Palette.getColorIndex(image.getRGB(col+1, row))));
				System.out.println();
				System.out.println("STA ($10), Y");
				System.out.println("INY");
			}
			if(row>0 && row%4==0) {
				System.out.println("INC $11");
				System.out.println("LDY #$00");
			}
		}
		
		System.out.println("RTS");
	}
	
	
	public static void main(final String args[]) throws IOException {
		final File file = new File("/tmp/boat1.png");
		//final File file = new File("/tmp/palette.png");
		final BufferedImage image = ImageIO.read(file);
		
		for(int row=0; row < image.getHeight(); row++) {
			for(int col=0; col<image.getWidth(); col+=2) {
				System.out.print(Integer.toHexString(Palette.getColorIndex(image.getRGB(col, row))));
				System.out.print(Integer.toHexString(Palette.getColorIndex(image.getRGB(col+1, row))));
				System.out.print(" ");
				System.out.print(String.format("0x%02X", 
						Palette.getColorByte(image.getRGB(col, row), image.getRGB(col+1, row))));
				System.out.println();
			}
		}
	}
}
