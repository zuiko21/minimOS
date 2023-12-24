EESchema Schematic File Version 4
LIBS:cart2832bbspsg-cache
EELAYER 29 0
EELAYER END
$Descr A4 11693 8268
encoding utf-8
Sheet 1 1
Title "Universal Durango·X cartridge"
Date "2023-12-20"
Rev "v1"
Comp "@zuiko21"
Comment1 "28-32 pin cartridge + bankswitching + PSG"
Comment2 ""
Comment3 ""
Comment4 ""
$EndDescr
$Comp
L edge_conn:Durango_ROM J1
U 1 1 6482016A
P 2350 2300
F 0 "J1" H 2100 1250 50  0000 C CNN
F 1 "Durango ROM" H 2650 1250 50  0000 C CNN
F 2 "edge_conn:Durango_ROM" H 2050 1300 50  0001 C CNN
F 3 "" H 2050 1300 50  0001 C CNN
	1    2350 2300
	1    0    0    1   
$EndComp
$Comp
L 74xx:74LS174 U12
U 1 1 6482525C
P 3900 1950
F 0 "U12" H 3675 2500 50  0000 C CNN
F 1 "74HC174" H 4100 2500 50  0000 C CNN
F 2 "Package_DIP:DIP-16_W7.62mm" H 3900 1950 50  0001 C CNN
F 3 "http://www.ti.com/lit/gpn/sn74LS174" H 3900 1950 50  0001 C CNN
	1    3900 1950
	1    0    0    -1  
$EndComp
Text Notes 8275 6375 0    100  ~ 20
Bankswitching = $DFFC-$DFFF\nPSG = $DFD8-$DFDB\nUx = common\nU1x = for Bank Switching\nU2x = for PSG\nU3x = for both
$Comp
L power:GND #PWR0101
U 1 1 6482AC66
P 3900 4700
F 0 "#PWR0101" H 3900 4450 50  0001 C CNN
F 1 "GND" H 3905 4527 50  0000 C CNN
F 2 "" H 3900 4700 50  0001 C CNN
F 3 "" H 3900 4700 50  0001 C CNN
	1    3900 4700
	1    0    0    -1  
$EndComp
Wire Wire Line
	3900 4700 5500 4700
Text Label 1900 1350 2    50   ~ 0
~RESET
Text Label 3400 2450 2    50   ~ 0
~RESET
Text Label 3400 2250 2    50   ~ 0
~LATCH
Wire Wire Line
	3900 3400 2350 3400
Wire Wire Line
	3900 1250 5500 1250
Wire Wire Line
	5500 1250 5500 1350
$Comp
L power:+5V #PWR0102
U 1 1 6482D0FC
P 5500 1250
F 0 "#PWR0102" H 5500 1100 50  0001 C CNN
F 1 "+5V" H 5515 1423 50  0000 C CNN
F 2 "" H 5500 1250 50  0001 C CNN
F 3 "" H 5500 1250 50  0001 C CNN
	1    5500 1250
	1    0    0    -1  
$EndComp
Connection ~ 5500 1250
$Comp
L power:+5V #PWR0103
U 1 1 6482D298
P 3900 3400
F 0 "#PWR0103" H 3900 3250 50  0001 C CNN
F 1 "+5V" H 3915 3573 50  0000 C CNN
F 2 "" H 3900 3400 50  0001 C CNN
F 3 "" H 3900 3400 50  0001 C CNN
	1    3900 3400
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR0104
U 1 1 6482D479
P 3900 2750
F 0 "#PWR0104" H 3900 2500 50  0001 C CNN
F 1 "GND" H 3905 2577 50  0000 C CNN
F 2 "" H 3900 2750 50  0001 C CNN
F 3 "" H 3900 2750 50  0001 C CNN
	1    3900 2750
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR0105
U 1 1 6482D64D
P 2350 1200
F 0 "#PWR0105" H 2350 950 50  0001 C CNN
F 1 "GND" H 2355 1027 50  0000 C CNN
F 2 "" H 2350 1200 50  0001 C CNN
F 3 "" H 2350 1200 50  0001 C CNN
	1    2350 1200
	-1   0    0    1   
$EndComp
NoConn ~ 2750 2750
NoConn ~ 2750 2850
Wire Wire Line
	2750 2550 2800 2550
Wire Wire Line
	2800 2550 2800 5100
Wire Wire Line
	2750 2450 2850 2450
Wire Wire Line
	2850 2450 2850 5000
Text Label 4650 5100 0    50   ~ 0
~CS
Text Label 4950 5000 0    50   ~ 0
~OE
Wire Wire Line
	2750 1550 2950 1550
Wire Wire Line
	2750 1650 2950 1650
Wire Wire Line
	2750 1750 2950 1750
Wire Wire Line
	2750 1850 2950 1850
Wire Wire Line
	2750 1950 2950 1950
Wire Wire Line
	2750 2050 2950 2050
Wire Wire Line
	2750 2150 2950 2150
Wire Wire Line
	2750 2250 2950 2250
Entry Wire Line
	2950 1550 3050 1450
Entry Wire Line
	2950 1650 3050 1550
