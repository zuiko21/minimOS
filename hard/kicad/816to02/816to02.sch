EESchema Schematic File Version 4
LIBS:816to02-cache
EELAYER 29 0
EELAYER END
$Descr A4 11693 8268
encoding utf-8
Sheet 1 1
Title "65C816 CPU to 65C02 socket adapter"
Date "2023-06-25"
Rev "v1"
Comp "@zuiko21"
Comment1 ""
Comment2 ""
Comment3 ""
Comment4 ""
$EndDescr
$Comp
L w65c816s:W65C816S U2
U 1 1 6498B2AC
P 4150 2550
F 0 "U2" H 3950 3900 50  0000 C CNN
F 1 "65C816" H 4350 3900 50  0000 C CNN
F 2 "Package_DIP:DIP-40_W15.24mm_Socket" H 4150 1050 50  0001 C CNN
F 3 "https://www.westerndesigncenter.com/wdc/datasheets/w65c816s.pdf" H 4150 2550 50  0001 C CNN
	1    4150 2550
	1    0    0    -1  
$EndComp
$Comp
L w65c02s:W65C02S U1
U 1 1 6498B4AA
P 1550 2550
F 0 "U1" H 1800 3900 50  0000 C CNN
F 1 "65C02 SOCKET" H 1200 3900 50  0000 C CNN
F 2 "Package_DIP:DIP-40_W15.24mm_Socket" H 1550 1050 50  0001 C CNN
F 3 "https://www.westerndesigncenter.com/wdc/documentation/w65c02s.pdf" H 1550 2550 50  0001 C CNN
	1    1550 2550
	-1   0    0    -1  
$EndComp
$Comp
L 74xx:74HC245 U3
U 1 1 6498FAD1
P 2850 1850
F 0 "U3" H 2650 2500 50  0000 C CNN
F 1 "74HC245" H 3050 2500 50  0000 C CNN
F 2 "Package_DIP:DIP-20_W7.62mm" H 2850 1850 50  0001 C CNN
F 3 "http://www.ti.com/lit/gpn/sn74HC245" H 2850 1850 50  0001 C CNN
	1    2850 1850
	1    0    0    -1  
$EndComp
$Comp
L 74xx:74HC00 U4
U 1 1 64993F25
P 1850 4900
F 0 "U4" H 1850 4583 50  0000 C CNN
F 1 "74HC00" H 1850 4674 50  0000 C CNN
F 2 "Package_DIP:DIP-14_W7.62mm" H 1850 4900 50  0001 C CNN
F 3 "http://www.ti.com/lit/gpn/sn74hc00" H 1850 4900 50  0001 C CNN
	1    1850 4900
	1    0    0    1   
$EndComp
$Comp
L 74xx:74HC00 U4
U 2 1 64994CAF
P 2750 5000
F 0 "U4" H 2750 5325 50  0000 C CNN
F 1 "74HC00" H 2750 5234 50  0000 C CNN
F 2 "Package_DIP:DIP-14_W7.62mm" H 2750 5000 50  0001 C CNN
F 3 "http://www.ti.com/lit/gpn/sn74hc00" H 2750 5000 50  0001 C CNN
	2    2750 5000
	1    0    0    -1  
$EndComp
$Comp
L 74xx:74HC00 U4
U 3 1 64995164
P 1900 5600
F 0 "U4" H 1900 5925 50  0000 C CNN
F 1 "74HC00" H 1900 5834 50  0000 C CNN
F 2 "Package_DIP:DIP-14_W7.62mm" H 1900 5600 50  0001 C CNN
F 3 "http://www.ti.com/lit/gpn/sn74hc00" H 1900 5600 50  0001 C CNN
	3    1900 5600
	-1   0    0    -1  
$EndComp
$Comp
L 74xx:74HC00 U4
U 4 1 64996D36
P 2800 5700
F 0 "U4" H 2800 6025 50  0000 C CNN
F 1 "74HC00" H 2800 5934 50  0000 C CNN
F 2 "Package_DIP:DIP-14_W7.62mm" H 2800 5700 50  0001 C CNN
F 3 "http://www.ti.com/lit/gpn/sn74hc00" H 2800 5700 50  0001 C CNN
	4    2800 5700
	-1   0    0    -1  
