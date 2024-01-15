EESchema Schematic File Version 4
LIBS:v2-cache
EELAYER 29 0
EELAYER END
$Descr A4 11693 8268
encoding utf-8
Sheet 3 3
Title "DURANGO-X computer"
Date "2023-08-28"
Rev "v2"
Comp "@zuiko21"
Comment1 "(c) 2021-2023 Carlos J. Santisteban"
Comment2 ""
Comment3 ""
Comment4 ""
$EndDescr
$Comp
L power:GND #PWR0111
U 1 1 6315BD20
P 1150 1400
F 0 "#PWR0111" H 1150 1150 50  0001 C CNN
F 1 "GND" H 1155 1227 50  0000 C CNN
F 2 "" H 1150 1400 50  0001 C CNN
F 3 "" H 1150 1400 50  0001 C CNN
	1    1150 1400
	1    0    0    -1  
$EndComp
$Comp
L Device:CP C6
U 1 1 6315BFF0
P 1150 1250
F 0 "C6" H 1200 1350 50  0000 L CNN
F 1 "470µ" H 1150 1150 50  0000 L CNN
F 2 "Capacitor_THT:CP_Radial_D6.3mm_P2.50mm" H 1188 1100 50  0001 C CNN
F 3 "~" H 1150 1250 50  0001 C CNN
	1    1150 1250
	1    0    0    -1  
$EndComp
Wire Wire Line
	650  1400 750  1400
Connection ~ 1150 1400
$Comp
L power:+5V #PWR0153
U 1 1 6315CF6B
P 1700 650
F 0 "#PWR0153" H 1700 500 50  0001 C CNN
F 1 "+5V" H 1800 750 50  0000 C CNN
F 2 "" H 1700 650 50  0001 C CNN
F 3 "" H 1700 650 50  0001 C CNN
	1    1700 650 
	1    0    0    -1  
$EndComp
$Comp
L Device:C C7
U 1 1 6315D0B4
P 1700 1250
F 0 "C7" H 1750 1350 50  0000 L CNN
F 1 "22n" H 1700 1150 50  0000 L CNN
F 2 "Capacitor_THT:C_Rect_L7.2mm_W2.5mm_P5.00mm_FKS2_FKP2_MKS2_MKP2" H 1738 1100 50  0001 C CNN
F 3 "~" H 1700 1250 50  0001 C CNN
	1    1700 1250
	1    0    0    -1  
$EndComp
Wire Wire Line
	1150 1400 1700 1400
$Comp
L 74xx:74LS20 U17
U 3 1 6318F3D4
P 4850 1150
F 0 "U17" H 4850 1600 50  0000 L CNN
F 1 "74HC21" H 4850 1500 50  0000 L CNN
F 2 "Package_DIP:DIP-14_W7.62mm_Socket" H 4850 1150 50  0001 C CNN
F 3 "http://www.ti.com/lit/gpn/sn74LS20" H 4850 1150 50  0001 C CNN
	3    4850 1150
	1    0    0    -1  
$EndComp
$Comp
L 74xx:74HCT02 U16
U 5 1 63193401
P 4400 1150
F 0 "U16" H 4400 1600 50  0000 L CNN
F 1 "74HC02" H 4400 1500 50  0000 L CNN
F 2 "Package_DIP:DIP-14_W7.62mm_Socket" H 4400 1150 50  0001 C CNN
F 3 "http://www.ti.com/lit/gpn/sn74hct02" H 4400 1150 50  0001 C CNN
	5    4400 1150
	1    0    0    -1  
$EndComp
$Comp
L 74xx:74HCT00 U9
U 5 1 631D9308
P 2600 1150
F 0 "U9" H 2600 1600 50  0000 L CNN
F 1 "74HC00" H 2600 1500 50  0000 L CNN
F 2 "Package_DIP:DIP-14_W7.62mm_Socket" H 2600 1150 50  0001 C CNN
F 3 "http://www.ti.com/lit/gpn/sn74hct00" H 2600 1150 50  0001 C CNN
	5    2600 1150
	1    0    0    -1  
$EndComp
$Comp
L 74xx:74HC74 U12
U 3 1 631DC617
P 3500 1150
F 0 "U12" H 3500 1600 50  0000 L CNN
F 1 "74HC74" H 3500 1500 50  0000 L CNN
F 2 "Package_DIP:DIP-14_W7.62mm_Socket" H 3500 1150 50  0001 C CNN
F 3 "74xx/74hc_hct74.pdf" H 3500 1150 50  0001 C CNN
	3    3500 1150
	1    0    0    -1  
$EndComp
Wire Wire Line
	1700 1100 1700 650 
$Comp
L 74xx:74HC86 U23
U 5 1 61BA3670
P 5300 1150
F 0 "U23" H 5300 1600 50  0000 L CNN
F 1 "74HC86" H 5300 1500 50  0000 L CNN
F 2 "Package_DIP:DIP-14_W7.62mm_Socket" H 5300 1150 50  0001 C CNN
F 3 "http://www.ti.com/lit/gpn/sn74HC86" H 5300 1150 50  0001 C CNN
	5    5300 1150
	1    0    0    -1  
$EndComp
$Comp
L 74xx:74LS32 U13
U 5 1 61BAB9F2
P 3950 1150
F 0 "U13" H 3950 1600 50  0000 L CNN
F 1 "74HC32" H 3950 1500 50  0000 L CNN
F 2 "Package_DIP:DIP-14_W7.62mm_Socket" H 3950 1150 50  0001 C CNN
F 3 "http://www.ti.com/lit/gpn/sn74LS32" H 3950 1150 50  0001 C CNN
	5    3950 1150
	1    0    0    -1  
$EndComp
$Comp
L 74xx:74HC86 U126
U 5 1 61BC27C7
P 5750 1150
F 0 "U126" H 5750 1600 50  0000 L CNN
F 1 "74HC86" H 5750 1500 50  0000 L CNN
F 2 "Package_DIP:DIP-14_W7.62mm_Socket" H 5750 1150 50  0001 C CNN
F 3 "http://www.ti.com/lit/gpn/sn74HC86" H 5750 1150 50  0001 C CNN
	5    5750 1150
	1    0    0    -1  
$EndComp
Text GLabel 900  2150 1    50   Input ~ 0
D[0..7]
Text GLabel 750  2150 1    50   Input ~ 0
A[0..15]
$Comp
L Connector_Generic:Conn_01x17 J8
U 1 1 60AD9E5D
P 1550 2850
F 0 "J8" H 1630 2842 50  0000 L CNN
F 1 "DEBUG" H 1630 2751 50  0000 L CNN
F 2 "Connector_PinSocket_2.54mm:PinSocket_1x17_P2.54mm_Vertical" H 1550 2850 50  0001 C CNN
F 3 "~" H 1550 2850 50  0001 C CNN
	1    1550 2850
	1    0    0    -1  
$EndComp
Wire Wire Line
	850  3250 1350 3250
Wire Wire Line
	850  3350 1350 3350
Wire Wire Line
	1000 3150 1350 3150
Wire Wire Line
	1000 3050 1350 3050
Wire Wire Line
	1000 2950 1350 2950
Wire Wire Line
	1000 2850 1350 2850
Wire Wire Line
	1000 2750 1350 2750
Wire Wire Line
	1000 2650 1350 2650
Wire Wire Line
	1000 2550 1350 2550
Wire Wire Line
	1000 2450 1350 2450
Text Label 1200 2450 0    50   ~ 0
D0
Text Label 1200 2550 0    50   ~ 0
D1
Text Label 1200 2650 0    50   ~ 0
D2
Text Label 1200 2750 0    50   ~ 0
D3
Text Label 1200 2850 0    50   ~ 0
D4
Text Label 1200 2950 0    50   ~ 0
D5
Text Label 1200 3050 0    50   ~ 0
D6
Text Label 1200 3150 0    50   ~ 0
D7
Text Label 1200 3250 0    50   ~ 0
A15
Text Label 1200 3350 0    50   ~ 0
A14
Entry Wire Line
	750  3150 850  3250
Entry Wire Line
	750  3250 850  3350
Entry Wire Line
	900  3050 1000 3150
Entry Wire Line
	900  2950 1000 3050
Entry Wire Line
	900  2850 1000 2950
Entry Wire Line
	900  2750 1000 2850
Entry Wire Line
	900  2650 1000 2750
Entry Wire Line
	900  2550 1000 2650
Entry Wire Line
	900  2450 1000 2550
Entry Wire Line
	900  2350 1000 2450
Text GLabel 1050 2050 1    50   Input ~ 0
R~W
Wire Wire Line
	1050 2350 1350 2350
$Comp
L power:GND #PWR0150
U 1 1 60AD9E86
P 1350 3650
F 0 "#PWR0150" H 1350 3400 50  0001 C CNN
F 1 "GND" V 1355 3522 50  0000 R CNN
F 2 "" H 1350 3650 50  0001 C CNN
F 3 "" H 1350 3650 50  0001 C CNN
	1    1350 3650
	0    1    1    0   
$EndComp
$Comp
L power:+5V #PWR0155
U 1 1 60AD9E8C
P 1200 1750
F 0 "#PWR0155" H 1200 1600 50  0001 C CNN
F 1 "+5V" H 1000 1850 50  0000 L CNN
F 2 "" H 1200 1750 50  0001 C CNN
F 3 "" H 1200 1750 50  0001 C CNN
	1    1200 1750
	1    0    0    -1  
