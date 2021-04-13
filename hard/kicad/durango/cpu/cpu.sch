EESchema Schematic File Version 4
LIBS:cpu-cache
EELAYER 30 0
EELAYER END
$Descr A4 11693 8268
encoding utf-8
Sheet 1 1
Title "CPU board for DURANGO computer"
Date "2021-04-12"
Rev ""
Comp "@zuiko21"
Comment1 "(c) 2021 Carlos J. Santisteban"
Comment2 ""
Comment3 ""
Comment4 ""
$EndDescr
$Comp
L cpu-rescue:62256-Memory_RAM-cpu-rescue U2
U 1 1 6074461F
P 3850 2050
F 0 "U2" H 3650 3150 50  0000 C CNN
F 1 "62256" H 4050 3150 50  0000 C CNN
F 2 "" H 3850 2050 50  0001 C CNN
F 3 "http://www.6502.org/users/alexis/62256.pdf" H 3850 2050 50  0001 C CNN
	1    3850 2050
	1    0    0    -1  
$EndComp
$Comp
L cpu-rescue:27C128-Memory_EPROM-cpu-rescue U3
U 1 1 60745512
P 5250 2050
F 0 "U3" H 5450 3100 50  0000 C CNN
F 1 "27C128" H 5050 3100 50  0000 C CNN
F 2 "Package_DIP:DIP-28_W15.24mm" H 5250 2050 50  0001 C CNN
F 3 "http://ww1.microchip.com/downloads/en/devicedoc/11003L.pdf" H 5250 2050 50  0001 C CNN
	1    5250 2050
	-1   0    0    -1  
$EndComp
$Comp
L cpu-rescue:74LS139-74xx-cpu-rescue U4
U 1 1 6074706A
P 3750 4150
F 0 "U4" H 3750 4517 50  0000 C CNN
F 1 "74HC139" H 3750 4426 50  0000 C CNN
F 2 "" H 3750 4150 50  0001 C CNN
F 3 "http://www.ti.com/lit/gpn/sn74LS139" H 3750 4150 50  0001 C CNN
	1    3750 4150
	1    0    0    -1  
$EndComp
$Comp
L cpu-rescue:74LS139-74xx-cpu-rescue U4
U 2 1 607493A2
P 3750 4900
F 0 "U4" H 3750 5267 50  0000 C CNN
F 1 "74HC139" H 3750 5176 50  0000 C CNN
F 2 "" H 3750 4900 50  0001 C CNN
F 3 "http://www.ti.com/lit/gpn/sn74LS139" H 3750 4900 50  0001 C CNN
	2    3750 4900
	1    0    0    -1  
$EndComp
$Comp
L cpu-rescue:74LS139-74xx-cpu-rescue U5
U 1 1 60749982
P 5300 4500
F 0 "U5" H 5300 4867 50  0000 C CNN
F 1 "74HC139" H 5300 4776 50  0000 C CNN
F 2 "" H 5300 4500 50  0001 C CNN
F 3 "http://www.ti.com/lit/gpn/sn74LS139" H 5300 4500 50  0001 C CNN
	1    5300 4500
	-1   0    0    1   
$EndComp
$Comp
L cpu-rescue:74LS139-74xx-cpu-rescue U5
U 2 1 6074A28D
P 5300 3700
F 0 "U5" H 5300 4067 50  0000 C CNN
F 1 "74HC139" H 5300 3976 50  0000 C CNN
F 2 "" H 5300 3700 50  0001 C CNN
F 3 "http://www.ti.com/lit/gpn/sn74LS139" H 5300 3700 50  0001 C CNN
	2    5300 3700
	1    0    0    -1  
$EndComp
$Comp
L cpu-rescue:4040-4xxx-cpu-rescue U10
U 1 1 6074C247
P 1050 4750
F 0 "U10" H 1200 5650 50  0000 C CNN
F 1 "4040" H 1200 5550 50  0000 C CNN
F 2 "" H 1050 4750 50  0001 C CNN
F 3 "http://www.intersil.com/content/dam/Intersil/documents/cd40/cd4020bms-24bms-40bms.pdf" H 1050 4750 50  0001 C CNN
	1    1050 4750
	1    0    0    -1  
$EndComp
$Comp
L cpu-rescue:74LS139-74xx-cpu-rescue U6
U 1 1 6074F30E
P 5300 5350
F 0 "U6" H 5300 5717 50  0000 C CNN
F 1 "74HC139" H 5300 5626 50  0000 C CNN
F 2 "" H 5300 5350 50  0001 C CNN
F 3 "http://www.ti.com/lit/gpn/sn74LS139" H 5300 5350 50  0001 C CNN
	1    5300 5350
	1    0    0    -1  
$EndComp
$Comp
L cpu-rescue:74LS139-74xx-cpu-rescue U6
U 2 1 6074FDAB
P 5350 6100
F 0 "U6" H 5350 6467 50  0000 C CNN
F 1 "74HC139" H 5350 6376 50  0000 C CNN
F 2 "" H 5350 6100 50  0001 C CNN
F 3 "http://www.ti.com/lit/gpn/sn74LS139" H 5350 6100 50  0001 C CNN
	2    5350 6100
	-1   0    0    -1  
$EndComp
$Comp
L cpu-rescue:74HC245-74xx-cpu-rescue U9
U 1 1 60754204
P 9550 5200
F 0 "U9" H 9550 6181 50  0000 C CNN
F 1 "74HC245" H 9550 6090 50  0000 C CNN
F 2 "" H 9550 5200 50  0001 C CNN
F 3 "http://www.ti.com/lit/gpn/sn74HC245" H 9550 5200 50  0001 C CNN
	1    9550 5200
	0    1    -1   0   
