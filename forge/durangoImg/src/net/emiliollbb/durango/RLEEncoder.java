package net.emiliollbb.durango;

import java.io.File;
import java.io.FileOutputStream;
import java.nio.file.Files;

public class RLEEncoder {
	/* global variables, WTF */
	byte[]	src;			// just in case, read whole input file
	File	f;					// file handler, both source and output as not simultaneous
	int		i;					// i = source index
	long		siz;
	int unc;
	int count;
	int output;
	int	clocks = 0;			// estimated 6502 decompression time!

	/* main code */
	private int main() throws Exception {
		byte	base;				// repeated character
		String	name;			// input filename
		int		thres;				// compression threshold (usually 2 is optimum, but ~19 is faster)
	/* read source file into memory */
		System.out.println("File to compress: ");
		name = "/tmp/pongimg.bin";			// does this put terminator? I think so
		f = new File(name);		// open source file
		if (f==null) {
			System.out.println("\n*** No input file ***\n");
			return -1;
		}
		siz = f.length();				// get length
				
		if (siz>32768) {
			System.out.println("\n*** File is too large ***\n");
			return -2;
		}
		src = Files.readAllBytes(f.toPath()); // read file into memory
				
	/* prepare output file */
		f = new File("/tmp/srcjava.rle");		// get ready for output file
		FileOutputStream out = new FileOutputStream(f);
		if (f==null) {
			System.out.println("\n*** Cannot create output file ***\n");
			out.close();
			return -3;
		}
	/* compress array */
		System.out.println("Compression threshold? (optimum ~2): ");
		thres=2;
	
		i = output = 0;				// cursor and output size reset
		unc = 0;					// this gets reset every time but first
		
		while (i < siz-1) {			// EMILIO FIX: -1
			base = src[i++];		// read this first byte and point to following one
			count = 1;				// assume not yet repeated
									// EMILIO FIX i<siz
			while (i<siz && src[i]==base && count<127 && i<siz) {	// next one is the same?
				count++;									// count it
				i++;										// and check the next one
			}
			if (count>thres) {		// any actual repetition?
				if (unc>0)
					send_u(out);		// send previous uncompressed chunk, if any!
				out.write(count);	// first goes 'command', positive means repeat following byte
				out.write(base);		// this was the repeated value
				output += 2;
				clocks += 47+13*count;
			} else {
				unc+=count;			// different, thus more for the uncompressed chunk EEEEEEK
				if (unc>=128) {
					send_u(out);		// cannot add more to chunk
				}
			}
		}
	/* input stream ended, but check for anything in progress! */
		count=0;					// EEEEEEEEEEEK
		if (unc>0)
			send_u(out);				// send uncompressed chunk in progress!
	
	/* end output stream and cleanout */
		out.write(0);				// end of stream
		output++;
		out.close();
		System.out.println("\nDone! Encoded "+siz+" bytes into "+output+" ("+(100*output/siz)+")\n");
		System.out.println("Estimated 6502 timing: "+clocks+" clock cycles\n");
	
		return 0;
	}

/* function definitions */
	private void send_u(FileOutputStream out) throws Exception {	// go backwards and send uncompressed chunk
		int		x, y;				// x = uncompressed chunk index, y = min(unc,128)
	
		x = i - unc - count;		// compute start of chunk
		y = (unc<128)?unc:128;		// cannot sent more than 128 in a chunk
		clocks += 46+18*y;
		out.write(-y);				// negative 'command' means length of uncompressed chunk EEEEK
		output++;
		while (y-->0) {
			out.write(src[x++]);		// send uncompressed byte
			output++;
			unc--;					// may NOT finish as 0
		}
	}
	
	public static void main(String[] args) throws Exception {
		new RLEEncoder().main();
	}
}