$EndComp
Text GLabel 1350 2050 1    50   Input ~ 0
SCLK
$Comp
L 74xx:74LS20 U227
U 3 1 6259510E
P 6200 1150
F 0 "U227" H 6200 1600 50  0000 L CNN
F 1 "74HC20" H 6200 1500 50  0000 L CNN
F 2 "Package_DIP:DIP-14_W7.62mm_Socket" H 6200 1150 50  0001 C CNN
F 3 "http://www.ti.com/lit/gpn/sn74LS20" H 6200 1150 50  0001 C CNN
	3    6200 1150
	1    0    0    -1  
$EndComp
NoConn ~ 1350 2250
Text Notes 1600 2300 0    50   ~ 0
KEY
Entry Wire Line
	750  3350 850  3450
Entry Wire Line
	750  3450 850  3550
Wire Wire Line
	850  3450 1350 3450
Wire Wire Line
	850  3550 1350 3550
Text Label 1200 3450 0    50   ~ 0
A13
Text Label 1200 3550 0    50   ~ 0
A12
Text Label 1200 2350 0    50   ~ 0
R~W
$Comp
L 74xx:74LS139 U10
U 3 1 612E1A0F
P 3050 1150
F 0 "U10" H 3050 1600 50  0000 L CNN
F 1 "74HC139" H 3050 1500 50  0000 L CNN
F 2 "Package_DIP:DIP-16_W7.62mm_Socket" H 3050 1150 50  0001 C CNN
F 3 "http://www.ti.com/lit/gpn/sn74LS139" H 3050 1150 50  0001 C CNN
	3    3050 1150
	1    0    0    -1  
$EndComp
Connection ~ 5750 650 
Wire Wire Line
	5750 650  6200 650 
Connection ~ 5750 1650
Wire Wire Line
	5750 1650 6200 1650
Text GLabel 3700 2150 1    50   Input ~ 0
D[0..7]
Entry Wire Line
	3700 2700 3600 2800
Entry Wire Line
	3700 2600 3600 2700
Entry Wire Line
	3700 2500 3600 2600
Entry Wire Line
	3700 2400 3600 2500
Text Label 3600 2500 2    50   ~ 0
D4
Text Label 3600 2600 2    50   ~ 0
D5
Text Label 3600 2700 2    50   ~ 0
D6
Text Label 3600 2800 2    50   ~ 0
D7
Text GLabel 2250 2800 0    50   Input ~ 0
HIRES
Text GLabel 2250 2700 0    50   Input ~ 0
INVERT
Text GLabel 2250 3000 0    50   Input ~ 0
~FRAME
Text GLabel 2250 2900 0    50   Input ~ 0
~LINE
Wire Wire Line
	3500 750  3500 650 
Wire Wire Line
	3500 1550 3500 1650
Connection ~ 5300 650 
Wire Wire Line
	5300 650  5750 650 
Connection ~ 5300 1650
Wire Wire Line
	5300 1650 5750 1650
Connection ~ 2600 650 
Connection ~ 2600 1650
Connection ~ 3050 650 
Connection ~ 3050 1650
Connection ~ 3500 650 
Connection ~ 3500 1650
Connection ~ 3950 650 
Connection ~ 3950 1650
Wire Wire Line
	2600 650  3050 650 
Wire Wire Line
	2600 1650 3050 1650
Wire Wire Line
	3050 650  3500 650 
Wire Wire Line
	3050 1650 3500 1650
Wire Wire Line
	3500 650  3950 650 
Wire Wire Line
	3500 1650 3950 1650
Wire Wire Line
	3950 650  4400 650 
Wire Wire Line
	3950 1650 4400 1650
Connection ~ 4400 650 
Connection ~ 4400 1650
Wire Wire Line
	4400 650  4850 650 
Wire Wire Line
	4400 1650 4850 1650
Connection ~ 4850 650 
Wire Wire Line
	4850 650  5300 650 
Connection ~ 4850 1650
Wire Wire Line
	4850 1650 5300 1650
$Comp
L 74xx:74LS139 U29
U 3 1 62D1DE0F
P 6650 1150
F 0 "U29" H 6650 1600 50  0000 L CNN
F 1 "74HC139" H 6650 1500 50  0000 L CNN
F 2 "Package_DIP:DIP-16_W7.62mm_Socket" H 6650 1150 50  0001 C CNN
F 3 "http://www.ti.com/lit/gpn/sn74LS139" H 6650 1150 50  0001 C CNN
	3    6650 1150
	1    0    0    -1  
$EndComp
Wire Wire Line
	6200 650  6650 650 
Connection ~ 6200 650 
Wire Wire Line
	6200 1650 6650 1650
Connection ~ 6200 1650
Text GLabel 2250 3200 0    50   Input ~ 0
~STAT
Text GLabel 2250 3300 0    50   Input ~ 0
~BLANK
Wire Wire Line
	1050 2050 1050 2350
Wire Wire Line
	3250 2500 3600 2500
Wire Wire Line
	3250 2600 3600 2600
Text GLabel 2250 2500 0    50   Input ~ 0
SC0
Text GLabel 2250 2600 0    50   Input ~ 0
SC1
$Comp
L Connector:USB_B J7
U 1 1 61A5663E
P 750 1000
F 0 "J7" H 750 1350 50  0000 C CNN
F 1 "POWER IN" V 500 950 50  0000 C CNN
F 2 "Connector_USB:USB_B_OST_USB-B1HSxx_Horizontal" H 900 950 50  0001 C CNN
F 3 " ~" H 900 950 50  0001 C CNN
	1    750  1000
	1    0    0    -1  
$EndComp
Connection ~ 750  1400
Wire Wire Line
	750  1400 1150 1400
Connection ~ 1700 650 
Wire Wire Line
	1150 800  1050 800 
NoConn ~ 1050 1000
NoConn ~ 1050 1100
Text GLabel 1350 5600 0    50   Input ~ 0
SCLK
Text GLabel 1850 5600 2    50   Input ~ 0
~RESET
Text GLabel 1200 4200 0    50   Input ~ 0
~WE
Text GLabel 2050 4000 2    50   Input ~ 0
~IOC
Entry Wire Line
	750  4200 850  4300
Entry Wire Line
	750  4300 850  4400
Entry Wire Line
	750  4400 850  4500
Entry Wire Line
	750  4500 850  4600
Entry Wire Line
	750  4600 850  4700
Entry Wire Line
	750  4700 850  4800
Entry Wire Line
	750  4900 850  5000
Entry Wire Line
	750  4800 850  4900
$Comp
L power:GND #PWR0164
U 1 1 624C4252
P 1350 5500
F 0 "#PWR0164" H 1350 5250 50  0001 C CNN
F 1 "GND" V 1355 5372 50  0000 R CNN
F 2 "" H 1350 5500 50  0001 C CNN
F 3 "" H 1350 5500 50  0001 C CNN
	1    1350 5500
	0    1    1    0   
$EndComp
$Comp
L power:+5V #PWR0165
U 1 1 624C4A16
P 1850 4200
F 0 "#PWR0165" H 1850 4050 50  0001 C CNN
F 1 "+5V" V 1865 4328 50  0000 L CNN
F 2 "" H 1850 4200 50  0001 C CNN
F 3 "" H 1850 4200 50  0001 C CNN
	1    1850 4200
	0    1    1    0   
$EndComp
Wire Bus Line
	750  5750 2450 5750
Wire Bus Line
	900  5700 2300 5700
Entry Wire Line
	750  5000 850  5100
Entry Wire Line
	900  5100 1000 5200
Entry Wire Line
	900  5200 1000 5300
Entry Wire Line
	2200 5500 2300 5600
Entry Wire Line
	2200 5400 2300 5500
Entry Wire Line
	2200 5300 2300 5400
Entry Wire Line
	2200 5200 2300 5300
Entry Wire Line
	2200 5100 2300 5200
Entry Wire Line
	2350 4900 2450 5000
Entry Wire Line
	2350 4700 2450 4800
Entry Wire Line
	2350 4600 2450 4700
Entry Wire Line
	2350 4500 2450 4600
Entry Wire Line
	2350 4400 2450 4500
Entry Wire Line
	2350 4300 2450 4400
Wire Wire Line
	1850 4300 2350 4300
Wire Wire Line
	1850 4400 2350 4400
Wire Wire Line
	1850 4500 2350 4500
Wire Wire Line
	1850 4600 2350 4600
Wire Wire Line
	1850 4700 2350 4700
Wire Wire Line
	1850 4900 2350 4900
Wire Wire Line
	1850 5100 2200 5100
Wire Wire Line
	1850 5200 2200 5200
Wire Wire Line
	1850 5300 2200 5300
Wire Wire Line
	1850 5400 2200 5400
Wire Wire Line
	1850 5500 2200 5500
Entry Wire Line
	900  5300 1000 5400
