/* SD-card SPI interface simulation on Raspberry Pi
 * based on http://www.rjhcoding.com/avrc-sd-interface-1.php
 * (c) 2023 Carlos J. Santisteban
 * */
 
#include <stdio.h>
#include <stdlib.h>
#include <wiringPi.h>
/* *** needs -lwiringPi option *** */

/* pin definitions, 36-38-40 at header, BCM 16-20-21 */
/* can use pin 34 as GND                             */
#define	SCK		16
#define	MOSI	20
#define	CS		21
/* SPI-specific pin definitions, 1 (+3.3v) and 7 (BCM 4) at header */
#define	MISO	4

#define CMD0		0
#define CMD0_ARG	0x00000000
#define CMD0_CRC	0x94

void SPI_init() {
/* GPIO setup */
	wiringPiSetupGpio();	/* using BCM numbering! */
	digitalWrite(SCK, 0);	/* clock initially idle */
	pinMode(SCK, OUTPUT);
	pinMode(MOSI, OUTPUT);
	pinMode(CS, OUTPUT);
	pinMode(MISO, INPUT);
}

u_int8_t SPI_transfer(u_int8_t data) {	/* exchange byte, MSb first! based on Wikipedia code */
	u_int8_t	in = 0, x = 8;
	
	digitalWrite(SCK, 0);
	while (x) {
		digitalWrite(MOSI, data & 128);
		data <<= 1;
		delayMicroseconds(4);
		digitalWrite(SCK, 1);
		in <<= 1;
		in |= digitalRead(MISO);
		delayMicroseconds(4);
		digitalWrite(SCK, 0);
		x--;
	}

	return in;
}

void SD_powerUpSeq() {
	digitalWrite(CS, 1);	// CS_DISABLE
	delayMicroseconds(1000);
	for (u_int8_t i = 0; i < 10; i++)	SPI_transfer(0xFF);	// send 80 clocks
	digitalWrite(CS, 1);	// CS_DISABLE
	SPI_transfer(0xFF);
}

void SD_command(u_int8_t cmd, u_int32_t arg, u_int8_t crc) {
	// send command
	SPI_transfer(cmd|0x40);

	// send argument
	SPI_transfer((u_int8_t)(arg >> 24));
	SPI_transfer((u_int8_t)(arg >> 16));
	SPI_transfer((u_int8_t)(arg >> 8));
	SPI_transfer((u_int8_t)(arg));

	// send CRC
	SPI_transfer(crc|0x01);
}

u_int8_t SD_readRes1() {
	u_int8_t i = 0, res1;

	// keep polling until actual data received
	while((res1 = SPI_transfer(0xFF)) == 0xFF)
	{
		i++;

		// if no data received for 8 bytes, break
		if(i > 8) break;
	}

	return res1;
}

u_int8_t SD_goIdleState() {
	// assert chip select
	SPI_transfer(0xFF);
	digitalWrite(CS, 0);	// CS_ENABLE
	SPI_transfer(0xFF);

	// send CMD0
	SD_command(CMD0, CMD0_ARG, CMD0_CRC);

	// read response
	u_int8_t res1 = SD_readRes1();

	// deassert chip select
	SPI_transfer(0xFF);
	digitalWrite(CS, 1);	// CS_DISABLE
	SPI_transfer(0xFF);

	return res1;
}

int main(void) {
	// initialize SPI
	SPI_init();

	// start power up sequence
	SD_powerUpSeq();

	// command card to idle
	SD_goIdleState();

	while(1);
}