$EndComp
$Comp
L cpu-rescue:74HC374-74xx-cpu-rescue U7
U 1 1 60755513
P 3650 6350
F 0 "U7" H 3800 7000 50  0000 C CNN
F 1 "74HC374" H 3450 7000 50  0000 C CNN
F 2 "" H 3650 6350 50  0001 C CNN
F 3 "https://www.ti.com/lit/ds/symlink/cd74hct374.pdf" H 3650 6350 50  0001 C CNN
	1    3650 6350
	-1   0    0    -1  
$EndComp
$Comp
L cpu-rescue:74HC74-74xx-cpu-rescue U8
U 1 1 60756402
P 6900 4100
F 0 "U8" H 6900 4581 50  0000 C CNN
F 1 "74HC74" H 6900 4490 50  0000 C CNN
F 2 "" H 6900 4100 50  0001 C CNN
F 3 "74xx/74hc_hct74.pdf" H 6900 4100 50  0001 C CNN
	1    6900 4100
	1    0    0    -1  
$EndComp
$Comp
L cpu-rescue:74HC74-74xx-cpu-rescue U8
U 2 1 60756EC3
P 6900 4950
F 0 "U8" H 6900 5431 50  0000 C CNN
F 1 "74HC74" H 6900 5340 50  0000 C CNN
F 2 "" H 6900 4950 50  0001 C CNN
F 3 "74xx/74hc_hct74.pdf" H 6900 4950 50  0001 C CNN
	2    6900 4950
	1    0    0    -1  
$EndComp
$Comp
L cpu-rescue:LED-Device-cpu-rescue D2
U 1 1 60757DE7
P 7650 5050
F 0 "D2" H 7650 4800 50  0000 C CNN
F 1 "RED LED" H 7600 4900 50  0000 C CNN
F 2 "" H 7650 5050 50  0001 C CNN
F 3 "~" H 7650 5050 50  0001 C CNN
	1    7650 5050
	-1   0    0    1   
$EndComp
$Comp
L cpu-rescue:ACO-xxxMHz-Oscillator-cpu-rescue X1
U 1 1 60759190
P 1400 3450
F 0 "X1" H 1150 3700 50  0000 R CNN
F 1 "1 MHz" H 1150 3600 50  0000 R CNN
F 2 "Oscillator:Oscillator_DIP-14" H 1850 3100 50  0001 C CNN
F 3 "http://www.conwin.com/datasheets/cx/cx030.pdf" H 1300 3450 50  0001 C CNN
	1    1400 3450
	1    0    0    -1  
$EndComp
$Comp
L cpu-rescue:R_Pack04_SIP-Device-cpu-rescue RN2
U 1 1 60787186
P 2450 6650
F 0 "RN2" H 3038 6677 50  0000 L CNN
F 1 "470" H 3038 6586 50  0000 L CNN
F 2 "Resistor_THT:R_Array_SIP8" V 3125 6650 50  0001 C CNN
F 3 "http://www.vishay.com/docs/31509/csc.pdf" H 2450 6650 50  0001 C CNN
	1    2450 6650
	1    0    0    -1  
$EndComp
$Comp
L cpu-rescue:R-Device-cpu-rescue R4
U 1 1 6079DBE5
P 7350 5050
F 0 "R4" V 7450 4900 50  0000 L CNN
F 1 "390" V 7250 4950 50  0000 L CNN
F 2 "" V 7280 5050 50  0001 C CNN
F 3 "~" H 7350 5050 50  0001 C CNN
	1    7350 5050
	0    -1   -1   0   
$EndComp
NoConn ~ 1550 4650
NoConn ~ 1550 4550
NoConn ~ 1550 4450
NoConn ~ 1550 4350
NoConn ~ 1550 4250
$Comp
L cpu-rescue:74LS30-74xx-cpu-rescue U11
U 1 1 6074DD29
P 2150 4950
F 0 "U11" H 2150 5475 50  0000 C CNN
F 1 "74HC30" H 2150 5384 50  0000 C CNN
F 2 "" H 2150 4950 50  0001 C CNN
F 3 "http://www.ti.com/lit/gpn/sn74LS30" H 2150 4950 50  0001 C CNN
	1    2150 4950
	1    0    0    1   
$EndComp
Wire Wire Line
	1050 5650 550  5650
Wire Wire Line
	550  5650 550  4550
Wire Wire Line
	1550 5250 1850 5250
Wire Wire Line
	1550 5150 1850 5150
Wire Wire Line
	1550 5050 1650 5050
Wire Wire Line
	1650 5050 1750 4950
Wire Wire Line
	1750 4950 1850 4950
Wire Wire Line
	1850 5050 1750 5050
Wire Wire Line
	1750 5050 1650 4950
Wire Wire Line
	1650 4950 1550 4950
Wire Wire Line
	1550 5350 1800 5350
Wire Wire Line
	1800 5350 1800 4850
Wire Wire Line
	1800 4850 1850 4850
Wire Wire Line
	1550 4750 1850 4750
Wire Wire Line
	1550 4850 1750 4850
Wire Wire Line
	1750 4850 1750 4650
Wire Wire Line
	1750 4650 1850 4650
Wire Wire Line
	1850 2150 1950 2150
Wire Wire Line
	1850 3450 1700 3450
$Comp
L cpu-rescue:+5V-power-cpu-rescue #PWR0101
U 1 1 607F0ABA
P 1400 3150
F 0 "#PWR0101" H 1400 3000 50  0001 C CNN
F 1 "+5V" H 1500 3150 50  0000 C CNN
F 2 "" H 1400 3150 50  0001 C CNN
F 3 "" H 1400 3150 50  0001 C CNN
	1    1400 3150
	1    0    0    -1  
$EndComp
Wire Wire Line
	1950 2650 1900 2650