Text Label 1350 5200 2    50   ~ 0
D0
Text Label 1350 5400 2    50   ~ 0
D2
Text Label 1850 5500 0    50   ~ 0
D3
Text Label 1850 5400 0    50   ~ 0
D4
Text Label 1850 5300 0    50   ~ 0
D5
Text Label 1850 5200 0    50   ~ 0
D6
Text Label 1850 5100 0    50   ~ 0
D7
Text Label 1850 4900 0    50   ~ 0
A10
Text Label 1850 4700 0    50   ~ 0
A11
Text Label 1850 4600 0    50   ~ 0
A9
Text Label 1850 4500 0    50   ~ 0
A8
Text Label 1850 4400 0    50   ~ 0
A13
Text Label 1850 4300 0    50   ~ 0
A14
Text Label 1350 4300 2    50   ~ 0
A12
Text Label 1350 4400 2    50   ~ 0
A7
Text Label 1350 4500 2    50   ~ 0
A6
Text Label 1350 4600 2    50   ~ 0
A5
Text Label 1350 4700 2    50   ~ 0
A4
Text Label 1350 4800 2    50   ~ 0
A3
Text Label 1350 4900 2    50   ~ 0
A2
Text Label 1350 5000 2    50   ~ 0
A1
Text Label 1350 5100 2    50   ~ 0
A0
Text GLabel 2000 5000 2    50   Input ~ 0
~ROM_CS
Text GLabel 2000 4800 2    50   Input ~ 0
~ROM_OE
Wire Wire Line
	2000 4800 1850 4800
Wire Wire Line
	2000 5000 1850 5000
Text GLabel 1350 4000 0    50   Input ~ 0
AUDIO_IN
Wire Wire Line
	1200 4200 1350 4200
Wire Wire Line
	850  4300 1350 4300
Wire Wire Line
	850  4400 1350 4400
Wire Wire Line
	850  4500 1350 4500
Wire Wire Line
	850  4600 1350 4600
Wire Wire Line
	850  4700 1350 4700
Wire Wire Line
	850  4800 1350 4800
Wire Wire Line
	850  4900 1350 4900
Wire Wire Line
	850  5000 1350 5000
Wire Wire Line
	1000 5200 1350 5200
Wire Wire Line
	1000 5300 1350 5300
Text Label 1350 5300 2    50   ~ 0
D1
Wire Wire Line
	1000 5400 1350 5400
Wire Wire Line
	1350 3650 1350 3750
Wire Wire Line
	1350 3750 2750 3750
Wire Wire Line
	2750 3600 2750 3750
Connection ~ 1350 3650
Text Notes 4350 3200 0    100  ~ 0
 xx = Standard\n1xx = Only needed for Colour mode\n2xx = Only needed for HiRes mode\n3xx = Only for switching modes (may be replaced by jumpers)\n4xx = Switchable features (may be replaced by jumpers)\n5xx = Advanced features (may be replaced by jumpers)\n6xx = Only for Component video output\n7xx = Only for optional second video output (Composite)\n8xx = Only if HiRes is *NOT* supported\n9xx = Only for SCART video output
NoConn ~ 1350 4100
NoConn ~ 1850 4100
Text Notes 1900 4150 0    50   Italic 0
KEY
Text Notes 1150 4150 0    50   Italic 0
KEY
$Comp
L Connector_Generic:Conn_02x18_Odd_Even J9
U 1 1 625630C9
P 1650 4700
F 0 "J9" H 1700 3600 50  0000 C CNN
F 1 "CARTRIDGE" H 1700 3500 50  0000 C CNN
F 2 "Connector_PinSocket_2.54mm:PinSocket_2x18_EDGE" H 1650 4700 50  0001 C CNN
F 3 "~" H 1650 4700 50  0001 C CNN
	1    1650 4700
	-1   0    0    -1  
$EndComp
Text GLabel 1350 3900 0    50   Input ~ 0
~NMI
Text GLabel 1850 3900 2    50   Input ~ 0
~IRQ
Wire Wire Line
	2050 4000 1850 4000
Text Label 1150 800  1    50   ~ 0
+5V_IN
Text Label 5150 4300 0    50   ~ 0
BA0
Text Label 5150 4400 0    50   ~ 0
BA1
Text Label 5150 4500 0    50   ~ 0
BA2
Text Label 5150 4600 0    50   ~ 0
BA3
Wire Wire Line
	5550 4300 5150 4300
Wire Wire Line
	5550 4400 5150 4400
Wire Wire Line
	5550 4500 5150 4500
Wire Wire Line
	5550 4600 5150 4600
Wire Wire Line
	5550 4700 5150 4700
Entry Wire Line
	5550 4300 5650 4400
Entry Wire Line
	5550 4400 5650 4500
Entry Wire Line
	5550 4500 5650 4600
Entry Wire Line
	5550 4600 5650 4700
Entry Wire Line
	5550 4700 5650 4800
Text GLabel 5650 4850 3    50   Input ~ 0
BA[0..4]
Entry Wire Line
	2450 4400 2550 4300
Entry Wire Line
	2450 4500 2550 4400
Entry Wire Line
	2450 4600 2550 4500
Entry Wire Line
	2450 4700 2550 4600
Wire Wire Line
	4650 5600 5150 5600
Wire Wire Line
	2550 4300 4150 4300
Wire Wire Line
	2550 4400 4150 4400
Wire Wire Line
	2550 4500 4150 4500
Wire Wire Line
	2550 4600 4150 4600
$Comp
L power:GND #PWR0135
U 1 1 628164ED
P 4650 5600
F 0 "#PWR0135" H 4650 5350 50  0001 C CNN
F 1 "GND" H 4655 5427 50  0000 C CNN
F 2 "" H 4650 5600 50  0001 C CNN
F 3 "" H 4650 5600 50  0001 C CNN
	1    4650 5600
	1    0    0    -1  
$EndComp
$Comp
L power:+5V #PWR0166
U 1 1 62816C8C
P 4650 3950
F 0 "#PWR0166" H 4650 3800 50  0001 C CNN
F 1 "+5V" H 4665 4123 50  0000 C CNN
F 2 "" H 4650 3950 50  0001 C CNN
F 3 "" H 4650 3950 50  0001 C CNN
	1    4650 3950
	1    0    0    -1  
$EndComp
Wire Wire Line
	2550 4700 4150 4700
Text Label 2600 4700 0    50   ~ 0
R~W
Wire Wire Line
	2550 4850 2550 4700
Text GLabel 2550 4850 3    50   Input ~ 0
R~W
Text Label 2600 4300 0    50   ~ 0
A0
Text Label 2600 4400 0    50   ~ 0
A1
Text Label 2600 4500 0    50   ~ 0
A2
Text Label 2600 4600 0    50   ~ 0
A3
Wire Wire Line
	3800 3750 2750 3750
Connection ~ 2750 3750
Wire Wire Line
	3250 2700 3350 2700
Wire Wire Line
	3250 2800 3600 2800
$Comp
L 74xx:74LS367 U530
U 1 1 61283F21
P 2750 2900
F 0 "U530" H 2500 3550 50  0000 C CNN
F 1 "74HC367" H 2500 3450 50  0000 C CNN
F 2 "Package_DIP:DIP-16_W7.62mm_Socket" H 2750 2900 50  0001 C CNN
F 3 "http://www.ti.com/lit/gpn/sn74LS367" H 2750 2900 50  0001 C CNN
	1    2750 2900
	1    0    0    -1  
$EndComp
Wire Wire Line
	3250 2900 3250 2800
Connection ~ 3250 2800
Wire Wire Line
	3250 3000 3350 3000
Wire Wire Line
	3350 3000 3350 2700
Connection ~ 3350 2700
Wire Wire Line
	3350 2700 3600 2700
Text Label 5150 4700 0    50   ~ 0
BA4
Text Notes 5300 4700 0    50   ~ 0
=~BWR
Wire Wire Line
	1200 1750 1200 2150
Wire Wire Line
	1200 2150 1350 2150
Wire Wire Line
	1200 1750 2750 1750
Wire Wire Line
	2750 1750 2750 2200
Connection ~ 1200 1750
$Comp
L Connector_Generic:Conn_02x08_Odd_Even J11
U 1 1 631CA641
P 1550 6500
F 0 "J11" H 1600 5950 50  0000 C CNN
F 1 "EXPANSION" H 1600 5850 50  0000 C CNN
F 2 "Connector_PinSocket_2.54mm:PinSocket_2x08_P2.54mm_Horizontal" H 1550 6500 50  0001 C CNN
F 3 "~" H 1550 6500 50  0001 C CNN
	1    1550 6500
	1    0    0    -1  
$EndComp
Text Label 1850 6200 0    50   ~ 0
PD0
Text Label 1850 6300 0    50   ~ 0
PD1
Text Label 1850 6400 0    50   ~ 0
PD2
Text Label 1850 6500 0    50   ~ 0
PD3
Text Label 1850 6600 0    50   ~ 0
PD4
Text Label 1850 6700 0    50   ~ 0
PD5
Text Label 1850 6800 0    50   ~ 0
PD6
Text Label 1850 6900 0    50   ~ 0
PD7
Text Label 1350 6300 2    50   ~ 0
BA0
Text Label 1350 6400 2    50   ~ 0
BA1
Text Label 1350 6500 2    50   ~ 0
BA2
Text Label 1350 6600 2    50   ~ 0
BA3
Wire Wire Line
	1150 6300 1350 6300
Wire Wire Line
	1150 6400 1350 6400
Wire Wire Line
	1150 6500 1350 6500
Wire Wire Line
	1150 6600 1350 6600
Wire Wire Line
	1150 6700 1350 6700
Entry Wire Line
	1150 6300 1050 6400
Entry Wire Line
	1150 6400 1050 6500
Entry Wire Line
	1150 6500 1050 6600
Entry Wire Line
	1150 6600 1050 6700