Entry Wire Line
	2950 1750 3050 1650
Entry Wire Line
	2950 1850 3050 1750
Entry Wire Line
	2950 1950 3050 1850
Entry Wire Line
	2950 2050 3050 1950
Entry Wire Line
	2950 2150 3050 2050
Entry Wire Line
	2950 2250 3050 2150
Text Label 2800 1550 0    50   ~ 0
D0
Text Label 2800 1650 0    50   ~ 0
D1
Text Label 2800 1750 0    50   ~ 0
D2
Text Label 2800 1850 0    50   ~ 0
D3
Text Label 2800 1950 0    50   ~ 0
D4
Text Label 2800 2050 0    50   ~ 0
D5
Text Label 2800 2150 0    50   ~ 0
D6
Text Label 2800 2250 0    50   ~ 0
D7
Wire Bus Line
	3050 1000 6250 1000
Entry Wire Line
	6150 1550 6250 1450
Entry Wire Line
	6150 1650 6250 1550
Entry Wire Line
	6150 1750 6250 1650
Entry Wire Line
	6150 1850 6250 1750
Entry Wire Line
	6150 1950 6250 1850
Entry Wire Line
	6150 2050 6250 1950
Entry Wire Line
	6150 2150 6250 2050
Entry Wire Line
	6150 2250 6250 2150
Wire Wire Line
	6150 1550 5900 1550
Wire Wire Line
	5900 1650 6150 1650
Wire Wire Line
	5900 1750 6150 1750
Wire Wire Line
	6150 1850 5900 1850
Wire Wire Line
	5900 1950 6150 1950
Wire Wire Line
	6150 2050 5900 2050
Wire Wire Line
	5900 2150 6150 2150
Wire Wire Line
	6150 2250 5900 2250
Text Label 5950 1550 0    50   ~ 0
D0
Text Label 5950 1650 0    50   ~ 0
D1
Text Label 5950 1750 0    50   ~ 0
D2
Text Label 5950 1850 0    50   ~ 0
D3
Text Label 5950 1950 0    50   ~ 0
D4
Text Label 5950 2050 0    50   ~ 0
D5
Text Label 5950 2150 0    50   ~ 0
D6
Text Label 5950 2250 0    50   ~ 0
D7
Wire Wire Line
	1700 1550 1950 1550
Wire Wire Line
	1700 1650 1950 1650
Wire Wire Line
	1700 1750 1950 1750
Wire Wire Line
	1700 1850 1950 1850
Wire Wire Line
	1700 1950 1950 1950
Wire Wire Line
	1700 2050 1950 2050
Wire Wire Line
	1700 2150 1950 2150
Wire Wire Line
	1700 2250 1950 2250
Wire Wire Line
	1700 2350 1950 2350
Wire Wire Line
	1700 2450 1950 2450
Wire Wire Line
	1700 2550 1950 2550
Wire Wire Line
	1700 2650 1950 2650
Wire Wire Line
	1700 2750 1950 2750
Wire Wire Line
	1700 2850 1950 2850
Text Label 1750 1550 0    50   ~ 0
A0
Text Label 1750 1650 0    50   ~ 0
A1
Text Label 1750 1750 0    50   ~ 0
A2
Text Label 1750 1850 0    50   ~ 0
A3
Text Label 1750 1950 0    50   ~ 0
A4
Text Label 1750 2050 0    50   ~ 0
A5
Text Label 1750 2150 0    50   ~ 0
A6
Text Label 1750 2250 0    50   ~ 0
A7
Text Label 1750 2350 0    50   ~ 0
A8
Text Label 1750 2450 0    50   ~ 0
A9
Text Label 1750 2550 0    50   ~ 0
A10
Text Label 1750 2650 0    50   ~ 0
A11
Text Label 1750 2750 0    50   ~ 0
A12
Text Label 1750 2850 0    50   ~ 0
A13
Wire Wire Line
	4850 1550 5100 1550
Wire Wire Line
	4850 1650 5100 1650
Wire Wire Line
	4850 1750 5100 1750
Wire Wire Line
	4850 1850 5100 1850
Wire Wire Line
	4850 1950 5100 1950
Wire Wire Line
	4850 2050 5100 2050
Wire Wire Line
	4850 2150 5100 2150
Wire Wire Line
	4850 2250 5100 2250
Wire Wire Line
	4850 2350 5100 2350
Wire Wire Line
	4850 2450 5100 2450
Wire Wire Line
	4850 2550 5100 2550
Wire Wire Line
	4850 2650 5100 2650
Wire Wire Line
	4850 2750 5100 2750
Text Label 4900 1550 0    50   ~ 0
A0
Text Label 4900 1650 0    50   ~ 0
A1
Text Label 4900 1750 0    50   ~ 0
A2
Text Label 4900 1850 0    50   ~ 0
A3
Text Label 4900 1950 0    50   ~ 0
A4
Text Label 4900 2050 0    50   ~ 0
A5
Text Label 4900 2150 0    50   ~ 0
A6
Text Label 4900 2250 0    50   ~ 0
A7
Text Label 4900 2350 0    50   ~ 0
A8
Text Label 4900 2450 0    50   ~ 0
A9
Text Label 4900 2550 0    50   ~ 0
A10
Text Label 4900 2650 0    50   ~ 0
A11
Text Label 4900 2750 0    50   ~ 0
A12
Text Label 5100 2850 2    50   ~ 0
MA13
Entry Wire Line
	1600 1450 1700 1550