$EndComp
$Comp
L 74xx:74HC00 U4
U 5 1 64999494
P 950 6550
F 0 "U4" H 1180 6596 50  0000 L CNN
F 1 "74HC00" H 1180 6505 50  0000 L CNN
F 2 "Package_DIP:DIP-14_W7.62mm" H 950 6550 50  0001 C CNN
F 3 "http://www.ti.com/lit/gpn/sn74hc00" H 950 6550 50  0001 C CNN
	5    950  6550
	1    0    0    -1  
$EndComp
Text Label 1050 1350 2    50   ~ 0
A0
Text Label 1050 1450 2    50   ~ 0
A1
Text Label 1050 1550 2    50   ~ 0
A2
Text Label 1050 1650 2    50   ~ 0
A3
Text Label 1050 1750 2    50   ~ 0
A4
Text Label 1050 1850 2    50   ~ 0
A5
Text Label 1050 1950 2    50   ~ 0
A6
Text Label 1050 2050 2    50   ~ 0
A7
Text Label 1050 2150 2    50   ~ 0
A8
Text Label 1050 2250 2    50   ~ 0
A9
Text Label 1050 2350 2    50   ~ 0
A10
Text Label 1050 2450 2    50   ~ 0
A11
Text Label 1050 2550 2    50   ~ 0
A12
Text Label 1050 2650 2    50   ~ 0
A13
Text Label 1050 2750 2    50   ~ 0
A14
Text Label 1050 2850 2    50   ~ 0
A15
Text Label 4650 1350 0    50   ~ 0
A0
Text Label 4650 1450 0    50   ~ 0
A1
Text Label 4650 1550 0    50   ~ 0
A2
Text Label 4650 1650 0    50   ~ 0
A3
Text Label 4650 1750 0    50   ~ 0
A4
Text Label 4650 1850 0    50   ~ 0
A5
Text Label 4650 1950 0    50   ~ 0
A6
Text Label 4650 2050 0    50   ~ 0
A7
Text Label 4650 2150 0    50   ~ 0
A8
Text Label 4650 2250 0    50   ~ 0
A9
Text Label 4650 2350 0    50   ~ 0
A10
Text Label 4650 2450 0    50   ~ 0
A11
Text Label 4650 2550 0    50   ~ 0
A12
Text Label 4650 2650 0    50   ~ 0
A13
Text Label 4650 2750 0    50   ~ 0
A14
Text Label 4650 2850 0    50   ~ 0
A15
Wire Wire Line
	1050 1350 900  1350
Entry Wire Line
	800  1250 900  1350
Wire Wire Line
	1050 1450 900  1450
Entry Wire Line
	800  1350 900  1450
Wire Wire Line
	1050 1550 900  1550
Entry Wire Line
	800  1450 900  1550
Wire Wire Line
	1050 1650 900  1650
Entry Wire Line
	800  1550 900  1650
Wire Wire Line
	1050 1750 900  1750
Entry Wire Line
	800  1650 900  1750
Wire Wire Line
	1050 1850 900  1850
Entry Wire Line
	800  1750 900  1850
Wire Wire Line
	1050 1950 900  1950
Entry Wire Line
	800  1850 900  1950
Wire Wire Line
	1050 2050 900  2050
Entry Wire Line
	800  1950 900  2050
Wire Wire Line
	1050 2150 900  2150
Entry Wire Line
	800  2050 900  2150
Wire Wire Line
	1050 2250 900  2250
Entry Wire Line
	800  2150 900  2250
Wire Wire Line
	1050 2350 900  2350
Entry Wire Line
	800  2250 900  2350
Wire Wire Line
	1050 2450 900  2450
Entry Wire Line
	800  2350 900  2450
Wire Wire Line
	1050 2550 900  2550
Entry Wire Line
	800  2450 900  2550
Wire Wire Line
	1050 2650 900  2650
Entry Wire Line
	800  2550 900  2650