Entry Wire Line
	1150 6700 1050 6800
Text GLabel 1050 6900 3    50   Input ~ 0
BA[0..4]
Text Label 1350 6700 2    50   ~ 0
BA4
Text Notes 1000 6700 2    50   ~ 0
BA4=~BWR
$Comp
L power:+5V #PWR0104
U 1 1 631E84E6
P 1350 6200
F 0 "#PWR0104" H 1350 6050 50  0001 C CNN
F 1 "+5V" H 1365 6373 50  0000 C CNN
F 2 "" H 1350 6200 50  0001 C CNN
F 3 "" H 1350 6200 50  0001 C CNN
	1    1350 6200
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR0108
U 1 1 631E8D69
P 1350 6900
F 0 "#PWR0108" H 1350 6650 50  0001 C CNN
F 1 "GND" H 1300 6750 50  0000 C CNN
F 2 "" H 1350 6900 50  0001 C CNN
F 3 "" H 1350 6900 50  0001 C CNN
	1    1350 6900
	1    0    0    -1  
$EndComp
Wire Wire Line
	1850 6200 2050 6200
Wire Wire Line
	1850 6300 2050 6300
Wire Wire Line
	1850 6400 2050 6400
Wire Wire Line
	1850 6500 2050 6500
Wire Wire Line
	1850 6600 2050 6600
Wire Wire Line
	1850 6700 2050 6700
Wire Wire Line
	1850 6800 2050 6800
Wire Wire Line
	1850 6900 2050 6900
Entry Wire Line
	2050 6200 2150 6300
Entry Wire Line
	2050 6300 2150 6400
Entry Wire Line
	2050 6400 2150 6500
Entry Wire Line
	2050 6500 2150 6600
Entry Wire Line
	2050 6600 2150 6700
Entry Wire Line
	2050 6700 2150 6800
Entry Wire Line
	2050 6800 2150 6900
Entry Wire Line
	2050 6900 2150 7000
Text GLabel 2150 7000 3    50   Input ~ 0
PD[0..7]
Text GLabel 1150 6900 3    50   Input ~ 0
~IO9Q
Wire Wire Line
	1350 6800 1150 6800
Wire Wire Line
	1150 6800 1150 6900
$Comp
L Device:R R731
U 1 1 632E91E3
P 3150 3550
F 0 "R731" V 3050 3550 50  0000 C CNN
F 1 "75" V 3150 3550 50  0000 C CNN
F 2 "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P2.54mm_Vertical" V 3080 3550 50  0001 C CNN
F 3 "~" H 3150 3550 50  0001 C CNN
	1    3150 3550
	0    1    1    0   
$EndComp
Text GLabel 3000 3550 0    50   Input ~ 0
MIX
Text Label 3350 3550 1    50   ~ 0
RMIX2
Wire Wire Line
	3300 3550 3350 3550
Text Label 3650 3550 2    50   ~ 0
Y
$Comp
L Mechanical:MountingHole_Pad H1
U 1 1 631FC739
P 10900 5550
F 0 "H1" V 10900 5700 50  0000 L CNN
F 1 " " V 10945 5700 50  0001 L CNN
F 2 "MountingHole:MountingHole_3.2mm_M3_DIN965_Pad" H 10900 5550 50  0001 C CNN
F 3 "~" H 10900 5550 50  0001 C CNN
	1    10900 5550
	0    1    1    0   
$EndComp
$Comp
L Mechanical:MountingHole_Pad H2
U 1 1 631FCA14
P 10900 5800
F 0 "H2" V 10900 5950 50  0000 L CNN
F 1 " " V 10945 5950 50  0001 L CNN
F 2 "MountingHole:MountingHole_3.2mm_M3_DIN965_Pad" H 10900 5800 50  0001 C CNN
F 3 "~" H 10900 5800 50  0001 C CNN
	1    10900 5800
	0    1    1    0   
$EndComp
$Comp
L Mechanical:MountingHole_Pad H3
U 1 1 631FD31E
P 10900 6050
F 0 "H3" V 10900 6200 50  0000 L CNN
F 1 " " V 10945 6200 50  0001 L CNN
F 2 "MountingHole:MountingHole_3.2mm_M3_DIN965_Pad" H 10900 6050 50  0001 C CNN
F 3 "~" H 10900 6050 50  0001 C CNN
	1    10900 6050
	0    1    1    0   
$EndComp
$Comp
L Mechanical:MountingHole_Pad H4
U 1 1 631FD67B
P 10900 6300
F 0 "H4" V 10900 6450 50  0000 L CNN
F 1 " " V 10945 6450 50  0001 L CNN
F 2 "MountingHole:MountingHole_3.2mm_M3_DIN965_Pad" H 10900 6300 50  0001 C CNN
F 3 "~" H 10900 6300 50  0001 C CNN
	1    10900 6300
	0    1    1    0   
$EndComp
$Comp
L power:GND #PWR0152
U 1 1 6321A7E5
P 10800 6300
F 0 "#PWR0152" H 10800 6050 50  0001 C CNN
F 1 "GND" H 10805 6127 50  0000 C CNN
F 2 "" H 10800 6300 50  0001 C CNN
F 3 "" H 10800 6300 50  0001 C CNN
	1    10800 6300
	1    0    0    -1  
$EndComp
Wire Wire Line
	10800 5550 10800 5800
Connection ~ 10800 5800
Wire Wire Line
	10800 5800 10800 6050
Connection ~ 10800 6050
Wire Wire Line
	10800 6050 10800 6300
Connection ~ 10800 6300
$Comp
L Graphic:Logo_Open_Hardware_Large LOGO1
U 1 1 63275510
P 6400 7350
F 0 "LOGO1" H 6400 7850 50  0001 C CNN
F 1 " " H 6400 6950 50  0001 C CNN
F 2 "Symbol:OSHW-Logo2_9.8x8mm_SilkScreen" H 6400 7350 50  0001 C CNN
F 3 "~" H 6400 7350 50  0001 C CNN
	1    6400 7350
	1    0    0    -1  
$EndComp
$Comp
L Device:R R32
U 1 1 63239AAF
P 2600 6500
F 0 "R32" H 2670 6546 50  0000 L CNN
F 1 "1K" V 2600 6450 50  0000 L CNN
F 2 "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P2.54mm_Vertical" V 2530 6500 50  0001 C CNN
F 3 "~" H 2600 6500 50  0001 C CNN
	1    2600 6500
	1    0    0    -1  
$EndComp
$Comp
L Connector_Generic:Conn_01x02 J4
U 1 1 6323A6FB
P 2800 6750
F 0 "J4" H 2880 6742 50  0000 L CNN
F 1 "LED" H 2880 6651 50  0000 L CNN
F 2 "Connector_PinHeader_2.54mm:PinHeader_1x02_P2.54mm_Vertical" H 2800 6750 50  0001 C CNN
F 3 "~" H 2800 6750 50  0001 C CNN
	1    2800 6750
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR0167
U 1 1 6323B425
P 2600 6850
F 0 "#PWR0167" H 2600 6600 50  0001 C CNN
F 1 "GND" H 2605 6677 50  0000 C CNN
F 2 "" H 2600 6850 50  0001 C CNN
F 3 "" H 2600 6850 50  0001 C CNN
	1    2600 6850
	1    0    0    -1  
$EndComp
Text Label 2600 6750 2    50   ~ 0
LED_R
Wire Wire Line
	2600 6650 2600 6750
Text GLabel 2600 6350 1    50   Input ~ 0
LED
$Comp
L Device:CP C709
U 1 1 632E74BB
P 3500 3550
F 0 "C709" V 3755 3550 50  0000 C CNN
F 1 "100µ" V 3650 3550 50  0000 C CNN
F 2 "Capacitor_THT:CP_Radial_D4.0mm_P1.50mm" H 3538 3400 50  0001 C CNN
F 3 "~" H 3500 3550 50  0001 C CNN
	1    3500 3550
	0    -1   -1   0   
$EndComp
$Comp
L Connector:Conn_Coaxial_x3 J706
U 1 1 6375B503
P 4050 3350
F 0 "J706" H 4150 3353 50  0000 L CNN
F 1 "COMPOSITE" H 4150 3262 50  0000 L CNN
F 2 "durango:3xRCA" H 4050 3350 50  0001 C CNN
F 3 " ~" H 4050 3350 50  0001 C CNN
	1    4050 3350
	1    0    0    -1  
$EndComp
Wire Wire Line
	3850 3150 3750 3150
Wire Wire Line
	3750 3150 3750 3350
Text GLabel 3750 3150 0    50   Input ~ 0
AUDIO
Wire Wire Line
	3800 3750 3800 3650
Wire Wire Line
	3650 3550 3850 3550
Wire Wire Line
	3750 3350 3850 3350
Wire Wire Line
	3800 3250 3800 3450
Connection ~ 3800 3650
Connection ~ 3800 3450
Wire Wire Line
	3800 3450 3800 3650
$Comp
L Connector:Conn_Coaxial_x3 J605
U 1 1 637D6FA2
P 9700 6100
F 0 "J605" V 9700 6400 50  0000 L CNN
F 1 "COMPONENT VIDEO" V 9850 5750 50  0000 L CNN
F 2 "durango:3xRCA" H 9700 6100 50  0001 C CNN
F 3 " ~" H 9700 6100 50  0001 C CNN
	1    9700 6100
	0    -1   1    0   