Entry Wire Line
	1600 1550 1700 1650
Entry Wire Line
	1600 1650 1700 1750
Entry Wire Line
	1600 1750 1700 1850
Entry Wire Line
	1600 1850 1700 1950
Entry Wire Line
	1600 1950 1700 2050
Entry Wire Line
	1600 2050 1700 2150
Entry Wire Line
	1600 2150 1700 2250
Entry Wire Line
	1600 2250 1700 2350
Entry Wire Line
	1600 2350 1700 2450
Entry Wire Line
	1600 2450 1700 2550
Entry Wire Line
	1600 2550 1700 2650
Entry Wire Line
	1600 2650 1700 2750
Entry Wire Line
	1600 2750 1700 2850
Entry Wire Line
	4750 1450 4850 1550
Entry Wire Line
	4750 1550 4850 1650
Entry Wire Line
	4750 1650 4850 1750
Entry Wire Line
	4750 1750 4850 1850
Entry Wire Line
	4750 1850 4850 1950
Entry Wire Line
	4750 1950 4850 2050
Entry Wire Line
	4750 2050 4850 2150
Entry Wire Line
	4750 2150 4850 2250
Entry Wire Line
	4750 2250 4850 2350
Entry Wire Line
	4750 2350 4850 2450
Entry Wire Line
	4750 2450 4850 2550
Entry Wire Line
	4750 2550 4850 2650
Entry Wire Line
	4750 2650 4850 2750
Wire Bus Line
	4750 950  1600 950 
Text GLabel 1600 950  0    50   Input ~ 0
A[0..14]
Text GLabel 6250 1000 2    50   Input ~ 0
D[0..7]
Text Label 5100 2950 2    50   ~ 0
MA14
Text Label 5100 3050 2    50   ~ 0
MA15
Text Label 5100 3150 2    50   ~ 0
BA2
Entry Wire Line
	3050 1450 3150 1550
Entry Wire Line
	3050 1550 3150 1650
Entry Wire Line
	3050 1650 3150 1750
Wire Wire Line
	3150 1550 3400 1550
Wire Wire Line
	3150 1650 3400 1650
Wire Wire Line
	3150 1750 3400 1750
Text Label 3200 1650 0    50   ~ 0
D1
Text Label 3200 1750 0    50   ~ 0
D2
Text Label 4400 1550 0    50   ~ 0
BA0
Text Label 4400 1650 0    50   ~ 0
BA1
Text Label 4400 1750 0    50   ~ 0
BA2
Text Label 3200 1550 0    50   ~ 0
D0
Wire Wire Line
	1950 3200 1950 4400
Wire Wire Line
	1950 4400 3400 4400
Wire Wire Line
	1950 3100 1900 3100
Wire Wire Line
	1900 3100 1900 4300
Wire Wire Line
	1900 4300 3400 4300
Text Label 3250 4300 0    50   ~ 0
~IOC
Text Label 3250 4400 0    50   ~ 0
~WE
Entry Wire Line
	1600 3800 1700 3900
Entry Wire Line
	1600 3700 1700 3800
Entry Wire Line
	1600 3600 1700 3700
Wire Wire Line
	1700 3700 3400 3700
Wire Wire Line
	1700 3800 3400 3800
Wire Wire Line
	1700 3900 3400 3900
Text Label 1750 3800 0    50   ~ 0
A3
Text Label 1750 3900 0    50   ~ 0
A5
Text Label 1750 3700 0    50   ~ 0
A2
NoConn ~ 4400 3700
NoConn ~ 4400 3800
NoConn ~ 4400 4000
NoConn ~ 4400 4200
NoConn ~ 4400 4300
Wire Wire Line
	3400 2250 3050 2250
Wire Wire Line
	3050 2250 3050 4950
Wire Wire Line
	3050 4950 4400 4950
Wire Wire Line
	4400 4950 4400 4400
Text Label 4400 4500 0    50   ~ 0
~LATCH
Wire Wire Line
	3400 2450 3200 2450
Wire Wire Line
	3200 2450 3200 3500
Wire Wire Line
	3200 3500 1500 3500
Wire Wire Line
	1500 3500 1500 1350
Wire Wire Line
	1500 1350 1950 1350
$Comp
L Graphic:Logo_Open_Hardware_Small LOGO1
U 1 1 6483E578
P 10650 6050
F 0 "LOGO1" H 10650 6325 50  0001 C CNN
F 1 "Logo_Open_Hardware_Small" H 10650 5825 50  0001 C CNN
F 2 "durango:jaqueria" H 10650 6050 50  0001 C CNN
F 3 "~" H 10650 6050 50  0001 C CNN
	1    10650 6050
	1    0    0    -1  