Wire Wire Line
	1050 2750 900  2750
Entry Wire Line
	800  2650 900  2750
Wire Wire Line
	1050 2850 900  2850
Entry Wire Line
	800  2750 900  2850
Wire Wire Line
	4650 1350 4800 1350
Entry Wire Line
	4900 1250 4800 1350
Wire Wire Line
	4650 1450 4800 1450
Entry Wire Line
	4900 1350 4800 1450
Wire Wire Line
	4650 1550 4800 1550
Entry Wire Line
	4900 1450 4800 1550
Wire Wire Line
	4650 1650 4800 1650
Entry Wire Line
	4900 1550 4800 1650
Wire Wire Line
	4650 1750 4800 1750
Entry Wire Line
	4900 1650 4800 1750
Wire Wire Line
	4650 1850 4800 1850
Entry Wire Line
	4900 1750 4800 1850
Wire Wire Line
	4650 1950 4800 1950
Entry Wire Line
	4900 1850 4800 1950
Wire Wire Line
	4650 2050 4800 2050
Entry Wire Line
	4900 1950 4800 2050
Wire Wire Line
	4650 2150 4800 2150
Entry Wire Line
	4900 2050 4800 2150
Wire Wire Line
	4650 2250 4800 2250
Entry Wire Line
	4900 2150 4800 2250
Wire Wire Line
	4650 2350 4800 2350
Entry Wire Line
	4900 2250 4800 2350
Wire Wire Line
	4650 2450 4800 2450
Entry Wire Line
	4900 2350 4800 2450
Wire Wire Line
	4650 2550 4800 2550
Entry Wire Line
	4900 2450 4800 2550
Wire Wire Line
	4650 2650 4800 2650
Entry Wire Line
	4900 2550 4800 2650
Wire Wire Line
	4650 2750 4800 2750
Entry Wire Line
	4900 2650 4800 2750
Wire Wire Line
	4650 2850 4800 2850
Entry Wire Line
	4900 2750 4800 2850
Wire Bus Line
	800  600  4900 600 
Wire Wire Line
	2050 1350 2350 1350
Wire Wire Line
	2050 1450 2350 1450
Wire Wire Line
	2050 1550 2350 1550
Wire Wire Line
	2050 1650 2350 1650
Wire Wire Line
	2050 1750 2350 1750
Wire Wire Line
	2050 1850 2350 1850
Wire Wire Line
	2050 1950 2350 1950
Wire Wire Line
	2050 2050 2350 2050
Wire Wire Line
	3350 1350 3650 1350
Wire Wire Line
	3350 1450 3650 1450
Wire Wire Line
	3350 1550 3650 1550
Wire Wire Line
	3350 1650 3650 1650
Wire Wire Line
	3350 1750 3650 1750
Wire Wire Line
	3350 1850 3650 1850
Wire Wire Line
	3350 1950 3650 1950
Wire Wire Line
	3350 2050 3650 2050
Text Label 2150 1350 0    50   ~ 0
D0
Text Label 2150 1450 0    50   ~ 0
D1
Text Label 2150 1550 0    50   ~ 0
D2
Text Label 2150 1650 0    50   ~ 0
D3
Text Label 2150 1750 0    50   ~ 0
D4
Text Label 2150 1850 0    50   ~ 0
D5
Text Label 2150 1950 0    50   ~ 0
D6
Text Label 2150 2050 0    50   ~ 0
D7
Text Label 3400 1350 0    50   ~ 0
BD0
Text Label 3400 1450 0    50   ~ 0
BD1
Text Label 3400 1550 0    50   ~ 0
BD2
Text Label 3400 1650 0    50   ~ 0
BD3
Text Label 3400 1750 0    50   ~ 0
BD4
Text Label 3400 1850 0    50   ~ 0
BD5
Text Label 3400 1950 0    50   ~ 0
BD6
Text Label 3400 2050 0    50   ~ 0
BD7
$Comp
L power:+5V #PWR0101
U 1 1 649DD8B2
P 1550 5100
F 0 "#PWR0101" H 1550 4950 50  0001 C CNN
F 1 "+5V" V 1600 5250 50  0000 C CNN
F 2 "" H 1550 5100 50  0001 C CNN
F 3 "" H 1550 5100 50  0001 C CNN
	1    1550 5100
	0    -1   -1   0   