$EndComp
Wire Wire Line
	9600 5850 9800 5850
Connection ~ 9800 5850
Wire Wire Line
	9800 5850 10000 5850
$Comp
L power:GND #PWR0176
U 1 1 637E28CA
P 10000 5850
F 0 "#PWR0176" H 10000 5600 50  0001 C CNN
F 1 "GND" V 10100 5750 50  0000 C CNN
F 2 "" H 10000 5850 50  0001 C CNN
F 3 "" H 10000 5850 50  0001 C CNN
	1    10000 5850
	0    -1   1    0   
$EndComp
Connection ~ 10000 5850
Text GLabel 9900 5800 1    50   Input ~ 0
LUMA
Wire Wire Line
	9500 5800 9500 5900
Wire Wire Line
	9700 5800 9700 5900
Wire Wire Line
	9900 5800 9900 5900
$Comp
L Graphic:Logo_Open_Hardware_Small LOGO2
U 1 1 636EC7BA
P 6600 6650
F 0 "LOGO2" H 6600 6925 50  0001 C CNN
F 1 " " H 6600 6425 50  0001 C CNN
F 2 "durango:durango-x90" H 6600 6650 50  0001 C CNN
F 3 "~" H 6600 6650 50  0001 C CNN
	1    6600 6650
	1    0    0    -1  
$EndComp
$Comp
L Graphic:Logo_Open_Hardware_Small LOGO3
U 1 1 63C8FA92
P 6150 6650
F 0 "LOGO3" H 6150 6925 50  0001 C CNN
F 1 " " H 6150 6425 50  0001 C CNN
F 2 "durango:jaqueria" H 6150 6650 50  0001 C CNN
F 3 "~" H 6150 6650 50  0001 C CNN
	1    6150 6650
	1    0    0    -1  
$EndComp
$Comp
L Device:R R?
U 1 1 658A2D3B
P 3900 4100
AR Path="/658A2D3B" Ref="R?"  Part="1" 
AR Path="/6310B9C7/658A2D3B" Ref="R26"  Part="1" 
F 0 "R26" H 4100 4100 50  0000 R CNN
F 1 "100K" V 3900 4100 50  0000 C CNN
F 2 "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P2.54mm_Vertical" V 3830 4100 50  0001 C CNN
F 3 "~" H 3900 4100 50  0001 C CNN
	1    3900 4100
	-1   0    0    1   
$EndComp
Wire Wire Line
	5150 5300 5150 5200
Wire Wire Line
	5150 5600 5150 5300
Connection ~ 5150 5300
Connection ~ 4650 5600
$Comp
L 74xx:74HC245 U?
U 1 1 627D9D31
P 4650 4800
AR Path="/60C42E7C/627D9D31" Ref="U?"  Part="1" 
AR Path="/6310B9C7/627D9D31" Ref="U32"  Part="1" 
F 0 "U32" H 4950 5450 50  0000 R CNN
F 1 "74HC245" H 4600 5450 50  0000 R CNN
F 2 "Package_DIP:DIP-20_W7.62mm_Socket" H 4650 4800 50  0001 C CNN
F 3 "http://www.ti.com/lit/gpn/sn74HC245" H 4650 4800 50  0001 C CNN
	1    4650 4800
	-1   0    0    -1  
$EndComp
$Comp
L Device:C C?
U 1 1 658A2D41
P 4050 4100
AR Path="/658A2D41" Ref="C?"  Part="1" 
AR Path="/6310B9C7/658A2D41" Ref="C8"  Part="1" 
F 0 "C8" H 3950 4000 50  0000 C CNN
F 1 "68p" H 3950 4200 50  0000 C CNN
F 2 "Capacitor_THT:C_Disc_D3.8mm_W2.6mm_P2.50mm" H 4088 3950 50  0001 C CNN
F 3 "~" H 4050 4100 50  0001 C CNN
	1    4050 4100
	-1   0    0    1   
$EndComp
Text GLabel 5150 4800 2    50   Input ~ 0
~RESET
Text GLabel 5150 4900 2    50   Input ~ 0
~NMIREQ
$Comp
L Device:R R?
U 1 1 65B96ACF
P 3000 4100
AR Path="/65B96ACF" Ref="R?"  Part="1" 
AR Path="/6310B9C7/65B96ACF" Ref="R3"  Part="1" 
F 0 "R3" H 3100 4100 50  0000 C CNN
F 1 "3K3" V 3000 4100 50  0000 C CNN
F 2 "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P2.54mm_Vertical" V 2930 4100 50  0001 C CNN
F 3 "~" H 3000 4100 50  0001 C CNN
	1    3000 4100
	-1   0    0    1   
$EndComp
$Comp
L Device:CP C?
U 1 1 65B96AD5
P 3000 4950
AR Path="/65B96AD5" Ref="C?"  Part="1" 
AR Path="/6310B9C7/65B96AD5" Ref="C1"  Part="1" 
F 0 "C1" H 3050 5050 50  0000 C CNN
F 1 "10µ" H 3100 4850 50  0000 C CNN
F 2 "Capacitor_THT:CP_Radial_D4.0mm_P1.50mm" H 3038 4800 50  0001 C CNN
F 3 "~" H 3000 4950 50  0001 C CNN
	1    3000 4950
	1    0    0    -1  
$EndComp
$Comp
L Switch:SW_Push SW?
U 1 1 65B96ADB
P 2800 5300
AR Path="/65B96ADB" Ref="SW?"  Part="1" 
AR Path="/6310B9C7/65B96ADB" Ref="SW1"  Part="1" 
F 0 "SW1" V 2750 5200 50  0000 C CNN
F 1 "RESET" V 2850 5150 50  0000 C CNN
F 2 "Button_Switch_THT:SW_PUSH_6mm" H 2800 5500 50  0001 C CNN
F 3 "~" H 2800 5500 50  0001 C CNN
	1    2800 5300
	0    1    1    0   
$EndComp
$Comp
L Device:R R33
U 1 1 65BDBC82
P 2800 4950
F 0 "R33" H 2800 4800 50  0000 L CNN
F 1 "120" V 2800 4950 50  0000 C CNN
F 2 "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P2.54mm_Vertical" V 2730 4950 50  0001 C CNN
F 3 "~" H 2800 4950 50  0001 C CNN
	1    2800 4950
	-1   0    0    1   
$EndComp
Wire Wire Line
	2800 4800 3000 4800
Wire Wire Line
	3000 5600 3000 5100
$Comp
L Device:R R?
U 1 1 65BEE1F1
P 3650 4100
AR Path="/65BEE1F1" Ref="R?"  Part="1" 
AR Path="/6310B9C7/65BEE1F1" Ref="R34"  Part="1" 
F 0 "R34" H 3850 4100 50  0000 R CNN
F 1 "3K3" V 3650 4100 50  0000 C CNN
F 2 "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P2.54mm_Vertical" V 3580 4100 50  0001 C CNN
F 3 "~" H 3650 4100 50  0001 C CNN
	1    3650 4100
	-1   0    0    1   
$EndComp
$Comp
L Device:CP C?
U 1 1 65BEE1FB
P 3650 5050
AR Path="/65BEE1FB" Ref="C?"  Part="1" 
AR Path="/6310B9C7/65BEE1FB" Ref="C10"  Part="1" 
F 0 "C10" H 3750 5150 50  0000 C CNN
F 1 "1µ" H 3750 4950 50  0000 C CNN
F 2 "Capacitor_THT:CP_Radial_D4.0mm_P1.50mm" H 3688 4900 50  0001 C CNN
F 3 "~" H 3650 5050 50  0001 C CNN
	1    3650 5050
	1    0    0    -1  
$EndComp
$Comp
L Switch:SW_Push SW?
U 1 1 65BEE205
P 3450 5400
AR Path="/65BEE205" Ref="SW?"  Part="1" 
AR Path="/6310B9C7/65BEE205" Ref="SW2"  Part="1" 
F 0 "SW2" V 3550 5550 50  0000 C CNN
F 1 "NMI" V 3350 5550 50  0000 C CNN
F 2 "Button_Switch_THT:SW_PUSH_6mm" H 3450 5600 50  0001 C CNN
F 3 "~" H 3450 5600 50  0001 C CNN
	1    3450 5400
	0    -1   -1   0   
$EndComp
$Comp
L Device:R R35
U 1 1 65BEE20F
P 3450 5050
F 0 "R35" H 3450 4900 50  0000 L CNN
F 1 "120" V 3450 5050 50  0000 C CNN
F 2 "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P2.54mm_Vertical" V 3380 5050 50  0001 C CNN
F 3 "~" H 3450 5050 50  0001 C CNN
	1    3450 5050
	-1   0    0    1   
$EndComp
Wire Wire Line
	3450 4900 3650 4900
Wire Wire Line
	3450 5600 3650 5600
Wire Wire Line
	3650 5600 3650 5200
Wire Wire Line
	3000 3950 3650 3950
Connection ~ 3650 3950
Wire Wire Line
	3650 3950 3900 3950
Wire Wire Line
	4650 3950 4650 4000
Connection ~ 4650 3950
Wire Wire Line
	3000 4250 3000 4800
Connection ~ 3000 4800
Wire Wire Line
	3650 4250 3650 4900
Connection ~ 3650 4900
Wire Wire Line
	3000 4800 4150 4800
Wire Wire Line
	3650 4900 4150 4900