Wire Wire Line
	1900 2650 1900 3800
$Comp
L cpu-rescue:+5V-power-cpu-rescue #PWR0102
U 1 1 60807619
P 1050 3950
F 0 "#PWR0102" H 1050 3800 50  0001 C CNN
F 1 "+5V" H 900 3950 50  0000 C CNN
F 2 "" H 1050 3950 50  0001 C CNN
F 3 "" H 1050 3950 50  0001 C CNN
	1    1050 3950
	1    0    0    -1  
$EndComp
Wire Wire Line
	550  4250 550  3800
Wire Wire Line
	550  3800 1900 3800
$Comp
L cpu-rescue:BC547-Transistor_BJT-cpu-rescue Q1
U 1 1 608143AC
P 1200 2750
F 0 "Q1" H 1391 2796 50  0000 L CNN
F 1 "BC547" H 1391 2705 50  0000 L CNN
F 2 "Package_TO_SOT_THT:TO-92_Inline" H 1400 2675 50  0001 L CIN
F 3 "http://www.fairchildsemi.com/ds/BC/BC547.pdf" H 1200 2750 50  0001 L CNN
	1    1200 2750
	1    0    0    -1  
$EndComp
$Comp
L cpu-rescue:BC547-Transistor_BJT-cpu-rescue Q2
U 1 1 608161CB
P 1000 2400
F 0 "Q2" H 850 2300 50  0000 L CNN
F 1 "BC547" H 750 2200 50  0000 L CNN
F 2 "Package_TO_SOT_THT:TO-92_Inline" H 1200 2325 50  0001 L CIN
F 3 "http://www.fairchildsemi.com/ds/BC/BC547.pdf" H 1000 2400 50  0001 L CNN
	1    1000 2400
	1    0    0    -1  
$EndComp
$Comp
L cpu-rescue:GND-power-cpu-rescue #PWR0103
U 1 1 60817340
P 1100 2600
F 0 "#PWR0103" H 1100 2350 50  0001 C CNN
F 1 "GND" H 1000 2500 50  0000 C CNN
F 2 "" H 1100 2600 50  0001 C CNN
F 3 "" H 1100 2600 50  0001 C CNN
	1    1100 2600
	1    0    0    -1  
$EndComp
$Comp
L cpu-rescue:GND-power-cpu-rescue #PWR0104
U 1 1 60817CD4
P 1300 2950
F 0 "#PWR0104" H 1300 2700 50  0001 C CNN
F 1 "GND" H 1150 2850 50  0000 C CNN
F 2 "" H 1300 2950 50  0001 C CNN
F 3 "" H 1300 2950 50  0001 C CNN
	1    1300 2950
	1    0    0    -1  
$EndComp
$Comp
L cpu-rescue:R-Device-cpu-rescue R2
U 1 1 60818948
P 800 2250
F 0 "R2" H 850 2300 50  0000 L CNN
F 1 "22K" H 700 2100 50  0000 L CNN
F 2 "" V 730 2250 50  0001 C CNN
F 3 "~" H 800 2250 50  0001 C CNN
	1    800  2250
	1    0    0    -1  
$EndComp
$Comp
L cpu-rescue:R-Device-cpu-rescue R1
U 1 1 6081916B
P 600 2250
F 0 "R1" H 650 2300 50  0000 L CNN
F 1 "22K" H 500 2100 50  0000 L CNN
F 2 "" V 530 2250 50  0001 C CNN
F 3 "~" H 600 2250 50  0001 C CNN
	1    600  2250
	1    0    0    -1  
$EndComp
Wire Wire Line
	600  2400 600  2750
Wire Wire Line
	600  2750 1000 2750
$Comp
L cpu-rescue:Conn_01x03-Connector_Generic-cpu-rescue J1
U 1 1 6081A7B1
P 700 1650
F 0 "J1" V 900 1700 50  0000 R CNN
F 1 "NANOLINK" V 800 1850 50  0000 R CNN
F 2 "" H 700 1650 50  0001 C CNN
F 3 "~" H 700 1650 50  0001 C CNN
	1    700  1650
	0    -1   -1   0   
$EndComp
$Comp
L cpu-rescue:GND-power-cpu-rescue #PWR0105
U 1 1 6081F6A5
P 700 1850
F 0 "#PWR0105" H 700 1600 50  0001 C CNN
F 1 "GND" H 705 1677 50  0000 C CNN
F 2 "" H 700 1850 50  0001 C CNN
F 3 "" H 700 1850 50  0001 C CNN
	1    700  1850
	1    0    0    -1  
$EndComp
Wire Wire Line
	600  1850 600  2100
Wire Wire Line
	800  1850 800  2100
Text Label 600  2100 1    50   ~ 0
SERDAT
Text Label 900  2100 1    50   ~ 0
SERCLK
Wire Wire Line
	1100 2200 1100 2000
Wire Wire Line
	1100 2200 1400 2200
Wire Wire Line
	1400 2200 1400 2350
Wire Wire Line
	1400 2350 1950 2350
$Comp
L cpu-rescue:R_Network04-Device-cpu-rescue RN1
U 1 1 60835B9A
P 1200 1800
F 0 "RN1" H 1350 2100 50  0000 R CNN
F 1 "4K7" H 1350 2000 50  0000 R CNN
F 2 "Resistor_THT:R_Array_SIP5" V 1475 1800 50  0001 C CNN
F 3 "http://www.vishay.com/docs/31509/csc.pdf" H 1200 1800 50  0001 C CNN
	1    1200 1800
	-1   0    0    -1  
$EndComp
Wire Wire Line
	1300 2550 1800 2550
Wire Wire Line
	1300 2000 1300 2550
Wire Wire Line
	1400 2000 1400 2050