$EndComp
$Comp
L Jumper:Jumper_3_Bridged12 JP1
U 1 1 6484669E
P 875 900
F 0 "JP1" V 921 967 50  0000 L CNN
F 1 "16/32K" V 830 967 50  0000 L CNN
F 2 "Jumper:SolderJumper-3_P1.3mm_Bridged12_RoundedPad1.0x1.5mm" H 875 900 50  0001 C CNN
F 3 "~" H 875 900 50  0001 C CNN
	1    875  900 
	0    -1   -1   0   
$EndComp
$Comp
L Memory_EPROM:27C080 U1
U 1 1 64874267
P 5500 2650
F 0 "U1" H 5250 3900 50  0000 C CNN
F 1 "27C16-080" H 5800 3900 50  0000 C CNN
F 2 "Package_DIP:DIP-32_W15.24mm" H 5500 2650 50  0001 C CNN
F 3 "http://ww1.microchip.com/downloads/en/devicedoc/doc0360.pdf" H 5500 2650 50  0001 C CNN
	1    5500 2650
	1    0    0    -1  
$EndComp
Wire Wire Line
	5500 3950 5500 4700
Wire Wire Line
	2850 5000 5100 5000
Wire Wire Line
	5100 5000 5100 3750
Wire Wire Line
	2800 5100 4800 5100
Wire Wire Line
	4800 5100 4800 3650
Wire Wire Line
	4800 3650 5100 3650
Text Label 4400 1850 0    50   ~ 0
BA3
Text Label 5100 3250 2    50   ~ 0
MA17
Entry Wire Line
	3050 1750 3150 1850
Entry Wire Line
	3050 1850 3150 1950
Entry Wire Line
	3050 1950 3150 2050
Wire Wire Line
	3150 1850 3400 1850
Wire Wire Line
	3150 1950 3400 1950
Wire Wire Line
	3150 2050 3400 2050
Text Label 3200 1950 0    50   ~ 0
D4
Text Label 3200 2050 0    50   ~ 0
D5
Text Label 3200 1850 0    50   ~ 0
D3
Wire Wire Line
	1700 2950 1950 2950
Text Label 1750 2950 0    50   ~ 0
A14
Entry Wire Line
	1600 2850 1700 2950
Text Label 5100 3350 2    50   ~ 0
MA18
Text Label 5100 3450 2    50   ~ 0
MA19
Text Label 4400 1950 0    50   ~ 0
BA4
Text Label 4400 2050 0    50   ~ 0
BA5
$Comp
L Jumper:Jumper_3_Bridged12 JP2
U 1 1 648D7A9C
P 875 1525
F 0 "JP2" V 921 1592 50  0000 L CNN
F 1 "27C040+" V 825 1550 50  0000 L CNN
F 2 "Jumper:SolderJumper-3_P1.3mm_Bridged12_RoundedPad1.0x1.5mm" H 875 1525 50  0001 C CNN
F 3 "~" H 875 1525 50  0001 C CNN
	1    875  1525
	0    -1   -1   0   
$EndComp
$Comp
L Jumper:Jumper_3_Bridged12 JP3
U 1 1 648DA578
P 875 2175
F 0 "JP3" V 921 2242 50  0000 L CNN
F 1 "27C080" V 825 2225 50  0000 L CNN
F 2 "Jumper:SolderJumper-3_P1.3mm_Bridged12_RoundedPad1.0x1.5mm" H 875 2175 50  0001 C CNN
F 3 "~" H 875 2175 50  0001 C CNN
	1    875  2175
	0    -1   -1   0   
$EndComp
Text Label 1025 900  0    50   ~ 0
UV14
Text Label 1025 1525 0    50   ~ 0
MA18
Text Label 1025 2175 0    50   ~ 0
MA19
$Comp
L power:+5V #PWR0106
U 1 1 648DB8D4
P 875 1775
F 0 "#PWR0106" H 875 1625 50  0001 C CNN
F 1 "+5V" V 890 1903 50  0000 L CNN
F 2 "" H 875 1775 50  0001 C CNN
F 3 "" H 875 1775 50  0001 C CNN
	1    875  1775
	0    -1   -1   0   
$EndComp
$Comp
L power:+5V #PWR0107
U 1 1 648DBECA
P 875 2425
F 0 "#PWR0107" H 875 2275 50  0001 C CNN
F 1 "+5V" V 890 2553 50  0000 L CNN
F 2 "" H 875 2425 50  0001 C CNN
F 3 "" H 875 2425 50  0001 C CNN
	1    875  2425
	0    -1   -1   0   
$EndComp
Text Label 875  1150 2    50   ~ 0
A14
Text Label 875  650  2    50   ~ 0
BA0
Text Label 875  1275 2    50   ~ 0
BA4
Text Label 875  1925 2    50   ~ 0
BA5
Text Label 9725 5150 0    50   ~ 0
AUDIO
Entry Wire Line
	6250 1450 6350 1550
Entry Wire Line
	6250 1550 6350 1650
Entry Wire Line
	6250 1650 6350 1750
Entry Wire Line
	6250 1750 6350 1850
Entry Wire Line
	6250 1850 6350 1950