Text Label 3000 4800 0    50   ~ 0
~ARST
Text Label 3650 4900 0    50   ~ 0
~ANMI
Text GLabel 5150 5000 2    50   Input ~ 0
~INTREQ
Connection ~ 4050 3950
Connection ~ 3900 3950
Wire Wire Line
	3900 3950 4050 3950
Wire Wire Line
	4050 3950 4650 3950
Wire Wire Line
	4150 5000 3900 5000
$Comp
L Device:D D?
U 1 1 658A2D35
P 3900 5150
AR Path="/658A2D35" Ref="D?"  Part="1" 
AR Path="/6310B9C7/658A2D35" Ref="D5"  Part="1" 
F 0 "D5" V 3900 5000 50  0000 L CNN
F 1 "4148" V 3800 4900 50  0000 L CNN
F 2 "Diode_THT:D_DO-35_SOD27_P2.54mm_Vertical_KathodeUp" H 3900 5150 50  0001 C CNN
F 3 "~" H 3900 5150 50  0001 C CNN
	1    3900 5150
	0    -1   -1   0   
$EndComp
Text Label 3900 5000 0    50   ~ 0
~ST250
Wire Wire Line
	3900 5000 3900 4250
Connection ~ 3900 5000
Wire Wire Line
	4050 4250 3900 4250
Connection ~ 3900 4250
Wire Wire Line
	4650 5600 3650 5600
Connection ~ 3650 5600
Wire Wire Line
	3000 5600 3450 5600
Connection ~ 3450 5600
Wire Wire Line
	3000 5600 2800 5600
Wire Wire Line
	2800 5600 2800 5500
Connection ~ 3000 5600
Text GLabel 3900 5300 3    50   Input ~ 0
~250HZ
Wire Wire Line
	1700 650  2100 650 
Wire Wire Line
	1700 1650 2100 1650
$Comp
L 74xx:74LS30 U8
U 2 1 6602C68F
P 2100 1150
F 0 "U8" H 2100 1600 50  0000 L CNN
F 1 "74HC30" H 2100 1500 50  0000 L CNN
F 2 "Package_DIP:DIP-14_W7.62mm_Socket" H 2100 1150 50  0001 C CNN
F 3 "http://www.ti.com/lit/gpn/sn74LS30" H 2100 1150 50  0001 C CNN
	2    2100 1150
	1    0    0    -1  
$EndComp
Connection ~ 2100 650 
Wire Wire Line
	2100 650  2600 650 
Connection ~ 2100 1650
Wire Wire Line
	2100 1650 2600 1650
Text Label 9500 5900 1    50   ~ 0
PR
Text Label 9700 5900 1    50   ~ 0
PB
$Comp
L Transistor_BJT:BC548 Q608
U 1 1 64FFA486
P 7450 4100
F 0 "Q608" H 7250 4250 50  0000 L CNN
F 1 "BC548" H 7300 3950 50  0000 L CNN
F 2 "Package_TO_SOT_THT:TO-92_Inline" H 7650 4025 50  0001 L CIN
F 3 "http://www.fairchildsemi.com/ds/BC/BC547.pdf" H 7450 4100 50  0001 L CNN
	1    7450 4100
	1    0    0    -1  
$EndComp
$Comp
L Transistor_BJT:BC548 Q609
U 1 1 64FFB066
P 7750 3900
F 0 "Q609" H 7600 4050 50  0000 L CNN
F 1 "BC548" H 7600 3750 50  0000 L CNN
F 2 "Package_TO_SOT_THT:TO-92_Inline" H 7950 3825 50  0001 L CIN
F 3 "http://www.fairchildsemi.com/ds/BC/BC547.pdf" H 7750 3900 50  0001 L CNN
	1    7750 3900
	1    0    0    -1  
$EndComp
$Comp
L Device:R R641
U 1 1 65013CD0
P 7550 3650
F 0 "R641" H 7450 3850 50  0000 L CNN
F 1 "1K" V 7550 3650 50  0000 C CNN
F 2 "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P2.54mm_Vertical" V 7480 3650 50  0001 C CNN
F 3 "~" H 7550 3650 50  0001 C CNN
	1    7550 3650
	1    0    0    -1  
$EndComp
$Comp
L Device:R R642
U 1 1 6501629E
P 7850 4450
F 0 "R642" V 7750 4350 50  0000 L CNN
F 1 "330" V 7850 4450 50  0000 C CNN
F 2 "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P2.54mm_Vertical" V 7780 4450 50  0001 C CNN
F 3 "~" H 7850 4450 50  0001 C CNN
	1    7850 4450
	1    0    0    -1  
$EndComp
$Comp
L Device:R R639
U 1 1 65016CE9
P 7250 4450
F 0 "R639" V 7350 4350 50  0000 L CNN
F 1 "3K3" V 7250 4450 50  0000 C CNN
F 2 "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P2.54mm_Vertical" V 7180 4450 50  0001 C CNN
F 3 "~" H 7250 4450 50  0001 C CNN
	1    7250 4450
	-1   0    0    1   
$EndComp
$Comp
L Device:R R638
U 1 1 65017690
P 7250 3650
F 0 "R638" H 7150 3850 50  0000 L CNN
F 1 "6K8" V 7250 3650 50  0000 C CNN
F 2 "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P2.54mm_Vertical" V 7180 3650 50  0001 C CNN
F 3 "~" H 7250 3650 50  0001 C CNN
	1    7250 3650
	1    0    0    -1  
$EndComp
$Comp
L Device:R R646
U 1 1 65018B26
P 7050 4250
F 0 "R646" V 7150 4150 50  0000 L CNN
F 1 "56K" V 7050 4250 50  0000 C CNN
F 2 "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P2.54mm_Vertical" V 6980 4250 50  0001 C CNN
F 3 "~" H 7050 4250 50  0001 C CNN
	1    7050 4250
	-1   0    0    1   
$EndComp
$Comp
L Device:R R645
U 1 1 650196F5
P 6850 4250
F 0 "R645" V 6950 4150 50  0000 L CNN
F 1 "22K" V 6850 4250 50  0000 C CNN
F 2 "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P2.54mm_Vertical" V 6780 4250 50  0001 C CNN
F 3 "~" H 6850 4250 50  0001 C CNN
	1    6850 4250
	-1   0    0    1   
$EndComp
$Comp
L Device:R R644
U 1 1 6501A0DC
P 6650 4250
F 0 "R644" V 6750 4150 50  0000 L CNN
F 1 "12K" V 6650 4250 50  0000 C CNN
F 2 "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P2.54mm_Vertical" V 6580 4250 50  0001 C CNN
F 3 "~" H 6650 4250 50  0001 C CNN
	1    6650 4250
	-1   0    0    1   
$EndComp
$Comp
L Device:R R643
U 1 1 6502E448
P 6750 3900
F 0 "R643" V 6850 3900 50  0000 C CNN
F 1 "4K7" V 6750 3900 50  0000 C CNN
F 2 "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P2.54mm_Vertical" V 6680 3900 50  0001 C CNN
F 3 "~" H 6750 3900 50  0001 C CNN
	1    6750 3900
	0    -1   -1   0   
$EndComp
$Comp
L Device:R R640
U 1 1 6502F127
P 7550 4450
F 0 "R640" V 7650 4350 50  0000 L CNN
F 1 "1K" V 7550 4450 50  0000 C CNN
F 2 "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P2.54mm_Vertical" V 7480 4450 50  0001 C CNN
F 3 "~" H 7550 4450 50  0001 C CNN
	1    7550 4450
	-1   0    0    1   
$EndComp
$Comp
L Device:R R657
U 1 1 65030F60
P 9500 5650
F 0 "R657" V 9400 5650 50  0000 C CNN
F 1 "75" V 9500 5650 50  0000 C CNN
F 2 "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P2.54mm_Vertical" V 9430 5650 50  0001 C CNN
F 3 "~" H 9500 5650 50  0001 C CNN
	1    9500 5650
	1    0    0    1   
$EndComp
$Comp
L Device:R R647
U 1 1 65031F66
P 9700 5650
F 0 "R647" V 9600 5650 50  0000 C CNN
F 1 "75" V 9700 5650 50  0000 C CNN
F 2 "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P2.54mm_Vertical" V 9630 5650 50  0001 C CNN
F 3 "~" H 9700 5650 50  0001 C CNN
	1    9700 5650
	1    0    0    1   
$EndComp
$Comp
L Device:CP C611
U 1 1 650335EC
P 9500 5250
F 0 "C611" H 9700 5250 50  0000 C CNN
F 1 "100µ" H 9650 5150 50  0000 C CNN
F 2 "Capacitor_THT:CP_Radial_D4.0mm_P1.50mm" H 9538 5100 50  0001 C CNN
F 3 "~" H 9500 5250 50  0001 C CNN
	1    9500 5250
	-1   0    0    -1  
$EndComp
$Comp
L Device:CP C612
U 1 1 65033D50
P 9700 5250
F 0 "C612" H 9500 5250 50  0000 C CNN
F 1 "100µ" H 9550 5150 50  0000 C CNN
F 2 "Capacitor_THT:CP_Radial_D4.0mm_P1.50mm" H 9738 5100 50  0001 C CNN
F 3 "~" H 9700 5250 50  0001 C CNN
	1    9700 5250
	-1   0    0    -1  
$EndComp
Wire Wire Line
	7250 3800 7250 4100