Wire Wire Line
	1400 2050 1750 2050
NoConn ~ 1200 2000
NoConn ~ 2950 2850
Wire Wire Line
	2950 2650 3100 2650
Wire Wire Line
	3100 2650 3100 2750
Wire Wire Line
	3100 2750 3250 2750
Wire Wire Line
	1400 1600 1500 1600
Wire Wire Line
	1500 1600 1500 2450
Wire Wire Line
	1500 2450 1950 2450
Wire Wire Line
	2450 850  2450 950 
Wire Wire Line
	1850 1150 1950 1150
Wire Wire Line
	1850 1250 1950 1250
Wire Wire Line
	1850 1350 1950 1350
Wire Wire Line
	1850 1450 1950 1450
Wire Wire Line
	1850 1550 1950 1550
Wire Wire Line
	1850 1650 1950 1650
Wire Wire Line
	1850 1750 1950 1750
Wire Wire Line
	1850 1850 1950 1850
Entry Wire Line
	1750 1750 1850 1850
Entry Wire Line
	1750 1650 1850 1750
Entry Wire Line
	1750 1550 1850 1650
Entry Wire Line
	1750 1450 1850 1550
Entry Wire Line
	1750 1350 1850 1450
Entry Wire Line
	1750 1250 1850 1350
Entry Wire Line
	1750 1150 1850 1250
Entry Wire Line
	1750 1050 1850 1150
Text Label 1850 1850 0    50   ~ 0
D7
Text Label 1850 1750 0    50   ~ 0
D6
Text Label 1850 1650 0    50   ~ 0
D5
Text Label 1850 1550 0    50   ~ 0
D4
Text Label 1850 1450 0    50   ~ 0
D3
Text Label 1850 1350 0    50   ~ 0
D2
Text Label 1850 1250 0    50   ~ 0
D1
Text Label 1850 1150 0    50   ~ 0
D0
Text Label 2950 2650 0    50   ~ 0
A15
Text Label 2950 2550 0    50   ~ 0
A14
Text Label 2950 2450 0    50   ~ 0
A13
Text Label 2950 2350 0    50   ~ 0
A12
Text Label 2950 2250 0    50   ~ 0
A11
Text Label 2950 2150 0    50   ~ 0
A10
Text Label 2950 2050 0    50   ~ 0
A9
Text Label 2950 1950 0    50   ~ 0
A8
Text Label 2950 1850 0    50   ~ 0
A7
Text Label 2950 1750 0    50   ~ 0
A6
Text Label 2950 1650 0    50   ~ 0
A5
Text Label 2950 1550 0    50   ~ 0
A4
Text Label 2950 1450 0    50   ~ 0
A3
Text Label 2950 1350 0    50   ~ 0
A2
Text Label 2950 1250 0    50   ~ 0
A1
Text Label 2950 1150 0    50   ~ 0
A0
Entry Wire Line
	3100 2650 3200 2550
Entry Wire Line
	3100 2550 3200 2450
Entry Wire Line
	3100 2450 3200 2350
Entry Wire Line
	3100 2350 3200 2250
Entry Wire Line
	3100 2250 3200 2150
Entry Wire Line
	3100 2150 3200 2050
Entry Wire Line
	3100 2050 3200 1950
Entry Wire Line
	3100 1950 3200 1850
Entry Wire Line
	3100 1850 3200 1750
Entry Wire Line
	3100 1750 3200 1650
Entry Wire Line
	3100 1650 3200 1550
Entry Wire Line
	3100 1550 3200 1450
Entry Wire Line
	3100 1450 3200 1350
Entry Wire Line
	3100 1350 3200 1250
Entry Wire Line
	3100 1250 3200 1150
Entry Wire Line
	3100 1150 3200 1050
Wire Wire Line
	1950 2250 1600 2250
Wire Wire Line
	1600 2250 1600 1400
Connection ~ 2450 850 
Wire Wire Line
	1850 3450 1850 2150
$Comp
L cpu-rescue:MOS6502-CPU-cpu-rescue U1
U 1 1 60743819
P 2450 2350
F 0 "U1" H 2200 3800 50  0000 C CNN
F 1 "65SC02" H 2200 3700 50  0000 C CNN
F 2 "Package_DIP:DIP-40_W15.24mm" H 2450 850 50  0001 C CNN
F 3 "http://archive.6502.org/datasheets/rockwell_r650x_r651x.pdf" H 2450 2350 50  0001 C CNN
	1    2450 2350
	1    0    0    -1  
$EndComp
$Comp
L cpu-rescue:R-Device-cpu-rescue R3
U 1 1 608C167A
P 1250 850
F 0 "R3" V 1043 850 50  0000 C CNN
F 1 "1K" V 1134 850 50  0000 C CNN
F 2 "" V 1180 850 50  0001 C CNN
F 3 "~" H 1250 850 50  0001 C CNN
	1    1250 850 
	0    1    1    0   
$EndComp
Wire Wire Line
	1400 850  1400 1600
$Comp
L cpu-rescue:SW_Push-Switch-cpu-rescue SW1
U 1 1 608D6A0F
P 900 850
F 0 "SW1" H 900 1135 50  0000 C CNN
F 1 "RESET" H 900 1044 50  0000 C CNN
F 2 "" H 900 1050 50  0001 C CNN
F 3 "~" H 900 1050 50  0001 C CNN
	1    900  850 
	1    0    0    -1  
$EndComp
$Comp
L cpu-rescue:C-Device-cpu-rescue C1
U 1 1 608D6E72
P 900 1000
F 0 "C1" V 1050 1000 50  0000 C CNN
F 1 "100n" V 1150 1000 50  0000 C CNN
F 2 "" H 938 850 50  0001 C CNN
F 3 "~" H 900 1000 50  0001 C CNN
	1    900  1000
	0    1    1    0   