Entry Wire Line
	6250 1950 6350 2050
Entry Wire Line
	6250 2050 6350 2150
Entry Wire Line
	6250 2150 6350 2250
Wire Wire Line
	6500 2250 6350 2250
Wire Wire Line
	6350 2150 6500 2150
Wire Wire Line
	6350 2050 6500 2050
Wire Wire Line
	6500 1950 6350 1950
Wire Wire Line
	6350 1850 6500 1850
Wire Wire Line
	6500 1750 6350 1750
Wire Wire Line
	6350 1650 6500 1650
Wire Wire Line
	6500 1550 6350 1550
Text Label 6400 2250 0    50   ~ 0
D0
Text Label 6400 2150 0    50   ~ 0
D1
Text Label 6400 2050 0    50   ~ 0
D2
Text Label 6400 1950 0    50   ~ 0
D3
Text Label 6400 1850 0    50   ~ 0
D7
Text Label 6400 1750 0    50   ~ 0
D6
Text Label 6400 1650 0    50   ~ 0
D4
Text Label 6400 1550 0    50   ~ 0
D5
$Comp
L Durango-X:SN76489A U24
U 1 1 65896AE6
P 8150 2350
F 0 "U24" H 8350 3300 50  0000 C CNN
F 1 "SN76489A" H 7950 3300 50  0000 C CNN
F 2 "Package_DIP:DIP-16_W7.62mm" H 7500 3400 50  0001 C CNN
F 3 "https://map.grauw.nl/resources/sound/texas_instruments_sn76489an.pdf" H 8150 2350 50  0001 C CNN
	1    8150 2350
	-1   0    0    -1  
$EndComp
Wire Wire Line
	7500 1950 7750 1950
Wire Wire Line
	7500 2050 7750 2050
Wire Wire Line
	7500 2150 7750 2150
Wire Wire Line
	7500 2250 7750 2250
Text Label 7500 1850 0    50   ~ 0
B7
Text Label 7500 1750 0    50   ~ 0
B6
Text Label 7500 1550 0    50   ~ 0
B5
Text Label 7500 1650 0    50   ~ 0
B4
Text Label 7575 1950 0    50   ~ 0
B3
Text Label 7575 2050 0    50   ~ 0
B2
Text Label 7575 2150 0    50   ~ 0
B1
Text Label 7575 2250 0    50   ~ 0
B0
Text Label 8600 900  2    50   ~ 0
VCLK
Wire Wire Line
	8150 2850 8150 2550
Wire Wire Line
	8150 1350 8150 1250
$Comp
L Transistor_BJT:BC548 Q21
U 1 1 659A2AD7
P 9500 2550
F 0 "Q21" H 9691 2596 50  0000 L CNN
F 1 "BC548" H 9691 2505 50  0000 L CNN
F 2 "Package_TO_SOT_THT:TO-92_Inline" H 9700 2475 50  0001 L CIN
F 3 "http://www.fairchildsemi.com/ds/BC/BC547.pdf" H 9500 2550 50  0001 L CNN
	1    9500 2550
	1    0    0    -1  
$EndComp
Wire Wire Line
	8150 2850 8700 2850
Connection ~ 8150 2850
$Comp
L Device:R R24
U 1 1 659AC542
P 9300 2700
F 0 "R24" H 9350 2700 50  0000 L CNN
F 1 "6K8" V 9300 2700 50  0000 C CNN
F 2 "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P10.16mm_Horizontal" V 9230 2700 50  0001 C CNN
F 3 "~" H 9300 2700 50  0001 C CNN
	1    9300 2700
	1    0    0    -1  
$EndComp
Connection ~ 9300 2850
Wire Wire Line
	9300 2850 9600 2850
Wire Wire Line
	9600 2750 9600 2850
$Comp
L Device:R R23
U 1 1 659B3A6E
P 9300 2400
F 0 "R23" H 9350 2400 50  0000 L CNN
F 1 "33K" V 9300 2400 50  0000 C CNN
F 2 "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P10.16mm_Horizontal" V 9230 2400 50  0001 C CNN
F 3 "~" H 9300 2400 50  0001 C CNN
	1    9300 2400
	1    0    0    -1  
$EndComp
Connection ~ 9300 2550
$Comp
L Device:R R21
U 1 1 659B3CD6
P 9100 2100
F 0 "R21" H 9150 2100 50  0000 L CNN
F 1 "15K" V 9100 2100 50  0000 C CIN
F 2 "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P10.16mm_Horizontal" V 9030 2100 50  0001 C CNN
F 3 "~" H 9100 2100 50  0001 C CNN
	1    9100 2100
	1    0    0    -1  
$EndComp
Wire Wire Line
	9100 2550 9300 2550
$Comp
L Device:CP C21
U 1 1 659BA836
P 8950 1550
F 0 "C21" V 9205 1550 50  0000 C CNN
F 1 "10µ" V 9114 1550 50  0000 C CNN
F 2 "Capacitor_THT:CP_Radial_D4.0mm_P1.50mm" H 8988 1400 50  0001 C CNN
F 3 "~" H 8950 1550 50  0001 C CNN
	1    8950 1550
	0    -1   -1   0   