Connection ~ 7250 4100
Wire Wire Line
	7250 4100 7250 4300
Wire Wire Line
	7250 4600 7550 4600
Connection ~ 7550 4600
Wire Wire Line
	7550 4600 7850 4600
Wire Wire Line
	7850 3700 7850 3500
Wire Wire Line
	7850 3500 7550 3500
Connection ~ 7550 3500
Wire Wire Line
	7550 3500 7250 3500
Wire Wire Line
	6900 3900 7550 3900
Connection ~ 7550 3900
Wire Wire Line
	7550 3900 7550 3800
Text Label 7500 3900 2    50   ~ 0
UR
Text Label 6800 4100 2    50   ~ 0
R_BIAS
Text Label 7550 4300 0    50   ~ 0
ER
Text Label 7850 4200 0    50   ~ 0
R_BUF
$Comp
L Transistor_BJT:BC548 Q610
U 1 1 6508FD52
P 9100 4100
F 0 "Q610" H 8900 4250 50  0000 L CNN
F 1 "BC548" H 8950 3950 50  0000 L CNN
F 2 "Package_TO_SOT_THT:TO-92_Inline" H 9300 4025 50  0001 L CIN
F 3 "http://www.fairchildsemi.com/ds/BC/BC547.pdf" H 9100 4100 50  0001 L CNN
	1    9100 4100
	1    0    0    -1  
$EndComp
$Comp
L Transistor_BJT:BC548 Q611
U 1 1 6508FD5C
P 9400 3900
F 0 "Q611" H 9250 4050 50  0000 L CNN
F 1 "BC548" H 9250 3750 50  0000 L CNN
F 2 "Package_TO_SOT_THT:TO-92_Inline" H 9600 3825 50  0001 L CIN
F 3 "http://www.fairchildsemi.com/ds/BC/BC547.pdf" H 9400 3900 50  0001 L CNN
	1    9400 3900
	1    0    0    -1  
$EndComp
$Comp
L Device:R R651
U 1 1 6508FD66
P 9200 3650
F 0 "R651" H 9100 3850 50  0000 L CNN
F 1 "1K" V 9200 3650 50  0000 C CNN
F 2 "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P2.54mm_Vertical" V 9130 3650 50  0001 C CNN
F 3 "~" H 9200 3650 50  0001 C CNN
	1    9200 3650
	1    0    0    -1  
$EndComp
$Comp
L Device:R R652
U 1 1 6508FD70
P 9500 4450
F 0 "R652" V 9400 4350 50  0000 L CNN
F 1 "330" V 9500 4450 50  0000 C CNN
F 2 "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P2.54mm_Vertical" V 9430 4450 50  0001 C CNN
F 3 "~" H 9500 4450 50  0001 C CNN
	1    9500 4450
	1    0    0    -1  
$EndComp
$Comp
L Device:R R649
U 1 1 6508FD7A
P 8900 4450
F 0 "R649" V 9000 4350 50  0000 L CNN
F 1 "3K3" V 8900 4450 50  0000 C CNN
F 2 "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P2.54mm_Vertical" V 8830 4450 50  0001 C CNN
F 3 "~" H 8900 4450 50  0001 C CNN
	1    8900 4450
	-1   0    0    1   
$EndComp
$Comp
L Device:R R648
U 1 1 6508FD84
P 8900 3650
F 0 "R648" H 8800 3850 50  0000 L CNN
F 1 "6K8" V 8900 3650 50  0000 C CNN
F 2 "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P2.54mm_Vertical" V 8830 3650 50  0001 C CNN
F 3 "~" H 8900 3650 50  0001 C CNN
	1    8900 3650
	1    0    0    -1  
$EndComp
$Comp
L Device:R R656
U 1 1 6508FD8E
P 8700 4250
F 0 "R656" V 8800 4150 50  0000 L CNN
F 1 "33K" V 8700 4250 50  0000 C CNN
F 2 "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P2.54mm_Vertical" V 8630 4250 50  0001 C CNN
F 3 "~" H 8700 4250 50  0001 C CNN
	1    8700 4250
	-1   0    0    1   
$EndComp
$Comp
L Device:R R655
U 1 1 6508FD98
P 8500 4250
F 0 "R655" V 8600 4150 50  0000 L CNN
F 1 "27K" V 8500 4250 50  0000 C CNN
F 2 "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P2.54mm_Vertical" V 8430 4250 50  0001 C CNN
F 3 "~" H 8500 4250 50  0001 C CNN
	1    8500 4250
	-1   0    0    1   
$EndComp
$Comp
L Device:R R654
U 1 1 6508FDA2
P 8300 4250
F 0 "R654" V 8400 4150 50  0000 L CNN
F 1 "15K" V 8300 4250 50  0000 C CNN
F 2 "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P2.54mm_Vertical" V 8230 4250 50  0001 C CNN
F 3 "~" H 8300 4250 50  0001 C CNN
	1    8300 4250
	-1   0    0    1   
$EndComp
$Comp
L Device:R R653
U 1 1 6508FDAC
P 8400 3900
F 0 "R653" V 8500 3900 50  0000 C CNN
F 1 "4K7" V 8400 3900 50  0000 C CNN
F 2 "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P2.54mm_Vertical" V 8330 3900 50  0001 C CNN
F 3 "~" H 8400 3900 50  0001 C CNN
	1    8400 3900
	0    -1   -1   0   
$EndComp
$Comp
L Device:R R650
U 1 1 6508FDB6
P 9200 4450
F 0 "R650" V 9300 4350 50  0000 L CNN
F 1 "1K" V 9200 4450 50  0000 C CNN
F 2 "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P2.54mm_Vertical" V 9130 4450 50  0001 C CNN
F 3 "~" H 9200 4450 50  0001 C CNN
	1    9200 4450
	-1   0    0    1   
$EndComp
Wire Wire Line
	8900 3800 8900 4100
Connection ~ 8900 4100
Wire Wire Line
	8900 4100 8900 4300
Wire Wire Line
	8900 4600 9200 4600
Connection ~ 9200 4600
Wire Wire Line
	9200 4600 9500 4600
Wire Wire Line
	9500 3700 9500 3500
Wire Wire Line
	9500 3500 9200 3500
Connection ~ 9200 3500
Wire Wire Line
	9200 3500 8900 3500
Wire Wire Line
	8550 3900 9200 3900
Connection ~ 9200 3900
Wire Wire Line
	9200 3900 9200 3800
Text Label 9150 3900 2    50   ~ 0
UB
Text Label 8450 4100 2    50   ~ 0
B_BIAS
Text Label 9200 4300 0    50   ~ 0
EB
Text Label 9500 4200 0    50   ~ 0
B_BUF
Wire Wire Line
	7850 4600 8900 4600
Connection ~ 7850 4600
Connection ~ 8900 4600
Connection ~ 7850 3500
Connection ~ 8900 3500
$Comp
L power:+5V #PWR0171
U 1 1 650BB449
P 9500 3500
F 0 "#PWR0171" H 9500 3350 50  0001 C CNN
F 1 "+5V" H 9515 3673 50  0000 C CNN
F 2 "" H 9500 3500 50  0001 C CNN
F 3 "" H 9500 3500 50  0001 C CNN
	1    9500 3500
	1    0    0    -1  
$EndComp
Connection ~ 9500 3500
$Comp
L power:GND #PWR0172
U 1 1 650BC028
P 9500 4600
F 0 "#PWR0172" H 9500 4350 50  0001 C CNN
F 1 "GND" H 9505 4427 50  0000 C CNN
F 2 "" H 9500 4600 50  0001 C CNN
F 3 "" H 9500 4600 50  0001 C CNN
	1    9500 4600
	1    0    0    -1  
$EndComp
Connection ~ 9500 4600
Wire Wire Line
	6600 3900 6500 3900
Wire Wire Line
	6500 3900 6500 4700
Wire Wire Line
	6500 4700 8700 4700
Wire Wire Line
	8700 4700 8700 4400
Wire Wire Line
	6650 4400 6650 4800
Wire Wire Line
	6650 4800 8300 4800
Wire Wire Line
	8300 4800 8300 4400
Wire Wire Line
	6850 4400 6850 4900
Wire Wire Line
	6850 4900 8500 4900
Wire Wire Line
	8500 4900 8500 4400
Wire Wire Line
	7050 4400 7050 5000
Wire Wire Line
	7050 5000 8150 5000
Wire Wire Line
	8150 5000 8150 3900
Wire Wire Line
	8150 3900 8250 3900
Text GLabel 6500 4700 3    50   Input ~ 0
DRED
Text GLabel 6650 4800 3    50   Input ~ 0
DGHI
Text GLabel 6850 4900 3    50   Input ~ 0
DGLO
Text GLabel 7050 5000 3    50   Input ~ 0
DBLU
Text Label 9500 5100 2    50   ~ 0
R_BUF
Wire Wire Line
	9500 4250 9500 4300
Wire Wire Line
	9500 4100 9500 4250
Connection ~ 9500 4250
Wire Wire Line
	9500 4250 9700 4250
Wire Wire Line
	7850 4250 7850 4300
Wire Wire Line
	7850 4100 7850 4250
Connection ~ 7850 4250
Wire Wire Line
	7850 4250 8050 4250
Wire Wire Line
	8050 4250 8050 5100
Wire Wire Line
	8050 5100 9500 5100
Wire Wire Line
	9700 4250 9700 5100