$EndComp
Wire Wire Line
	1100 850  1100 1000
Wire Wire Line
	1100 1000 1050 1000
Wire Wire Line
	700  850  700  1000
Wire Wire Line
	700  1000 750  1000
Wire Wire Line
	1600 1400 1100 1400
Wire Wire Line
	1100 1400 1100 1000
Connection ~ 1100 1000
Connection ~ 1800 2550
Wire Wire Line
	1800 2550 1950 2550
Wire Wire Line
	1800 2550 1800 4450
$Comp
L cpu-rescue:D-Device-cpu-rescue D1
U 1 1 60908C99
P 2450 4600
F 0 "D1" V 2450 4850 50  0000 R CNN
F 1 "1N4148" V 2350 4950 50  0000 R CNN
F 2 "" H 2450 4600 50  0001 C CNN
F 3 "~" H 2450 4600 50  0001 C CNN
	1    2450 4600
	0    -1   -1   0   
$EndComp
Wire Wire Line
	1800 4450 2450 4450
Wire Wire Line
	2450 4750 2450 4950
Wire Wire Line
	4450 1150 4550 1150
Wire Wire Line
	4450 1250 4550 1250
Wire Wire Line
	4450 1350 4550 1350
Wire Wire Line
	4450 1450 4550 1450
Wire Wire Line
	4450 1550 4550 1550
Wire Wire Line
	4450 1650 4550 1650
Wire Wire Line
	4450 1750 4550 1750
Wire Wire Line
	4450 1850 4550 1850
Text Label 4450 1150 0    50   ~ 0
D0
Text Label 4450 1250 0    50   ~ 0
D1
Text Label 4450 1350 0    50   ~ 0
D2
Text Label 4450 1450 0    50   ~ 0
D3
Text Label 4450 1550 0    50   ~ 0
D4
Text Label 4450 1650 0    50   ~ 0
D5
Text Label 4450 1750 0    50   ~ 0
D6
Text Label 4450 1850 0    50   ~ 0
D7
Entry Wire Line
	4550 1850 4650 1750
Entry Wire Line
	4550 1750 4650 1650
Entry Wire Line
	4550 1650 4650 1550
Entry Wire Line
	4550 1550 4650 1450
Entry Wire Line
	4550 1450 4650 1350
Entry Wire Line
	4550 1350 4650 1250
Entry Wire Line
	4550 1250 4650 1150
Entry Wire Line
	4550 1150 4650 1050
Wire Wire Line
	4850 1150 4750 1150
Wire Wire Line
	4850 1250 4750 1250
Wire Wire Line
	4850 1350 4750 1350
Wire Wire Line
	4850 1450 4750 1450
Wire Wire Line
	4850 1550 4750 1550
Wire Wire Line
	4850 1650 4750 1650
Wire Wire Line
	4850 1750 4750 1750
Wire Wire Line
	4850 1850 4750 1850
Text Label 4850 1150 2    50   ~ 0
D0
Text Label 4850 1250 2    50   ~ 0
D1
Text Label 4850 1350 2    50   ~ 0
D2
Text Label 4850 1450 2    50   ~ 0
D3
Text Label 4850 1550 2    50   ~ 0
D4
Text Label 4850 1650 2    50   ~ 0
D5
Text Label 4850 1750 2    50   ~ 0
D6
Text Label 4850 1850 2    50   ~ 0
D7
Entry Wire Line
	4750 1850 4650 1750
Entry Wire Line
	4750 1750 4650 1650
Entry Wire Line
	4750 1650 4650 1550
Entry Wire Line
	4750 1550 4650 1450
Entry Wire Line
	4750 1450 4650 1350
Entry Wire Line
	4750 1350 4650 1250
Entry Wire Line
	4750 1250 4650 1150
Entry Wire Line
	4750 1150 4650 1050
Wire Wire Line
	5250 850  5250 950 
Wire Bus Line
	4650 800  1750 800 
Wire Bus Line
	3200 750  5900 750 
Text Label 5650 2450 0    50   ~ 0
A13
Text Label 5650 2350 0    50   ~ 0
A12
Text Label 5650 2250 0    50   ~ 0
A11
Text Label 5650 2150 0    50   ~ 0
A10
Text Label 5650 2050 0    50   ~ 0
A9
Text Label 5650 1950 0    50   ~ 0
A8
Text Label 5650 1850 0    50   ~ 0
A7
Text Label 5650 1750 0    50   ~ 0
A6
Text Label 5650 1650 0    50   ~ 0
A5
Text Label 5650 1550 0    50   ~ 0
A4
Text Label 5650 1450 0    50   ~ 0
A3
Text Label 5650 1350 0    50   ~ 0
A2
Text Label 5650 1250 0    50   ~ 0
A1
Text Label 5650 1150 0    50   ~ 0
A0
Entry Wire Line
	5800 2450 5900 2350
Entry Wire Line
	5800 2350 5900 2250
Entry Wire Line
	5800 2250 5900 2150
Entry Wire Line
	5800 2150 5900 2050
Entry Wire Line
	5800 2050 5900 1950
Entry Wire Line
	5800 1950 5900 1850
Entry Wire Line
	5800 1850 5900 1750
Entry Wire Line
	5800 1750 5900 1650
Entry Wire Line
	5800 1650 5900 1550
Entry Wire Line
	5800 1550 5900 1450
Entry Wire Line
	5800 1450 5900 1350
Entry Wire Line
	5800 1350 5900 1250
Entry Wire Line
	5800 1250 5900 1150
Entry Wire Line
	5800 1150 5900 1050
Wire Wire Line
	5650 1150 5800 1150
Wire Wire Line
	5650 1250 5800 1250
