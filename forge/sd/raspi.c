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
#define	SCK			16
#define	MOSI		20
#define	CS			21
/* SPI-specific pin definitions, 1 (+3.3v) and 7 (BCM 4) at header */
#define	MISO		4


#define	CS_DISABLE()	digitalWrite(CS, 1)
#define	CS_ENABLE()		digitalWrite(CS, 0)

#define	CMD0		0
#define	CMD0_ARG	0x00000000
#define	CMD0_CRC	0x94

#define	CMD8		8
#define	CMD8_ARG	0x0000001AA
#define CMD8_CRC	0x86 //(1000011 << 1)

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
	CS_DISABLE();
	delayMicroseconds(1000);
	for (u_int8_t i = 0; i < 10; i++)	SPI_transfer(0xFF);	// send 80 clocks
	CS_DISABLE();
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
	CS_ENABLE();
	SPI_transfer(0xFF);

	// send CMD0
	SD_command(CMD0, CMD0_ARG, CMD0_CRC);

	// read response
	u_int8_t res1 = SD_readRes1();

	// deassert chip select
	SPI_transfer(0xFF);
	CS_DISABLE();
	SPI_transfer(0xFF);

	return res1;
}

void SD_readRes7(uint8_t *res) {
	// read response 1 in R7
	res[0] = SD_readRes1();

	// if error reading R1, return
	if(res[0] > 1) return;

	// read remaining bytes
	res[1] = SPI_transfer(0xFF);
	res[2] = SPI_transfer(0xFF);
	res[3] = SPI_transfer(0xFF);
	res[4] = SPI_transfer(0xFF);
}

void SD_sendIfCond(uint8_t *res) {
	// assert chip select
	SPI_transfer(0xFF);
	CS_ENABLE();
	SPI_transfer(0xFF);

	// send CMD8
	SD_command(CMD8, CMD8_ARG, CMD8_CRC);

	// read response
	SD_readRes7(res);

	// deassert chip select
	SPI_transfer(0xFF);
	CS_DISABLE();
	SPI_transfer(0xFF);
}

#define	PARAM_ERROR(X)		X & 0b01000000
#define	ADDR_ERROR(X)		X & 0b00100000
#define	ERASE_SEQ_ERROR(X)	X & 0b00010000
#define	CRC_ERROR(X)		X & 0b00001000
#define	ILLEGAL_CMD(X)		X & 0b00000100
#define	ERASE_RESET(X)		X & 0b00000010
#define	IN_IDLE(X)			X & 0b00000001

void SD_printR1(uint8_t res){
	if(res & 0b10000000)	{	printf("\tError: MSB = 1\r\n"); return; }
	if(res == 0)			{	printf("\tCard Ready\r\n"); return; }
	if(PARAM_ERROR(res))		printf("\tParameter Error\r\n");
	if(ADDR_ERROR(res))			printf("\tAddress Error\r\n");
	if(ERASE_SEQ_ERROR(res))	printf("\tErase Sequence Error\r\n");
	if(CRC_ERROR(res))			printf("\tCRC Error\r\n");
	if(ILLEGAL_CMD(res))		printf("\tIllegal Command\r\n");
	if(ERASE_RESET(res))		printf("\tErase Reset Error\r\n");
	if(IN_IDLE(res))			printf("\tIn Idle State\r\n");
}

#define	CMD_VER(X)			((X >> 4) & 0xF0)
#define	VOL_ACC(X)			(X & 0x1F)

#define	VOLTAGE_ACC_27_33	0b00000001
#define	VOLTAGE_ACC_LOW		0b00000010
#define	VOLTAGE_ACC_RES1	0b00000100
#define	VOLTAGE_ACC_RES2	0b00001000

void SD_printR7(uint8_t *res){
	SD_printR1(res[0]);

	if(res[0] > 1)	return;

	printf("\tCommand Version: ");
	printf("%02X", CMD_VER(res[1]));
	printf("\r\n");

	printf("\tVoltage Accepted: ");
	if(VOL_ACC(res[3]) == VOLTAGE_ACC_27_33)
		printf("2.7-3.6V\r\n");
	else if(VOL_ACC(res[3]) == VOLTAGE_ACC_LOW)
		printf("LOW VOLTAGE\r\n");
	else if(VOL_ACC(res[3]) == VOLTAGE_ACC_RES1)
		printf("RESERVED\r\n");
	else if(VOL_ACC(res[3]) == VOLTAGE_ACC_RES2)
		printf("RESERVED\r\n");
	else
		printf("NOT DEFINED\r\n");

	printf("\tEcho: ");
	printf("%02X", res[4]);
	printf("\r\n");
}

int main(void) {
// array to hold responses
	uint8_t res[5];

// initialize SPI
	SPI_init();

// start power up sequence
	SD_powerUpSeq();

// command card to idle
	printf("Sending CMD0...\r\n");
	res[0] = SD_goIdleState();
	printf("Response:\r\n");
	SD_printR1(res[0]);

// send if conditions
	printf("Sending CMD8...\r\n");
	SD_sendIfCond(res);
	printf("Response:\r\n");
	SD_printR7(res);

	while(1);
}