$EndComp
Wire Wire Line
	9300 2250 9600 2250
Wire Wire Line
	9600 2250 9600 2350
$Comp
L Device:R R22
U 1 1 659C1734
P 9600 2100
F 0 "R22" H 9675 2100 50  0000 L CNN
F 1 "3K3" V 9600 2100 50  0000 C CNN
F 2 "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P10.16mm_Horizontal" V 9530 2100 50  0001 C CNN
F 3 "~" H 9600 2100 50  0001 C CNN
	1    9600 2100
	1    0    0    -1  
$EndComp
Connection ~ 9600 2250
$Comp
L Device:C C22
U 1 1 659C1DF4
P 9100 2700
F 0 "C22" H 8850 2750 50  0000 L CNN
F 1 "47n" H 8850 2650 50  0000 L CNN
F 2 "Capacitor_THT:C_Disc_D3.8mm_W2.6mm_P2.50mm" H 9138 2550 50  0001 C CNN
F 3 "~" H 9100 2700 50  0001 C CNN
	1    9100 2700
	1    0    0    -1  
$EndComp
Connection ~ 9100 2850
Wire Wire Line
	9100 2850 9300 2850
Wire Wire Line
	9600 1250 9600 1950
Connection ~ 8150 1250
Wire Wire Line
	2750 3050 2750 5150
Wire Wire Line
	9975 5150 9975 2250
Wire Wire Line
	9975 2250 9600 2250
Wire Wire Line
	2750 5150 9975 5150
Text Label 9100 2425 2    50   ~ 0
BIAS
Wire Wire Line
	8550 1550 8800 1550
Wire Wire Line
	9100 1550 9100 1950
Wire Wire Line
	9100 2250 9100 2550
Connection ~ 9100 2550
Text Label 8650 1550 0    50   ~ 0
AOUT
Text Label 9100 1950 2    50   ~ 0
AC
Wire Wire Line
	2750 1350 2950 1350
Wire Wire Line
	2950 900  8600 900 
Wire Wire Line
	8600 900  8600 2250
Wire Wire Line
	8600 2250 8550 2250
Wire Wire Line
	2950 900  2950 1350
$Comp
L Device:R R25
U 1 1 65A47B9E
P 10025 1400
F 0 "R25" H 10100 1400 50  0000 L CNN
F 1 "3K3" V 10025 1400 50  0000 C CNN
F 2 "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P10.16mm_Horizontal" V 9955 1400 50  0001 C CNN
F 3 "~" H 10025 1400 50  0001 C CNN
	1    10025 1400
	1    0    0    -1  
$EndComp
$Comp
L 74xx:74LS08 U26
U 2 1 65A6748E
P 10575 1050
F 0 "U26" H 10925 1175 50  0000 R CNN
F 1 "74HC08" H 11025 975 50  0000 R CNN
F 2 "Package_DIP:DIP-14_W7.62mm" H 10575 1050 50  0001 C CNN
F 3 "http://www.ti.com/lit/gpn/sn74LS08" H 10575 1050 50  0001 C CNN
	2    10575 1050
	1    0    0    -1  
$EndComp
Wire Wire Line
	8550 2100 8650 2100
Wire Wire Line
	8650 2100 8650 2975
Wire Wire Line
	8550 2000 8700 2000
Wire Wire Line
	8700 2000 8700 2850
Connection ~ 8700 2850
Wire Wire Line
	8700 2850 9100 2850
Text Label 9300 3575 0    50   ~ 0
RDY
Text Label 8650 2975 2    50   ~ 0
~POE
Wire Wire Line
	8550 3575 6450 3575
Text Label 6275 4000 0    50   ~ 0
~PSG
Wire Wire Line
	8150 1250 9600 1250
Wire Wire Line
	8550 1750 10025 1750
Connection ~ 9600 1250
Wire Wire Line
	10025 1550 10025 1750
Wire Wire Line
	10025 3575 10025 1750
Wire Wire Line
	8750 3575 10025 3575
Connection ~ 10025 1750
Entry Wire Line
	1600 4100 1700 4200
Wire Wire Line
	1700 4200 3400 4200
Text Label 1750 4200 0    50   ~ 0
A4
$Comp
L 74xx:74LS08 U26
U 1 1 65850ABF
P 8650 3275
F 0 "U26" V 8696 3095 50  0000 R CNN
F 1 "74HC08" V 8605 3095 50  0000 R CNN
F 2 "Package_DIP:DIP-14_W7.62mm" H 8650 3275 50  0001 C CNN
F 3 "http://www.ti.com/lit/gpn/sn74LS08" H 8650 3275 50  0001 C CNN
	1    8650 3275
	0    -1   -1   0   
$EndComp
$Comp
L 74xx:74LS08 U26
U 3 1 65862361
P 10575 1400
F 0 "U26" H 10825 1500 50  0000 C CNN
F 1 "74HC08" H 10875 1325 50  0000 C CNN
F 2 "Package_DIP:DIP-14_W7.62mm" H 10575 1400 50  0001 C CNN
F 3 "http://www.ti.com/lit/gpn/sn74LS08" H 10575 1400 50  0001 C CNN
	3    10575 1400
	1    0    0    -1  