Wire Wire Line
	5650 1350 5800 1350
Wire Wire Line
	5650 1450 5800 1450
Wire Wire Line
	5650 1550 5800 1550
Wire Wire Line
	5650 1650 5800 1650
Wire Wire Line
	5650 1750 5800 1750
Wire Wire Line
	5650 1850 5800 1850
Wire Wire Line
	5650 1950 5800 1950
Wire Wire Line
	5650 2050 5800 2050
Wire Wire Line
	5650 2150 5800 2150
Wire Wire Line
	5650 2250 5800 2250
Wire Wire Line
	3850 3750 3850 3250
Wire Wire Line
	3850 3250 5250 3250
Wire Wire Line
	5250 3250 5250 3150
$Comp
L cpu-rescue:GND-power-cpu-rescue #PWR0108
U 1 1 60A697B0
P 2450 3750
F 0 "#PWR0108" H 2450 3500 50  0001 C CNN
F 1 "GND" H 2455 3577 50  0000 C CNN
F 2 "" H 2450 3750 50  0001 C CNN
F 3 "" H 2450 3750 50  0001 C CNN
	1    2450 3750
	1    0    0    -1  
$EndComp
$Comp
L cpu-rescue:PWR_FLAG-power-cpu-rescue #FLG0102
U 1 1 60A6E03B
P 2950 3750
F 0 "#FLG0102" H 2950 3825 50  0001 C CNN
F 1 "PWR_FLAG" H 2750 3700 50  0000 C CNN
F 2 "" H 2950 3750 50  0001 C CNN
F 3 "~" H 2950 3750 50  0001 C CNN
	1    2950 3750
	1    0    0    -1  
$EndComp
Wire Wire Line
	5650 2750 5650 2650
Wire Wire Line
	5650 2650 5750 2650
$Comp
L cpu-rescue:+5V-power-cpu-rescue #PWR0109
U 1 1 60B43304
P 5750 2650
F 0 "#PWR0109" H 5750 2500 50  0001 C CNN
F 1 "+5V" H 5650 2750 50  0000 C CNN
F 2 "" H 5750 2650 50  0001 C CNN
F 3 "" H 5750 2650 50  0001 C CNN
	1    5750 2650
	1    0    0    -1  
$EndComp
Wire Wire Line
	5650 2950 5650 3300
Wire Wire Line
	5650 3300 4350 3300
Wire Wire Line
	3200 3300 3200 2850
Wire Wire Line
	3200 2850 3250 2850
$Comp
L cpu-rescue:GND-power-cpu-rescue #PWR0110
U 1 1 60B50324
P 1050 5650
F 0 "#PWR0110" H 1050 5400 50  0001 C CNN
F 1 "GND" H 1055 5477 50  0000 C CNN
F 2 "" H 1050 5650 50  0001 C CNN
F 3 "" H 1050 5650 50  0001 C CNN
	1    1050 5650
	1    0    0    -1  
$EndComp
$Comp
L cpu-rescue:Conn_01x09-Connector_Generic-cpu-rescue J2
U 1 1 60B8046B
P 9650 6000
F 0 "J2" H 9730 6042 50  0000 L CNN
F 1 "IO9 INPUT" H 9730 5951 50  0000 L CNN
F 2 "" H 9650 6000 50  0001 C CNN
F 3 "~" H 9650 6000 50  0001 C CNN
	1    9650 6000
	0    1    1    0   
$EndComp
Wire Wire Line
	10050 5700 10050 5800
Wire Wire Line
	9950 5700 9950 5800
Wire Wire Line
	9850 5700 9850 5800
Wire Wire Line
	9750 5700 9750 5800
Wire Wire Line
	9650 5700 9650 5800
Wire Wire Line
	9550 5700 9550 5800
Wire Wire Line
	9450 5700 9450 5800
Wire Wire Line
	9350 5700 9350 5800
$Comp
L cpu-rescue:GND-power-cpu-rescue #PWR0111
U 1 1 60BBE2B7
P 8750 5200
F 0 "#PWR0111" H 8750 4950 50  0001 C CNN
F 1 "GND" H 8755 5027 50  0000 C CNN
F 2 "" H 8750 5200 50  0001 C CNN
F 3 "" H 8750 5200 50  0001 C CNN
	1    8750 5200
	0    1    1    0   
$EndComp
Wire Wire Line
	8750 5200 8750 5800
Wire Wire Line
	8750 5800 9250 5800
Wire Wire Line
	9150 5700 9150 5750
Wire Wire Line
	9150 5750 10350 5750
Wire Wire Line
	10350 5750 10350 5200
$Comp
L cpu-rescue:+5V-power-cpu-rescue #PWR0112
U 1 1 60BD1E66
P 10350 5750
F 0 "#PWR0112" H 10350 5600 50  0001 C CNN
F 1 "+5V" H 10365 5923 50  0000 C CNN
F 2 "" H 10350 5750 50  0001 C CNN
F 3 "" H 10350 5750 50  0001 C CNN
	1    10350 5750
	0    1    1    0   
$EndComp
Text Label 9650 5700 3    50   ~ 0
DI0
Text Label 9550 5700 3    50   ~ 0
DI1
Text Label 9450 5700 3    50   ~ 0
DI2
Text Label 9350 5700 3    50   ~ 0
DI3
Wire Wire Line
	1750 2050 1750 4350
Wire Wire Line
	1750 4350 3250 4350
Connection ~ 1750 2050
Wire Wire Line
	1750 2050 1950 2050
Wire Wire Line
	2450 850  5250 850 
Wire Wire Line
	1400 850  1550 850 
Wire Wire Line
	1400 3750 3850 3750
Wire Wire Line
	3100 2750 3100 3600
Wire Wire Line
	3100 4050 3250 4050
