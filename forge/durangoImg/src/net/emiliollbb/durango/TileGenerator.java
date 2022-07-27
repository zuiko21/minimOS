package net.emiliollbb.durango;

import java.awt.image.BufferedImage;
import java.io.File;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedList;
import java.util.List;

import javax.imageio.ImageIO;

public class TileGenerator {

	public static void mainz(String[] args) throws Exception {
		final File file = new File("/tmp/boat1.png");
		final BufferedImage image = ImageIO.read(file);
		Tile tile = new Tile(image, 0, 0);
		System.out.println(tile);		
	}
	
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
	
	public static void generateMap(List<Integer> map, List<Tile> tiles, String s) throws Exception {
		final File file = new File(s);
		final BufferedImage image = ImageIO.read(file);
			
		for(int row=0; row < 16; row++) {
			for(int col=0; col<16; col++) {
				map.add(findTile(tiles, new Tile(image, row, col)));
			}
		}						
	}
	
	public static void printMap(List<Integer> map) {
		Integer[] tiles = new Integer[256];
		map.toArray(tiles);
		
		for(int i=0; i<256/32; i++) {
			System.out.print(".byt ");
			for(int j=0; j<32; j++) {
				System.out.print(String.format("$%02X", tiles[i*32+j]));
				System.out.print(',');
			}
			System.out.println();
		}
	}
	
	public static void mainzz(final String args[]) throws Exception {
		List<Tile> tiles = new ArrayList<Tile>(255);
		List<Integer> map1 = new LinkedList<>();
		List<Integer> map2 = new LinkedList<>();
		List<Integer> map3 = new LinkedList<>();
		generateTiles(tiles, Arrays.asList("/tmp/boat1.png"));
		System.out.println("Tiles: " + tiles.size());
		generateTiles(tiles, Arrays.asList("/tmp/boat2.png"));
		System.out.println("Tiles: " + tiles.size());
		generateTiles(tiles, Arrays.asList("/tmp/boat3.png"));
		System.out.println("Tiles: " + tiles.size());
		
		while(tiles.size()<256) {
			tiles.add(new Tile());
		}
		
		System.out.println("Size: " + tiles.size());
		
		generateMap(map1, tiles, "/tmp/boat1.png");
		generateMap(map2, tiles, "/tmp/boat2.png");
		generateMap(map3, tiles, "/tmp/boat3.png");
		
		System.out.println("----- TILES ------");
		int i=0;
		for(Tile t : tiles) {
			System.out.println(t.getHexString()+" ; Tile "+String.format("$%02X",i));
			i++;
		}
		System.out.println("\n----- ----- ------");
		System.out.println("----- MAPS ------");
		System.out.println("; --- map1 ---");
		printMap(map1);
		System.out.println("; --- map2 ---");
		printMap(map2);
		System.out.println("; --- map3 ---");
		printMap(map3);		
	}
	
	public static void main(final String args[]) throws Exception {
		List<Tile> tiles = new ArrayList<Tile>(255);
		List<Integer> map1 = new LinkedList<>();
		generateTiles(tiles, Arrays.asList("/tmp/gamepads.png"));
		System.out.println("Tiles: " + tiles.size());
		
		generateMap(map1, tiles, "/tmp/gamepads.png");
		
		System.out.println("----- TILES ------");
		int i=0;
		for(Tile t : tiles) {
			System.out.println(t.getHexString()+" ; Tile "+String.format("$%02X",i));
			i++;
		}
		System.out.println("\n----- ----- ------");
		System.out.println("----- MAPS ------");
		System.out.println("; --- map1 ---");
		printMap(map1);		
	}
}