$EndComp
Text Label 1750 4500 2    50   ~ 0
PHI0
Wire Wire Line
	2150 4900 2450 4900
Wire Wire Line
	2500 5700 2200 5700
Text Label 2250 4900 0    50   ~ 0
PHI1
Text Label 3050 5000 0    50   ~ 0
PHI2
Text Label 1600 5600 2    50   ~ 0
SYNC
Text Label 2400 5700 2    50   ~ 0
~SYNC
Text Label 3100 5800 0    50   ~ 0
VDA
Text Label 3100 5600 0    50   ~ 0
VPA
Text Label 4650 3050 0    50   ~ 0
VDA
Text Label 4650 3150 0    50   ~ 0
VPA
Wire Wire Line
	2050 2250 2150 2250
Wire Wire Line
	2150 2250 2150 2350
Wire Wire Line
	2150 2350 2350 2350
NoConn ~ 2050 3450
Text Label 2350 4350 0    50   ~ 0
~ML
Text Label 2350 4250 0    50   ~ 0
R~W
NoConn ~ 3650 3450
Text Label 3200 3050 0    50   ~ 0
PHI0
Wire Wire Line
	2050 2450 3650 2450
Wire Wire Line
	2050 2550 3650 2550
Wire Wire Line
	2050 2650 2700 2650
Wire Wire Line
	2700 2650 2700 2700
Wire Wire Line
	3000 2700 3000 2650
Wire Wire Line
	3000 2650 3650 2650
Wire Wire Line
	2050 2750 3650 2750
Wire Wire Line
	2050 2950 3650 2950
Text Label 3200 2950 0    50   ~ 0
BE
Text Label 3200 2750 0    50   ~ 0
~IRQ
Text Label 3200 2650 0    50   ~ 0
RDY
Text Label 3200 2550 0    50   ~ 0
~NMI
Text Label 3200 2450 0    50   ~ 0
~RST
Wire Wire Line
	1650 3950 4050 3950
Text Label 3200 3950 0    50   ~ 0
~VP
Wire Wire Line
	1450 3950 1450 4000
Wire Wire Line
	1450 4000 2850 4000
Wire Wire Line
	4250 4000 4250 3950
$Comp
L power:GND #PWR0102
U 1 1 64A1F782
P 1450 4000
F 0 "#PWR0102" H 1450 3750 50  0001 C CNN
F 1 "GND" H 1455 3827 50  0000 C CNN
F 2 "" H 1450 4000 50  0001 C CNN
F 3 "" H 1450 4000 50  0001 C CNN
	1    1450 4000
	1    0    0    -1  
$EndComp
Connection ~ 1450 4000
Wire Wire Line
	2850 2650 2850 4000
Connection ~ 2850 4000
Wire Wire Line
	2850 4000 4250 4000
Wire Wire Line
	2050 2350 2100 2350
Wire Wire Line
	2100 2350 2100 3050
Wire Wire Line
	2100 4500 1550 4500
Wire Wire Line
	1550 4500 1550 4800
Wire Wire Line
	2050 2850 3050 2850
Wire Wire Line
	3050 2850 3050 5000
Wire Wire Line
	1550 5000 1550 5100
Wire Wire Line
	1550 5100 2200 5100
Connection ~ 1550 5100
Wire Wire Line
	2150 2350 2150 4900
Connection ~ 2150 2350
Connection ~ 2150 4900
Wire Wire Line
	1050 3250 1050 4250
Wire Wire Line
	4650 4250 4650 3350
Wire Wire Line
	1050 3150 1000 3150
Wire Wire Line
	1000 3150 1000 4350
Wire Wire Line
	1000 4350 4700 4350
Wire Wire Line
	4700 4350 4700 3250
Wire Wire Line
	4700 3250 4650 3250
Wire Wire Line
	1050 4250 2300 4250