Connection ~ 3100 2750
Wire Wire Line
	3150 2550 3150 3700
Wire Wire Line
	3150 4150 3250 4150
Connection ~ 3150 2550
Wire Wire Line
	4800 3700 3150 3700
Connection ~ 3150 3700
Wire Wire Line
	3150 3700 3150 4150
Wire Wire Line
	4800 3600 3100 3600
Connection ~ 3100 3600
Wire Wire Line
	3100 3600 3100 4050
Wire Wire Line
	5800 3900 5850 3900
Wire Wire Line
	5850 3900 5850 2850
Wire Wire Line
	5850 2850 5650 2850
Wire Wire Line
	1900 3800 1900 4300
Wire Wire Line
	1900 4300 2950 4300
Wire Wire Line
	2950 4300 2950 4900
Wire Wire Line
	2950 4900 3250 4900
Connection ~ 1900 3800
Wire Wire Line
	2950 3050 3000 3050
Wire Wire Line
	3000 3050 3000 4800
Wire Wire Line
	3000 4800 3250 4800
Wire Wire Line
	4250 5100 4350 5100
Wire Wire Line
	4350 5100 4350 3300
Connection ~ 4350 3300
Wire Wire Line
	4350 3300 3200 3300
Wire Wire Line
	3250 2950 3250 3350
Wire Wire Line
	3250 3350 4300 3350
Wire Wire Line
	4300 3350 4300 4900
Wire Wire Line
	4250 4900 4300 4900
NoConn ~ 4250 4800
NoConn ~ 4250 5000
$Comp
L cpu-rescue:GND-power-cpu-rescue #PWR0114
U 1 1 6082DCA0
P 3250 5100
F 0 "#PWR0114" H 3250 4850 50  0001 C CNN
F 1 "GND-power" H 3255 4927 50  0000 C CNN
F 2 "" H 3250 5100 50  0001 C CNN
F 3 "" H 3250 5100 50  0001 C CNN
	1    3250 5100
	1    0    0    -1  
$EndComp
Connection ~ 8750 5200
Connection ~ 10350 5750
Wire Wire Line
	5800 3800 5900 3800
Wire Wire Line
	5900 3800 5900 4300
NoConn ~ 5800 3600
NoConn ~ 5800 3700
NoConn ~ 4250 4050
NoConn ~ 4250 4150
NoConn ~ 4800 4300
NoConn ~ 4800 4400
NoConn ~ 4800 4500
Wire Wire Line
	5800 4300 5900 4300
Wire Wire Line
	4250 4350 4400 4350
Wire Wire Line
	4400 4350 4400 5350
Wire Wire Line
	4400 5350 4800 5350
NoConn ~ 5800 5250
NoConn ~ 5800 5350
NoConn ~ 5800 5550
Wire Wire Line
	4300 5550 4800 5550
Wire Wire Line
	4300 4900 4300 5550
Connection ~ 4300 4900
Wire Wire Line
	5800 4600 5850 4600
Wire Wire Line
	5850 4600 5850 6000
Wire Wire Line
	5900 6100 5900 4500
Wire Wire Line
	5900 4500 5800 4500
Wire Wire Line
	5900 6100 5850 6100
Wire Wire Line
	4250 4250 4450 4250
Wire Wire Line
	4450 4250 4450 6450
Wire Wire Line
	5850 6450 5850 6300
Wire Wire Line
	4450 6450 5850 6450
Wire Wire Line
	5950 4400 5850 4400
Wire Wire Line
	5850 4400 5850 4600
Connection ~ 5850 4600
Wire Wire Line
	6000 4500 5900 4500
Connection ~ 5900 4500
Wire Wire Line
	5950 2450 5950 4400
Wire Wire Line
	6000 2350 6000 4500
Text Label 4600 4650 0    50   ~ 0
~IO8U
Text Label 4650 6000 0    50   ~ 0
~IO8Q
Text Label 4650 6100 0    50   ~ 0
~IO9Q
Text Label 4650 6200 0    50   ~ 0
~IOAQ
Text Label 4650 6300 0    50   ~ 0
~IOBQ
Text Label 5950 5450 0    50   ~ 0
~LTC
Text Label 1700 4550 0    50   ~ 0
IEN
Text Label 7250 4900 0    50   ~ 0
IEN
Text Label 6400 5000 0    50   ~ 0
~IOAQ
Text Label 6400 4150 0    50   ~ 0
~IOBQ
Text Label 6450 4050 0    50   ~ 0
D0
Text Label 6450 4900 0    50   ~ 0
A0
Text Label 7300 5250 0    50   ~ 0
~RES
Text Label 1100 1400 0    50   ~ 0
~RES
NoConn ~ 7200 4200
Text Label 7250 4050 0    50   ~ 0
BUZ
Wire Wire Line
	6900 4650 7250 4650
Wire Wire Line
	7250 4650 7250 3800
Wire Wire Line
	7250 3800 6900 3800
Wire Wire Line
	6900 5250 7300 5250
Wire Wire Line
	7300 5250 7300 4400
Wire Wire Line
	7300 4400 6900 4400
Wire Wire Line
	6400 4150 6600 4150
Wire Wire Line
	6600 4150 6600 4100
Wire Wire Line
	6400 5000 6600 5000
Wire Wire Line
	6600 5000 6600 4950
Wire Wire Line
	6450 4900 6600 4900
Wire Wire Line
	6600 4900 6600 4850
Wire Wire Line
	6450 4050 6600 4050
Wire Wire Line
	6600 4050 6600 4000
Wire Wire Line
	4850 6300 4650 6300
Wire Wire Line
	4850 6200 4650 6200
Wire Wire Line
	1850 4550 1700 4550
Wire Wire Line
	7200 4850 7200 4900
