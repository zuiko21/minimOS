package net.emiliollbb.durango;

import java.awt.image.BufferedImage;

public class Tile implements Comparable<Tile>{
	byte pixels[];
	
	public Tile() {
		pixels = new byte[32];
	}
		
	public Tile(BufferedImage image, int tileRow, int tileCol) {
		this();
		int i=0;
		for(int row=tileRow*8; row < tileRow*8+8; row++) {
			for(int col=tileCol*8; col<tileCol*8+8; col+=2) {
				pixels[i++]=Palette.getColorByte(image.getRGB(col, row), image.getRGB(col+1, row));				
			}
		}
	}
	
	public String getHexString() {
		StringBuilder sb = new StringBuilder(50);
		sb.append(".byt ");
		for(int i=0; i<pixels.length; i++) {
			sb.append(String.format("$%02X",pixels[i])).append(',');
		}
		return sb.toString();
	}
	
	@Override
	public String toString() {
		StringBuilder sb = new StringBuilder(50);
		for(int i=0; i<pixels.length; i++) {
			sb.append(String.format("0x%02X",pixels[i])).append(' ');
			if(i%4==3) {
				sb.append('\n');
			}
		}
		return sb.toString();
	}

	@Override
	public int compareTo(Tile o) {
		for(int i=0; i<pixels.length; i++) {
			if(pixels[i]!=o.pixels[i]) {
				return Integer.valueOf(pixels[i]).compareTo(Integer.valueOf(o.pixels[i]));
			}
		}
		return 0;
	}
	
	@Override
	public boolean equals(Object obj) {
		if(obj instanceof Tile) {
			return this.compareTo((Tile)obj)==0;
		}
		else {
			return false;
		}
	}
}
