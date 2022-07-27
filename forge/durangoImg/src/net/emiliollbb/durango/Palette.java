package net.emiliollbb.durango;

public class Palette {

	public static final int COLOR_00 = -16777216;	// Negro
	public static final int COLOR_01 = -16733696;	// Verde
	public static final int COLOR_02 = -65536;		// Rojo
	public static final int COLOR_03 = -22016;		// Naranja
	public static final int COLOR_04 = -16755456;	// Botella
	public static final int COLOR_05 = -16711936;	// Lima
	public static final int COLOR_06 = -43776;		// Ladrillo
	public static final int COLOR_07 = -256;		// Amarillo
	public static final int COLOR_08 = -16776961;	// Azul
	public static final int COLOR_09 = -16733441;	// Celeste
	public static final int COLOR_10 = -65281;		// Magenta
	public static final int COLOR_11 = -21761;		// Rosita
	public static final int COLOR_12 = -16755201;	// Azur
	public static final int COLOR_13 = -16711681;	// Cian
	public static final int COLOR_14 = -43521;		// Fucsia
	public static final int COLOR_15 = -1;			// Blanco

	public static int getColorIndex(int rgb) {
		switch(rgb) {
			case COLOR_00: return 0;
			case COLOR_01: return 1;
			case COLOR_02: return 2;
			case COLOR_03: return 3;
			case COLOR_04: return 4;
			case COLOR_05: return 5;
			case COLOR_06: return 6;
			case COLOR_07: return 7;
			case COLOR_08: return 8;
			case COLOR_09: return 9;
			case COLOR_10: return 10;
			case COLOR_11: return 11;
			case COLOR_12: return 12;
			case COLOR_13: return 13;
			case COLOR_14: return 14;
			case COLOR_15: return 15;
			default : return -1;
		}
	}
	
	public static byte getColorByte(int rgb) {
		switch(rgb) {
			case COLOR_00: return 0x00;
			case COLOR_01: return 0x01;
			case COLOR_02: return 0x02;
			case COLOR_03: return 0x03;
			case COLOR_04: return 0x04;
			case COLOR_05: return 0x05;
			case COLOR_06: return 0x06;
			case COLOR_07: return 0x07;
			case COLOR_08: return 0x08;
			case COLOR_09: return 0x09;
			case COLOR_10: return 0x0a;
			case COLOR_11: return 0x0b;
			case COLOR_12: return 0x0c;
			case COLOR_13: return 0x0d;
			case COLOR_14: return 0x0e;
			case COLOR_15: return 0x0f;
			default : return (byte)0xff;
		}
	}
	
	public String getColorSpanish(int rgb) {
		switch(rgb) {
			case COLOR_00: return "Negro";
			case COLOR_01: return "Verde";
			case COLOR_02: return "Rojo";
			case COLOR_03: return "Naranja";
			case COLOR_04: return "Botella";
			case COLOR_05: return "Lima";
			case COLOR_06: return "Ladrillo";
			case COLOR_07: return "Amarillo";
			case COLOR_08: return "Azul";
			case COLOR_09: return "Celeste";
			case COLOR_10: return "Magenta";
			case COLOR_11: return "Rosita";
			case COLOR_12: return "Azur";
			case COLOR_13: return "Cian";
			case COLOR_14: return "Fucsia";
			case COLOR_15: return "Blanco";
			default : return "";
		}
	}
	
	public static byte getColorByte(int rgbLeft, int rgbRight) {
		return (byte) ((byte) (getColorByte(rgbLeft)<<4) | getColorByte(rgbRight));
	}
}
