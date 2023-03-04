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
/* SPI-specific pin definitions, 1 (+3.3v) and 37 (was 7, BCM 4) at header */
#define	MISO		26


#define	CS_DISABLE()	digitalWrite(CS, 1)
#define	CS_ENABLE()		digitalWrite(CS, 0)

#define	CMD0		0
#define	CMD0_ARG	0x00000000
#define	CMD0_CRC	0x94

#define	CMD8		8
#define	CMD8_ARG	0x0000001AA
#define	CMD8_CRC	0x86 //(1000011 << 1)

#define	CMD58		58
#define	CMD58_ARG	0x00000000
#define	CMD58_CRC	0x00

#define	CMD55		55
#define	CMD55_ARG	0x00000000
#define	CMD55_CRC	0x00

#define	ACMD41		41
#define	ACMD41_ARG	0x40000000
#define	ACMD41_CRC	0x00

#define	CMD17		17
#define	CMD17_CRC	0x00
#define	SD_MAX_READ_ATTEMPTS	1563

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
//		delayMicroseconds(4);	//?
		digitalWrite(MOSI, data & 128);
		data <<= 1;
		delayMicroseconds(4);
		digitalWrite(SCK, 1);
		in <<= 1;
		if(digitalRead(MISO))	in++;
//printf("%d-",digitalRead(MISO));
		delayMicroseconds(4);
		digitalWrite(SCK, 0);
		x--;
	}
//printf("[%02X]",in);
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