$EndComp
$Comp
L 74xx:74LS08 U26
U 4 1 658631C3
P 10575 1750
F 0 "U26" H 10825 1875 50  0000 C CNN
F 1 "74HC08" H 10875 1675 50  0000 C CNN
F 2 "Package_DIP:DIP-14_W7.62mm" H 10575 1750 50  0001 C CNN
F 3 "http://www.ti.com/lit/gpn/sn74LS08" H 10575 1750 50  0001 C CNN
	4    10575 1750
	1    0    0    -1  
$EndComp
$Comp
L 74xx:74LS08 U26
U 5 1 658646F2
P 10275 2350
F 0 "U26" H 10505 2396 50  0000 L CNN
F 1 "74HC08" H 10505 2305 50  0000 L CNN
F 2 "Package_DIP:DIP-14_W7.62mm" H 10275 2350 50  0001 C CNN
F 3 "http://www.ti.com/lit/gpn/sn74LS08" H 10275 2350 50  0001 C CNN
	5    10275 2350
	1    0    0    -1  
$EndComp
Wire Wire Line
	10275 2850 9600 2850
Connection ~ 9600 2850
Wire Wire Line
	10275 1850 10275 1650
Wire Wire Line
	9600 1250 10025 1250
Connection ~ 10025 1250
Wire Wire Line
	10025 1250 10275 1250
Connection ~ 10275 1850
NoConn ~ 10875 1400
NoConn ~ 10875 1750
NoConn ~ 10875 1050
Wire Wire Line
	10275 950  10275 1150
Connection ~ 10275 1650
Connection ~ 10275 1150
Wire Wire Line
	10275 1150 10275 1250
Connection ~ 10275 1250
Wire Wire Line
	10275 1250 10275 1300
Connection ~ 10275 1300
Wire Wire Line
	10275 1300 10275 1500
Connection ~ 10275 1500
Wire Wire Line
	10275 1500 10275 1650
Wire Wire Line
	4400 3900 4650 3900
Wire Wire Line
	4650 3900 4650 4000
Wire Wire Line
	4650 4000 6450 4000
Wire Wire Line
	6450 4000 6450 3575
NoConn ~ 4400 4100
Connection ~ 3900 4700
Connection ~ 3900 3400
$Comp
L 74xx:74LS138 U33
U 1 1 64829879
P 3900 4000
F 0 "U33" H 3700 3450 50  0000 C CNN
F 1 "74HC138" H 4100 3450 50  0000 C CNN
F 2 "Package_DIP:DIP-16_W7.62mm" H 3900 4000 50  0001 C CNN
F 3 "http://www.ti.com/lit/gpn/sn74LS138" H 3900 4000 50  0001 C CNN
	1    3900 4000
	1    0    0    -1  
$EndComp
$Comp
L Jumper:Jumper_3_Bridged12 JP4
U 1 1 658B361F
P 875 2825
F 0 "JP4" V 825 2900 50  0000 L CNN
F 1 "DIP24" V 925 2875 50  0000 L CNN
F 2 "Jumper:SolderJumper-3_P1.3mm_Bridged12_RoundedPad1.0x1.5mm" H 875 2825 50  0001 C CNN
F 3 "~" H 875 2825 50  0001 C CNN
	1    875  2825
	0    -1   1    0   
$EndComp
Text Label 1025 2825 0    50   ~ 0
MA13
$Comp
L power:+5V #PWR0108
U 1 1 658B362A
P 875 3075
F 0 "#PWR0108" H 875 2925 50  0001 C CNN
F 1 "+5V" V 890 3203 50  0000 L CNN
F 2 "" H 875 3075 50  0001 C CNN
F 3 "" H 875 3075 50  0001 C CNN
	1    875  3075
	0    -1   -1   0   
$EndComp
Text Label 875  2575 2    50   ~ 0
A13
$Comp
L Jumper:Jumper_3_Bridged12 JP5
U 1 1 658CA557
P 875 3475
F 0 "JP5" V 825 3550 50  0000 L CNN
F 1 "DIP28" V 925 3525 50  0000 L CNN
F 2 "Jumper:SolderJumper-3_P1.3mm_Bridged12_RoundedPad1.0x1.5mm" H 875 3475 50  0001 C CNN
F 3 "~" H 875 3475 50  0001 C CNN
	1    875  3475
	0    -1   1    0   
$EndComp
Text Label 875  3225 2    50   ~ 0
BA3
$Comp
L power:+5V #PWR0109
U 1 1 658CA562
P 875 3725
F 0 "#PWR0109" H 875 3575 50  0001 C CNN
F 1 "+5V" V 890 3853 50  0000 L CNN
F 2 "" H 875 3725 50  0001 C CNN
F 3 "" H 875 3725 50  0001 C CNN
	1    875  3725
	0    -1   -1   0   
