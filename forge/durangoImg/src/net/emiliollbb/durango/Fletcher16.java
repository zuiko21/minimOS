package net.emiliollbb.durango;

import java.io.File;
import java.nio.charset.Charset;
import java.nio.file.Files;

public class Fletcher16 {
	private static final String SIGNATURE_STAMP = "SIGNATURE:[";
	
	private static void addSignature(int offset, byte[] rom) throws Exception {
		int sum, check;				/* computed sums    */
		int size;					/* ROM size         */
		int skip;					/* I/O page to be skipped                          */
		int target;					/* preliminary sum */
		int i, j;
				
		size=rom.length;				/* compute size    */
		if (size>32768) {
			System.out.print("\n*** File too large ***\n\n");
			throw new Exception("File too large!");				/* too large       */
		}
		System.out.print("ROM size: "+size+" bytes\n");
		target=0;
		for (i=0; i<size; i++) {
			target += rom[i];		/* preliminary sum */
		}
		
		skip = 256;				/* impossible value */
		System.out.print("DOWNLOADABLE ROM, no page skipped\n");
		skip = size-((256-skip)<<8);	/* convert page into offset */
		target -= rom[offset];		/* subtract reserved values */
		target -= rom[offset+1];
		target &= 255;
		target = 256-target;		/* expected sum    */
		System.out.print("Original signature: "+String.format("%02X",rom[offset])+String.format("%02X",rom[offset+1]));
		rom[offset]		=0;
		rom[offset+1]	=0;			/* clear them too  */

		check=sum=0;				/* precheck values */
	/*	for(i=0;i<size;i++) {
			sum += rom[i];
			sum &= 255;
			check += sum;
			check &= 255;
		}
		System.out.print("ORIGINAL: %d, %d ($%02x%02x)\n", sum, check, check, sum);*/
		System.out.print("TARGET: "+target+"\n");

		check = 256;
		j=0;
		while (j<256 && check!=0) {
			rom[offset]=(byte)j;					/* preload candidates */
			rom[offset+1]=(byte)((target-j) & 255);	/* as defined from preliminary sum */
			check=sum=0;
			for(i=0;i<size;i++) {
				if (i==skip)	i+=256;		/* skip I/O page */
				sum += rom[i];
				sum &= 255;
				check += sum;
				check &= 255;
			}
//			if(check==0)	System.out.print("%d.%d: SUM=%d, CHECK=%d\n", j, rom[offset+1], sum, check);
			j++;
		}
		if (check>0) {
			System.out.print("\n*** No way! Try another offset ***\n\n");
			throw new Exception("\n*** No way! Try another offset ***\n\n");
		}
		System.out.print(j+" attempts\n");
		System.out.print("ROM signature: "+String.format("%02X",rom[offset])+String.format("%02X",rom[offset+1]));
	
		System.out.print("\nDone!\n\n");
	}
	
	private static int findSignatureOffset(byte[] rom) {
		return new String(rom, Charset.forName("ASCII")).indexOf(SIGNATURE_STAMP) + SIGNATURE_STAMP.length();
	}
	
	public static void main(String[] args) throws Exception {
		byte[] rom = Files.readAllBytes(new File("/tmp/pong.bin").toPath());
		int offset = findSignatureOffset(rom);
		System.out.println(offset);
		addSignature(offset, rom);
		Files.write(new File("/tmp/pong_signed.bin").toPath(), rom);
	}

}