void SD_readRes7(u_int8_t *res) {	// also for R3
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

void SD_sendIfCond(u_int8_t *res) {
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

void SD_readOCR(u_int8_t *res) {
	// assert chip select
	SPI_transfer(0xFF);
	CS_ENABLE();
	SPI_transfer(0xFF);

	// send CMD58
	SD_command(CMD58, CMD58_ARG, CMD58_CRC);

	// read response
	SD_readRes7(res);	// actually R3

	// deassert chip select
	SPI_transfer(0xFF);
	CS_DISABLE();
	SPI_transfer(0xFF);
}

u_int8_t SD_sendApp() {
	// assert chip select
	SPI_transfer(0xFF);
	CS_ENABLE();
	SPI_transfer(0xFF);

	// send CMD55
	SD_command(CMD55, CMD55_ARG, CMD55_CRC);

	// read response
	u_int8_t res1 = SD_readRes1();

	// deassert chip select
	SPI_transfer(0xFF);
	CS_DISABLE();
	SPI_transfer(0xFF);

	return res1;
}

u_int8_t SD_sendOpCond() {
	// assert chip select
	SPI_transfer(0xFF);
	CS_ENABLE();
	SPI_transfer(0xFF);

	// send CMD0
	SD_command(ACMD41, ACMD41_ARG, ACMD41_CRC);

	// read response
	u_int8_t res1 = SD_readRes1();

	// deassert chip select
	SPI_transfer(0xFF);
	CS_DISABLE();
	SPI_transfer(0xFF);

	return res1;
}

#define	PARAM_ERROR(X)		X & 0b01000000
#define	ADDR_ERROR(X)		X & 0b00100000
#define	ERASE_SEQ_ERROR(X)	X & 0b00010000
#define	CRC_ERROR(X)		X & 0b00001000
#define	ILLEGAL_CMD(X)		X & 0b00000100
#define	ERASE_RESET(X)		X & 0b00000010
#define	IN_IDLE(X)			X & 0b00000001

void SD_printR1(u_int8_t res){
	if(res & 0b10000000)	{	printf("\tError: MSB = 1 ($%02X)\r\n",res); return; }
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

void SD_printR7(u_int8_t *res){
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

#define POWER_UP_STATUS(X)  X & 0x40
#define CCS_VAL(X)          X & 0x40
#define VDD_2728(X)         X & 0b10000000
#define VDD_2829(X)         X & 0b00000001
#define VDD_2930(X)         X & 0b00000010
#define VDD_3031(X)         X & 0b00000100
#define VDD_3132(X)         X & 0b00001000
#define VDD_3233(X)         X & 0b00010000
#define VDD_3334(X)         X & 0b00100000
#define VDD_3435(X)         X & 0b01000000
#define VDD_3536(X)         X & 0b10000000

void SD_printR3(u_int8_t *res) {
	SD_printR1(res[0]);

	if(res[0] > 1)	return;

	printf("\tCard Power Up Status: ");
	if(POWER_UP_STATUS(res[1])) {
		printf("READY\r\n");
		printf("\tCCS Status: ");
		if(CCS_VAL(res[1]))	{	printf("1\r\n"); }
		else					printf("0\r\n");
	} else {
		printf("BUSY\r\n");
	}

	printf("\tVDD Window: ");
	if(VDD_2728(res[3])) printf("2.7, ");
	if(VDD_2829(res[2])) printf("2.8, ");
	if(VDD_2930(res[2])) printf("2.9, ");
	if(VDD_3031(res[2])) printf("3.0, ");
	if(VDD_3132(res[2])) printf("3.1, ");
	if(VDD_3233(res[2])) printf("3.2, ");
	if(VDD_3334(res[2])) printf("3.3, ");
	if(VDD_3435(res[2])) printf("3.4, ");
	if(VDD_3536(res[2])) printf("3.5-3.6");
	printf("\r\n");
}

#define	SD_TOKEN_OOR(X)		X & 0b00001000
#define	SD_TOKEN_CECC(X)	X & 0b00000100
#define	SD_TOKEN_CC(X)		X & 0b00000010
#define	SD_TOKEN_ERROR(X)	X & 0b00000001

void SD_printDataErrToken(u_int8_t token) {
	if(SD_TOKEN_OOR(token))
		printf("\tData out of range\n");
	if(SD_TOKEN_CECC(token))
		printf("\tCard ECC failed\n");
	if(SD_TOKEN_CC(token))
		printf("\tCC Error\n");
	if(SD_TOKEN_ERROR(token))
		printf("\tError\n");
}

#define	SD_SUCCESS	0
#define	SD_ERROR	1
#define	SD_READY	0

u_int8_t SD_init()
{
	u_int8_t res[5], cmdAttempts = 0;

	SD_powerUpSeq();

	// command card to idle
	printf("Going idle");		//***
	while((res[0] = SD_goIdleState()) != 0x01) {
		cmdAttempts++;
		printf(".");			//***
		if(cmdAttempts > 10)	return SD_ERROR;
	}
	printf("\nResponse:\n");	//***
	SD_printR1(res[0]);			//***

	// send interface conditions
	printf("\nSending interface conditions: ");		//***
	SD_sendIfCond(res);
	if(res[0] != 0x01)			return SD_ERROR;

	// check echo pattern
	if(res[4] != 0xAA)			return SD_ERROR;
	printf("Echo pattern OK!\n");					//***

	// attempt to initialize card
//	cmdAttempts = 0;
	printf("SD card init");		//***
	do {
		if(cmdAttempts > 100)	return SD_ERROR;

		// send app cmd
		res[0] = SD_sendApp();

		// if no error in response
		if(res[0] < 2)	res[0] = SD_sendOpCond();

		// wait
		delayMicroseconds(10000);
		cmdAttempts++;
		printf(".");			//***
	} while(res[0] != SD_READY);
	printf(" Ready!\n");		//***
	// read OCR
	SD_readOCR(res);

	// check card is ready
	if(!(res[1] & 0x80))		return SD_ERROR;

	return SD_SUCCESS;
}

u_int8_t SD_readSingleBlock(u_int32_t addr, u_int8_t *buf, u_int8_t *token) {
	u_int8_t	res1, read;
	u_int16_t	readAttempts;

	// set token to none
	*token = 0xFF;

	// assert chip select
	SPI_transfer(0xFF);
	CS_ENABLE();
	SPI_transfer(0xFF);

	// send CMD17
	SD_command(CMD17, addr, CMD17_CRC);

	// read R1
	res1 = SD_readRes1();

	// if response received from card
	if(res1 != 0xFF) {
		// wait for a response token (timeout = 100ms)
		readAttempts = 0;
		while(++readAttempts != SD_MAX_READ_ATTEMPTS)
			if((read = SPI_transfer(0xFF)) != 0xFF)		break;

		// if response token is 0xFE
		if(read == 0xFE) {
			// read 512 byte block
			for(u_int16_t i = 0; i < 512; i++)
				*buf++ = SPI_transfer(0xFF);

			// read 16-bit CRC
			SPI_transfer(0xFF);
			SPI_transfer(0xFF);
		}

		// set token to card response
		*token = read;
	}

	// deassert chip select
	SPI_transfer(0xFF);
	CS_DISABLE();
	SPI_transfer(0xFF);

	return res1;
}

int main(void) {
	// array to hold responses
	u_int8_t res[5], sdBuf[512], token;

	// initialize SPI
	SPI_init();

	// init SD card in full!
	if(SD_init() != SD_SUCCESS)	{	printf("\nError initializaing SD CARD\n"); return 0; }
	else							printf("\nSD Card initialized!\n");

	// read sector 0
	printf("*** READ SECTOR 0 ***\n");
	res[0] = SD_readSingleBlock(0x00000000, sdBuf, &token);

	// print response
	if((res[0]<2) && (token == 0xFE)) {
		for(u_int16_t i = 0; i < 512; i++)	printf("%c", sdBuf[i]>31?sdBuf[i]:'.');
		printf("\n\n");
	} else {
		printf("Error reading sector\n");
	}

	// try to generate a read error
	printf("*** TRY TO READ NON-EXISTENT SECTOR ***\n");
	res[0] = SD_readSingleBlock(0xffffffff, sdBuf, &token);

	printf("Response 1:\r\n");
	SD_printR1(res[0]);

	// if error token received
	if(!(token & 0xF0)) {
		printf("Error token:\r\n");
		SD_printDataErrToken(token);	// eeek
	} else if(token == 0xFF) {
		printf("Timeout\n");
	}

	return 0;
}