Wire Wire Line
	7200 4900 7250 4900
Text Label 4200 6800 0    50   ~ 0
~LTC
Wire Wire Line
	4150 6750 4150 6800
Wire Wire Line
	4150 6800 4200 6800
Wire Wire Line
	5800 5450 5950 5450
Wire Wire Line
	3650 7150 4150 7150
Wire Wire Line
	4150 7150 4150 6850
Text Label 9050 5700 3    50   ~ 0
~IO9Q
Wire Wire Line
	4850 6100 4650 6100
Wire Bus Line
	3200 750  3200 2550
$Comp
L power:+5V #PWR0106
U 1 1 6078B50B
P 1400 850
F 0 "#PWR0106" H 1400 700 50  0001 C CNN
F 1 "+5V" H 1415 1023 50  0000 C CNN
F 2 "" H 1400 850 50  0001 C CNN
F 3 "" H 1400 850 50  0001 C CNN
	1    1400 850 
	1    0    0    -1  
$EndComp
Connection ~ 1400 850 
$Comp
L power:PWR_FLAG #FLG0101
U 1 1 6079A47E
P 1550 850
F 0 "#FLG0101" H 1550 925 50  0001 C CNN
F 1 "PWR_FLAG" H 1400 750 50  0000 C CNN
F 2 "" H 1550 850 50  0001 C CNN
F 3 "~" H 1550 850 50  0001 C CNN
	1    1550 850 
	1    0    0    -1  
$EndComp
Connection ~ 1550 850 
Wire Wire Line
	1550 850  2450 850 
$Comp
L power:GND #PWR0107
U 1 1 607ACFC1
P 700 1000
F 0 "#PWR0107" H 700 750 50  0001 C CNN
F 1 "GND" H 705 827 50  0000 C CNN
F 2 "" H 700 1000 50  0001 C CNN
F 3 "" H 700 1000 50  0001 C CNN
	1    700  1000
	1    0    0    -1  
$EndComp
Connection ~ 700  1000
$Comp
L power:+5V #PWR0115
U 1 1 607D5C5D
P 3650 5550
F 0 "#PWR0115" H 3650 5400 50  0001 C CNN
F 1 "+5V" H 3665 5723 50  0000 C CNN
F 2 "" H 3650 5550 50  0001 C CNN
F 3 "" H 3650 5550 50  0001 C CNN
	1    3650 5550
	1    0    0    -1  
$EndComp
$Comp
L power:+5V #PWR0116
U 1 1 607D60E0
P 4800 5250
F 0 "#PWR0116" H 4800 5100 50  0001 C CNN
F 1 "+5V" H 4815 5423 50  0000 C CNN
F 2 "" H 4800 5250 50  0001 C CNN
F 3 "" H 4800 5250 50  0001 C CNN
	1    4800 5250
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR0117
U 1 1 607E5943
P 3650 7150
F 0 "#PWR0117" H 3650 6900 50  0001 C CNN
F 1 "GND" H 3655 6977 50  0000 C CNN
F 2 "" H 3650 7150 50  0001 C CNN
F 3 "" H 3650 7150 50  0001 C CNN
	1    3650 7150
	1    0    0    -1  
$EndComp
Connection ~ 3650 7150
$Comp
L power:GND #PWR0118
U 1 1 607F8FF4
P 7800 5050
F 0 "#PWR0118" H 7800 4800 50  0001 C CNN
F 1 "GND" H 7805 4877 50  0000 C CNN
F 2 "" H 7800 5050 50  0001 C CNN
F 3 "" H 7800 5050 50  0001 C CNN
	1    7800 5050
	1    0    0    -1  
$EndComp
$Comp
L power:+5V #PWR0119
U 1 1 60809B69
P 7250 3800
F 0 "#PWR0119" H 7250 3650 50  0001 C CNN
F 1 "+5V" H 7265 3973 50  0000 C CNN
F 2 "" H 7250 3800 50  0001 C CNN
F 3 "" H 7250 3800 50  0001 C CNN
	1    7250 3800
	1    0    0    -1  
$EndComp
Connection ~ 7250 3800
$Comp
L power:GND #PWR0113
U 1 1 6082C3CC
P 4800 3900
F 0 "#PWR0113" H 4800 3650 50  0001 C CNN
F 1 "GND" H 4805 3727 50  0000 C CNN
F 2 "" H 4800 3900 50  0001 C CNN
F 3 "" H 4800 3900 50  0001 C CNN
	1    4800 3900
	1    0    0    -1  
$EndComp
Connection ~ 1100 2200
Connection ~ 1300 2550
Wire Wire Line
	5650 2450 5950 2450
Wire Wire Line
	2950 2550 3150 2550
Wire Wire Line
	3150 2550 3250 2550
Wire Wire Line
	2950 2450 3250 2450
Wire Wire Line
	2950 2350 3250 2350
Wire Wire Line
	2950 2250 3250 2250
Wire Wire Line
	2950 2150 3250 2150
Wire Wire Line
	2950 2050 3250 2050
Wire Wire Line
	2950 1950 3250 1950
Wire Wire Line
	2950 1850 3250 1850
Wire Wire Line
	2950 1750 3250 1750
Wire Wire Line
	2950 1650 3250 1650
Wire Wire Line
	2950 1550 3250 1550
Wire Wire Line
	2950 1450 3250 1450
Wire Wire Line
	2950 1350 3250 1350
Wire Wire Line
	2950 1250 3250 1250
Wire Wire Line
	2950 1150 3250 1150
Wire Wire Line
	5650 2350 6000 2350
Wire Bus Line
	1750 800  1750 1750
Wire Bus Line
	4650 800  4650 7500
Wire Bus Line
	5900 750  5900 2350
$EndSCHEMATC