$Comp
L Device:CP C613
U 1 1 652190BF
P 9800 3650
F 0 "C613" H 9918 3696 50  0000 L CNN
F 1 "470µ" H 9918 3605 50  0000 L CNN
F 2 "Capacitor_THT:CP_Radial_D6.3mm_P2.50mm" H 9838 3500 50  0001 C CNN
F 3 "~" H 9800 3650 50  0001 C CNN
	1    9800 3650
	1    0    0    -1  
$EndComp
Wire Wire Line
	9800 3500 9500 3500
$Comp
L power:GND #PWR0173
U 1 1 65227A48
P 9800 3800
F 0 "#PWR0173" H 9800 3550 50  0001 C CNN
F 1 "GND" H 9805 3627 50  0000 C CNN
F 2 "" H 9800 3800 50  0001 C CNN
F 3 "" H 9800 3800 50  0001 C CNN
	1    9800 3800
	1    0    0    -1  
$EndComp
Wire Wire Line
	9500 5400 9500 5500
Wire Wire Line
	9700 5400 9700 5500
Text Label 9500 5500 2    50   ~ 0
PR_C
Text Label 9700 5500 0    50   ~ 0
PB_C
Wire Wire Line
	6650 4100 6850 4100
Connection ~ 6850 4100
Wire Wire Line
	6850 4100 7050 4100
Connection ~ 7050 4100
Wire Wire Line
	7050 4100 7250 4100
Wire Wire Line
	8300 4100 8500 4100
Connection ~ 8500 4100
Wire Wire Line
	7850 3500 8900 3500
Wire Wire Line
	8500 4100 8700 4100
Connection ~ 8700 4100
Wire Wire Line
	8700 4100 8900 4100
Text Label 2800 5100 2    50   ~ 0
R_SW
Text Label 3450 5200 2    50   ~ 0
N_SW
$Comp
L Jumper:Jumper_3_Bridged12 JP3
U 1 1 64F320DA
P 1400 800
F 0 "JP3" V 1250 600 50  0000 L CNN
F 1 "SWITCH" H 1300 900 50  0000 L CNN
F 2 "durango:PowerSwitch" H 1400 800 50  0001 C CNN
F 3 "~" H 1400 800 50  0001 C CNN
	1    1400 800 
	-1   0    0    -1  
$EndComp
NoConn ~ 1650 800 
Wire Wire Line
	1700 1400 1700 1650
Connection ~ 1700 1100
Connection ~ 1700 1400
Wire Wire Line
	1150 1100 1400 1100
Wire Wire Line
	1400 950  1400 1100
Connection ~ 1400 1100
Wire Wire Line
	1400 1100 1700 1100
Wire Wire Line
	9700 1000 9500 1000
Wire Wire Line
	9700 1100 9500 1100
Wire Wire Line
	9700 1200 9500 1200
Wire Wire Line
	9700 1400 9500 1400
Wire Wire Line
	9700 1500 9500 1500
Wire Wire Line
	9700 1600 9500 1600
Wire Wire Line
	9700 1700 9500 1700
Wire Wire Line
	9700 1800 9500 1800
Wire Wire Line
	9700 1900 9500 1900
Wire Wire Line
	9700 2000 9500 2000
Wire Wire Line
	9700 2100 9500 2100
Wire Wire Line
	9700 2200 9500 2200
Text Label 9700 2400 2    50   ~ 0
MA0
Text Label 9700 2200 2    50   ~ 0
MA1
Text Label 9700 1700 2    50   ~ 0
MA2
Text Label 9700 1600 2    50   ~ 0
MA3
Text Label 9700 1500 2    50   ~ 0
MA4
Text Label 9700 1300 2    50   ~ 0
MA5
Text Label 9700 1400 2    50   ~ 0
MA6
Text Label 9700 1200 2    50   ~ 0
MA7
Text Label 9700 2000 2    50   ~ 0
MA8
Text Label 9700 1100 2    50   ~ 0
MA9
Text Label 9700 1000 2    50   ~ 0
MA10
Text Label 9700 2100 2    50   ~ 0
MA11
Text Label 9700 1800 2    50   ~ 0
MA12
Text Label 9700 1900 2    50   ~ 0
MA13
Text Label 10900 1700 0    50   ~ 0
D0
Text Label 10900 1600 0    50   ~ 0
D1
Text Label 10900 1500 0    50   ~ 0
D2
Text Label 10900 1400 0    50   ~ 0
D3
Text Label 10900 1200 0    50   ~ 0
D4
Text Label 10900 1300 0    50   ~ 0
D5
Text Label 10900 1100 0    50   ~ 0
D7
Text Label 9700 2300 2    50   ~ 0
MA14
$Comp
L power:GND #PWR?
U 1 1 6500E44F
P 10300 3100
AR Path="/6500E44F" Ref="#PWR?"  Part="1" 
AR Path="/6310B9C7/6500E44F" Ref="#PWR0174"  Part="1" 
F 0 "#PWR0174" H 10300 2850 50  0001 C CNN
F 1 "GND" H 10305 2927 50  0000 C CNN
F 2 "" H 10300 3100 50  0001 C CNN
F 3 "" H 10300 3100 50  0001 C CNN
	1    10300 3100
	1    0    0    -1  
$EndComp
Wire Wire Line
	9700 2700 9650 2700
Wire Wire Line
	9650 2700 9650 3100
Wire Wire Line
	9650 3100 10300 3100
Text Label 10900 1000 0    50   ~ 0
D6
$Comp
L power:+5V #PWR0175
U 1 1 650F616A
P 10300 700
F 0 "#PWR0175" H 10300 550 50  0001 C CNN
F 1 "+5V" H 10315 873 50  0000 C CNN
F 2 "" H 10300 700 50  0001 C CNN
F 3 "" H 10300 700 50  0001 C CNN
	1    10300 700 
	1    0    0    -1  
$EndComp
Text Notes 10200 700  2    50   ~ 0
Alternative narrow SRAM footprint
Wire Wire Line
	9700 2300 9500 2300
Wire Wire Line
	9700 2400 9500 2400
Wire Wire Line
	10900 1000 11000 1000
Wire Wire Line
	10900 1100 11000 1100
Wire Wire Line
	10900 1200 11000 1200
Wire Wire Line
	10900 1300 11000 1300
Wire Wire Line
	10900 1400 11000 1400
Wire Wire Line
	10900 1500 11000 1500
Wire Wire Line
	10900 1600 11000 1600
Wire Wire Line
	10900 1700 11000 1700
Entry Wire Line
	11000 1000 11100 900 
Entry Wire Line
	11000 1100 11100 1000
Entry Wire Line
	11000 1200 11100 1100
Entry Wire Line
	11000 1300 11100 1200
Entry Wire Line
	11000 1400 11100 1300
Entry Wire Line
	11000 1500 11100 1400
Entry Wire Line
	11000 1600 11100 1500
Entry Wire Line
	11000 1700 11100 1600
Text GLabel 11100 900  1    50   Input ~ 0
D[0..7]
Entry Wire Line
	9400 900  9500 1000
Entry Wire Line
	9400 1000 9500 1100
Entry Wire Line
	9400 1100 9500 1200
Entry Wire Line
	9400 1200 9500 1300
Entry Wire Line
	9400 1300 9500 1400
Entry Wire Line
	9400 1400 9500 1500
Entry Wire Line
	9400 1500 9500 1600
Entry Wire Line
	9400 1600 9500 1700
Entry Wire Line
	9400 1700 9500 1800
Entry Wire Line
	9400 1800 9500 1900
Entry Wire Line
	9400 1900 9500 2000
Entry Wire Line
	9400 2000 9500 2100
Entry Wire Line
	9400 2100 9500 2200
Entry Wire Line
	9400 2200 9500 2300
Entry Wire Line
	9400 2300 9500 2400
Text GLabel 9400 900  0    50   Input ~ 0
MA[0..14]
Text GLabel 9700 2800 0    50   Input ~ 0
~DWE
Connection ~ 10300 3100
Wire Wire Line
	9700 1300 9500 1300
$Comp
L 62256:62256 U?
U 1 1 6500E3FF
P 10300 1900
AR Path="/6500E3FF" Ref="U?"  Part="1" 
AR Path="/6310B9C7/6500E3FF" Ref="U003"  Part="1" 
F 0 "U003" H 10050 3000 50  0000 C CNN
F 1 "62256" H 10500 3000 50  0000 C CNN
F 2 "Package_DIP:DIP-28_W7.62mm_Socket" H 10300 1900 50  0001 C CNN
F 3 "http://www.6502.org/users/alexis/62256.pdf" H 10300 1900 50  0001 C CNN
	1    10300 1900
	1    0    0    -1  
$EndComp
Text GLabel 9700 2600 0    50   Input ~ 0
~MCS
Wire Wire Line
	850  5100 1350 5100
Wire Bus Line
	1050 6400 1050 6900
Wire Bus Line
	5650 4400 5650 4850
Wire Bus Line
	3700 2150 3700 2700
Wire Bus Line
	2300 5200 2300 5700
Wire Bus Line
	2450 4400 2450 5750
Wire Bus Line
	2150 6300 2150 7000
Wire Bus Line
	11100 900  11100 1600
Wire Bus Line
	900  2150 900  5700
Wire Bus Line
	750  2150 750  5750
Wire Bus Line
	9400 900  9400 2300
$EndSCHEMATC