Wire Wire Line
	2350 2250 2300 2250
Wire Wire Line
	2300 2250 2300 4250
Connection ~ 2300 4250
Wire Wire Line
	2300 4250 4650 4250
Wire Wire Line
	2200 5500 2200 5100
Connection ~ 2200 5100
Wire Wire Line
	2200 5100 2450 5100
Wire Wire Line
	1050 3050 950  3050
Wire Wire Line
	950  3050 950  5600
Wire Wire Line
	950  5600 1600 5600
Wire Wire Line
	3100 5600 4750 5600
Wire Wire Line
	4750 5600 4750 3150
Wire Wire Line
	4750 3150 4650 3150
Wire Wire Line
	3100 5800 4800 5800
Wire Wire Line
	4800 5800 4800 3050
Wire Wire Line
	4800 3050 4650 3050
Wire Wire Line
	1550 1150 1550 1050
Wire Wire Line
	1550 1050 2850 1050
Wire Wire Line
	4150 1050 4150 1150
Connection ~ 2850 1050
Wire Wire Line
	2850 1050 3600 1050
$Comp
L power:+5V #PWR0103
U 1 1 64AB1C87
P 2850 1050
F 0 "#PWR0103" H 2850 900 50  0001 C CNN
F 1 "+5V" H 2865 1223 50  0000 C CNN
F 2 "" H 2850 1050 50  0001 C CNN
F 3 "" H 2850 1050 50  0001 C CNN
	1    2850 1050
	1    0    0    -1  
$EndComp
$Comp
L power:+5V #PWR0104
U 1 1 64ABA1B7
P 950 6050
F 0 "#PWR0104" H 950 5900 50  0001 C CNN
F 1 "+5V" H 965 6223 50  0000 C CNN
F 2 "" H 950 6050 50  0001 C CNN
F 3 "" H 950 6050 50  0001 C CNN
	1    950  6050
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR0105
U 1 1 64ABA6BA
P 950 7050
F 0 "#PWR0105" H 950 6800 50  0001 C CNN
F 1 "GND" H 955 6877 50  0000 C CNN
F 2 "" H 950 7050 50  0001 C CNN
F 3 "" H 950 7050 50  0001 C CNN
	1    950  7050
	1    0    0    -1  
$EndComp
Wire Wire Line
	2700 2700 3000 2700
Wire Wire Line
	2100 3050 3400 3050
Wire Wire Line
	3400 3050 3400 2350
Wire Wire Line
	3400 2350 3650 2350
Connection ~ 2100 3050
Wire Wire Line
	2100 3050 2100 4500
Wire Wire Line
	3650 2250 3600 2250
Wire Wire Line
	3600 2250 3600 1050
Connection ~ 3600 1050
Wire Wire Line
	3600 1050 4150 1050
$Comp
L Device:R R1
U 1 1 649BA6B6
P 3500 3550
F 0 "R1" V 3600 3550 50  0000 C CNN
F 1 "12K" V 3500 3550 50  0000 C CNN
F 2 "Resistor_SMD:R_0805_2012Metric_Pad1.15x1.40mm_HandSolder" V 3430 3550 50  0001 C CNN
F 3 "~" H 3500 3550 50  0001 C CNN
	1    3500 3550
	0    1    1    0   
$EndComp
$Comp
L Device:LED D1
U 1 1 649BBBF1
P 3350 3400
F 0 "D1" V 3400 3250 50  0000 L CNN
F 1 "BLUE" V 3300 3150 50  0000 L CNN
F 2 "LED_THT:LED_D3.0mm_Horizontal_O6.35mm_Z2.0mm" H 3350 3400 50  0001 C CNN
F 3 "~" H 3350 3400 50  0001 C CNN
	1    3350 3400
	0    1    -1   0   
$EndComp
Wire Wire Line
	3350 3250 3600 3250
Wire Wire Line
	3600 3250 3600 2250
Connection ~ 3600 2250
Wire Bus Line
	4900 600  4900 2750
Wire Bus Line
	800  600  800  2750
$EndSCHEMATC