$EndComp
Text Label 1025 3475 0    50   ~ 0
MA17
$Comp
L Jumper:Jumper_2_Open JP6
U 1 1 658F413E
P 875 4075
F 0 "JP6" H 875 4310 50  0000 C CNN
F 1 "29F040" H 875 4219 50  0000 C CNN
F 2 "Jumper:SolderJumper-2_P1.3mm_Open_RoundedPad1.0x1.5mm" H 875 4075 50  0001 C CNN
F 3 "~" H 875 4075 50  0001 C CNN
	1    875  4075
	1    0    0    -1  
$EndComp
Text Label 675  4075 2    50   ~ 0
BA4
Text Label 1075 4075 0    50   ~ 0
MA19
$Comp
L Jumper:Jumper_3_Bridged12 JP7
U 1 1 6591AA04
P 875 4500
F 0 "JP7" V 825 4575 50  0000 L CNN
F 1 "28C" V 925 4550 50  0000 L CNN
F 2 "Jumper:SolderJumper-3_P1.3mm_Bridged12_RoundedPad1.0x1.5mm" H 875 4500 50  0001 C CNN
F 3 "~" H 875 4500 50  0001 C CNN
	1    875  4500
	0    -1   1    0   
$EndComp
Text Label 1025 4500 0    50   ~ 0
MA14
$Comp
L power:+5V #PWR0110
U 1 1 6591AA0F
P 875 4750
F 0 "#PWR0110" H 875 4600 50  0001 C CNN
F 1 "+5V" V 890 4878 50  0000 L CNN
F 2 "" H 875 4750 50  0001 C CNN
F 3 "" H 875 4750 50  0001 C CNN
	1    875  4750
	0    -1   -1   0   
$EndComp
Text Label 875  4250 2    50   ~ 0
UV14
$Comp
L Jumper:Jumper_3_Bridged12 JP8
U 1 1 659274BD
P 875 5150
F 0 "JP8" V 921 5217 50  0000 L CNN
F 1 "28C[64]" V 830 5217 50  0000 L CNN
F 2 "Jumper:SolderJumper-3_P1.3mm_Bridged12_RoundedPad1.0x1.5mm" H 875 5150 50  0001 C CNN
F 3 "~" H 875 5150 50  0001 C CNN
	1    875  5150
	0    -1   -1   0   
$EndComp
Text Label 1025 5150 0    50   ~ 0
MA15
Text Label 875  5400 2    50   ~ 0
BA1
Text Label 875  4900 2    50   ~ 0
UV14
Wire Wire Line
	6500 2450 6450 2450
Wire Wire Line
	6450 2450 6450 3575
Connection ~ 6450 3575
Wire Wire Line
	8150 1250 7000 1250
Wire Wire Line
	5500 1250 7000 1250
Connection ~ 7000 1250
Wire Wire Line
	8150 2850 7000 2850
Connection ~ 7000 2850
$Comp
L 74xx:74LS574 U25
U 1 1 6588D022
P 7000 2050
F 0 "U25" H 6800 2700 50  0000 C CNN
F 1 "74HC574" H 7175 2700 50  0000 C CNN
F 2 "Package_DIP:DIP-20_W7.62mm" H 7000 2050 50  0001 C CNN
F 3 "http://www.ti.com/lit/gpn/sn74LS574" H 7000 2050 50  0001 C CNN
	1    7000 2050
	1    0    0    -1  
$EndComp
Wire Wire Line
	6500 2850 7000 2850
Wire Wire Line
	6500 2550 6500 2850
Text Label 7750 1750 2    50   ~ 0
B5
Text Label 7750 1850 2    50   ~ 0
B4
Text Label 7750 1650 2    50   ~ 0
B6
Text Label 7750 1550 2    50   ~ 0
B7
Wire Wire Line
	5500 4700 7000 4700
Wire Wire Line
	7000 4700 7000 2850
Connection ~ 5500 4700
Text Notes 950  7725 0    89   ~ 0
24-pin: 27c16, 27c32  (change JP4)\n28-pin: 27c64, 27c128, 27c256 (change JP5)\n28-pin in 16K blocks: 27c256, 27c512 (change JP5, JP1; use U12, U33)\n28-pin in 32K blocks: 27c512 (change JP5; use U12, U33)\n28-pin EEPROM: 28C64 (change JP5, JP7; -CUT- JP8)\n28-pin EEPROM: 28C256 (change JP5, JP7, JP8)\n32-pin: 27C1001, 27C010, 27C020 (use U12, U33)*\n32-pin: 27C040 (change JP2; use U12, U33)*\n32-pin: 27C080  (change JP2, JP3; use U12, U33)*\n32-pin Flash: 28F512, 29F010, 29F020 (use U12, U33)*\n32-pin Flash: 29F040 (bridge JP6; -CUT- JP3; do NOT change JP2; use U12, U33)*\n\n*) change JP1 as needed\n\n2508/2708/2532/2564/27C1000 NOT compatible\nEEPROM 28c16 needs JP4 *and* wiring pin 21 to +5V outside board!
Wire Bus Line
	6250 1000 6250 2150
Wire Bus Line
	3050 1000 3050 2150
Wire Bus Line
	4750 950  4750 2650
Wire Bus Line
	1600 950  1600 4100
$EndSCHEMATC
