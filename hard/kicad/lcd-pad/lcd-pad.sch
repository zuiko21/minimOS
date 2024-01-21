EESchema Schematic File Version 4
LIBS:lcd-pad-cache
EELAYER 29 0
EELAYER END
$Descr A4 11693 8268
encoding utf-8
Sheet 1 1
Title "LCD pad for Chihuahua"
Date "2024-01-21"
Rev "v1"
Comp "@zuiko21"
Comment1 "(c) 2024 Carlos J. Santisteban"
Comment2 ""
Comment3 ""
Comment4 ""
$EndDescr
$Comp
L Connector_Generic:Conn_02x20_Odd_Even J1
U 1 1 652CE392
P 1250 3000
F 0 "J1" H 1300 4117 50  0000 C CNN
F 1 "VIAport" H 1300 4026 50  0000 C CNN
F 2 "Connector_PinSocket_2.54mm:PinSocket_2x20_P2.54mm_Vertical" H 1250 3000 50  0001 C CNN
F 3 "~" H 1250 3000 50  0001 C CNN
	1    1250 3000
	1    0    0    -1  
$EndComp
$Comp
L power:+5V #PWR0103
U 1 1 65302E77
P 1050 2100
F 0 "#PWR0103" H 1050 1950 50  0001 C CNN
F 1 "+5V" H 1065 2273 50  0000 C CNN
F 2 "" H 1050 2100 50  0001 C CNN
F 3 "" H 1050 2100 50  0001 C CNN
	1    1050 2100
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR0104
U 1 1 653031C4
P 1550 2100
F 0 "#PWR0104" H 1550 1850 50  0001 C CNN
F 1 "GND" V 1650 2100 50  0000 R CNN
F 2 "" H 1550 2100 50  0001 C CNN
F 3 "" H 1550 2100 50  0001 C CNN
	1    1550 2100
	0    -1   -1   0   
$EndComp
Wire Wire Line
	1050 2700 1050 2750
$Comp
L power:GND #PWR0105
U 1 1 6530786E
P 1050 2750
F 0 "#PWR0105" H 1050 2500 50  0001 C CNN
F 1 "GND" V 1055 2622 50  0000 R CNN
F 2 "" H 1050 2750 50  0001 C CNN
F 3 "" H 1050 2750 50  0001 C CNN
	1    1050 2750
	0    1    1    0   
$EndComp
Connection ~ 1050 2750
Wire Wire Line
	1050 2750 1050 2800
$Comp
L power:+5V #PWR0106
U 1 1 65307BCC
P 1550 2700
F 0 "#PWR0106" H 1550 2550 50  0001 C CNN
F 1 "+5V" V 1600 2700 50  0000 L CNN
F 2 "" H 1550 2700 50  0001 C CNN
F 3 "" H 1550 2700 50  0001 C CNN
	1    1550 2700
	0    1    1    0   
$EndComp
NoConn ~ 1550 2800
NoConn ~ 1550 2900
NoConn ~ 1550 3000
NoConn ~ 1550 3100
NoConn ~ 1550 3200
NoConn ~ 1550 3300
$Comp
L power:GND #PWR0107
U 1 1 65308401
P 1550 3400
F 0 "#PWR0107" H 1550 3150 50  0001 C CNN
F 1 "GND" V 1555 3272 50  0000 R CNN
F 2 "" H 1550 3400 50  0001 C CNN
F 3 "" H 1550 3400 50  0001 C CNN
	1    1550 3400
	0    -1   -1   0   
$EndComp
Wire Wire Line
	1050 3300 1050 3350
$Comp
L power:+5V #PWR0108
U 1 1 65308D59
P 1050 3350
F 0 "#PWR0108" H 1050 3200 50  0001 C CNN
F 1 "+5V" V 1100 3350 50  0000 L CNN
F 2 "" H 1050 3350 50  0001 C CNN
F 3 "" H 1050 3350 50  0001 C CNN
	1    1050 3350
	0    -1   -1   0   
$EndComp
Connection ~ 1050 3350
Wire Wire Line
	1050 3350 1050 3400
$Comp
L power:+5V #PWR0109
U 1 1 653098A2
P 1550 4000
F 0 "#PWR0109" H 1550 3850 50  0001 C CNN
F 1 "+5V" V 1650 3950 50  0000 L CNN
F 2 "" H 1550 4000 50  0001 C CNN
F 3 "" H 1550 4000 50  0001 C CNN
	1    1550 4000
	0    1    1    0   
$EndComp
$Comp
L power:GND #PWR0110
U 1 1 6530AFE2
P 1050 4000
F 0 "#PWR0110" H 1050 3750 50  0001 C CNN
F 1 "GND" H 1055 3827 50  0000 C CNN
F 2 "" H 1050 4000 50  0001 C CNN
F 3 "" H 1050 4000 50  0001 C CNN
	1    1050 4000
	1    0    0    -1  
$EndComp
Text Label 1050 2200 2    50   ~ 0
PA0
Text Label 1050 2300 2    50   ~ 0
PA1
Text Label 1050 2400 2    50   ~ 0
PA2
Text Label 1050 2500 2    50   ~ 0
PA3
Text Label 1050 2600 2    50   ~ 0
PA4
Text Label 1050 2900 2    50   ~ 0
CB1
Text Label 1050 3000 2    50   ~ 0
CB2
Text Label 1050 3100 2    50   ~ 0
CA2
NoConn ~ 1050 3200
Text Label 1050 3500 2    50   ~ 0
PB0
Text Label 1050 3600 2    50   ~ 0
PB1
Text Label 1050 3700 2    50   ~ 0
PB2
Text Label 1050 3800 2    50   ~ 0
PB3
Text Label 1050 3900 2    50   ~ 0
PB4
Text Label 1550 2200 0    50   ~ 0
PA5
Text Label 1550 2300 0    50   ~ 0
PA6
Text Label 1550 2400 0    50   ~ 0
PA7
Text Label 1550 2500 0    50   ~ 0
CA1
Text Label 1550 2600 0    50   ~ 0
CA2
Text Label 1550 3500 0    50   ~ 0
PB5
Text Label 1550 3600 0    50   ~ 0
PB6
Text Label 1550 3700 0    50   ~ 0
PB7
Text Label 1550 3800 0    50   ~ 0
CB1
Text Label 1550 3900 0    50   ~ 0
CB2
Wire Wire Line
	1050 3500 750  3500
Wire Wire Line
	750  3600 1050 3600
Wire Wire Line
	750  3700 1050 3700
Wire Wire Line
	750  3800 1050 3800
Wire Wire Line
	750  3900 1050 3900
Entry Wire Line
	650  3400 750  3500
Entry Wire Line
	650  3500 750  3600
Entry Wire Line
	650  3600 750  3700
Entry Wire Line
	650  3700 750  3800
Entry Wire Line
	650  3800 750  3900
Wire Wire Line
	1550 2200 1850 2200
Wire Wire Line
	1850 2300 1550 2300
Wire Wire Line
	1850 2400 1550 2400
Entry Wire Line
	1850 2200 1950 2100
Entry Wire Line
	1850 2300 1950 2200
Entry Wire Line
	1850 2400 1950 2300
Wire Wire Line
	1550 3700 1850 3700
Wire Wire Line
	1550 3600 1850 3600
Wire Wire Line
	1850 3500 1550 3500
Entry Wire Line
	1850 3500 1950 3600
Entry Wire Line
	1850 3600 1950 3700
Entry Wire Line
	1850 3700 1950 3800
Wire Bus Line
	1950 4250 650  4250
Wire Wire Line
	1050 2200 900  2200
Wire Wire Line
	900  2300 1050 2300
Wire Wire Line
	900  2400 1050 2400
Wire Wire Line
	900  2500 1050 2500
Wire Wire Line
	900  2600 1050 2600
Entry Wire Line
	800  2100 900  2200
Entry Wire Line
	800  2200 900  2300
Entry Wire Line
	800  2300 900  2400
Entry Wire Line
	800  2400 900  2500
Entry Wire Line
	800  2500 900  2600
Wire Bus Line
	800  1800 1950 1800
Connection ~ 1950 1800
Text Label 2350 3450 2    50   ~ 0
PB0
Text Label 2350 3550 2    50   ~ 0
PB1
Text Label 2350 3650 2    50   ~ 0
PB2
Text Label 2350 3750 2    50   ~ 0
PB3
Text Label 2350 3850 2    50   ~ 0
PB4
Text Label 2350 3950 2    50   ~ 0
PB5
Text Label 2350 4050 2    50   ~ 0
PB6
Text Label 2350 4150 2    50   ~ 0
PB7
Entry Wire Line
	1950 4250 2050 4150
Entry Wire Line
	1950 4150 2050 4050
Entry Wire Line
	1950 4050 2050 3950
Entry Wire Line
	1950 3950 2050 3850
Entry Wire Line
	1950 3850 2050 3750
Entry Wire Line
	1950 3750 2050 3650
Entry Wire Line
	1950 3650 2050 3550
Entry Wire Line
	1950 3550 2050 3450
Wire Wire Line
	2050 3450 2350 3450
Wire Wire Line
	2350 3550 2050 3550
Wire Wire Line
	2050 3650 2350 3650
Wire Wire Line
	2350 3750 2050 3750
Wire Wire Line
	2050 3850 2350 3850
Wire Wire Line
	2350 3950 2050 3950
Wire Wire Line
	2050 4050 2350 4050
Text Label 2350 2150 2    50   ~ 0
PA0
Text Label 2350 2250 2    50   ~ 0
PA1
Text Label 2350 2350 2    50   ~ 0
PA2
Text Label 2350 2450 2    50   ~ 0
PA3
Text Label 2350 2550 2    50   ~ 0
PA4
Text Label 2350 2650 2    50   ~ 0
PA5
Text Label 2350 2750 2    50   ~ 0
PA6
Text Label 2350 2850 2    50   ~ 0
PA7
Entry Wire Line
	1950 2050 2050 2150
Wire Wire Line
	2050 2150 2350 2150
Entry Wire Line
	1950 2150 2050 2250
Entry Wire Line
	1950 2250 2050 2350
Entry Wire Line
	1950 2350 2050 2450
Entry Wire Line
	1950 2450 2050 2550
Entry Wire Line
	1950 2550 2050 2650
Entry Wire Line
	1950 2650 2050 2750
Entry Wire Line
	1950 2750 2050 2850
Wire Wire Line
	2050 2250 2350 2250
Wire Wire Line
	2350 2350 2050 2350
Wire Wire Line
	2050 2450 2350 2450
Wire Wire Line
	2350 2550 2050 2550
Wire Wire Line
	2050 2650 2350 2650
Wire Wire Line
	2350 2750 2050 2750
Wire Wire Line
	2050 2850 2350 2850
Wire Wire Line
	1550 3900 1750 3900
Wire Wire Line
	1750 3900 1750 4450
Wire Wire Line
	1800 4350 1800 3800
Wire Wire Line
	1800 3800 1550 3800
Wire Wire Line
	1050 3000 850  3000
Wire Wire Line
	850  3000 850  4450
Wire Wire Line
	850  4450 1750 4450
Wire Wire Line
	1800 4350 800  4350
Wire Wire Line
	800  4350 800  2900
Wire Wire Line
	800  2900 1050 2900
Wire Wire Line
	1550 2500 1800 2500
Wire Wire Line
	1800 2500 1800 3050
Wire Wire Line
	1550 2600 1750 2600
Wire Wire Line
	1750 2600 1750 3150
Wire Wire Line
	1750 3150 2350 3150
Wire Wire Line
	1750 3150 1050 3150
Wire Wire Line
	1050 3150 1050 3100
Connection ~ 1750 3150
Text GLabel 1950 900  1    50   Input ~ 0
PA[0..7]
Text GLabel 650  1000 1    50   Input ~ 0
PB[0..7]
$Comp
L Graphic:Logo_Open_Hardware_Large LOGO1
U 1 1 65300219
P 10200 3600
F 0 "LOGO1" H 10200 4100 50  0001 C CNN
F 1 "Logo_Open_Hardware_Large" H 10200 3200 50  0001 C CNN
F 2 "Symbol:OSHW-Symbol_8.9x8mm_SilkScreen" H 10200 3600 50  0001 C CNN
F 3 "~" H 10200 3600 50  0001 C CNN
	1    10200 3600
	1    0    0    -1  
$EndComp
$Comp
L Graphic:Logo_Open_Hardware_Small LOGO2
U 1 1 65301B9B
P 10200 4950
F 0 "LOGO2" H 10200 5225 50  0001 C CNN
F 1 "Logo_Open_Hardware_Small" H 10200 4725 50  0001 C CNN
F 2 "durango:jaqueria" H 10200 4950 50  0001 C CNN
F 3 "~" H 10200 4950 50  0001 C CNN
	1    10200 4950
	1    0    0    -1  
$EndComp
$Comp
L Mechanical:MountingHole_Pad H1
U 1 1 65AE728F
P 10250 1025
F 0 "H1" V 10204 1175 50  0000 L CNN
F 1 "MountingHole_Pad" V 10295 1175 50  0000 L CNN
F 2 "MountingHole:MountingHole_3.2mm_M3_DIN965_Pad" H 10250 1025 50  0001 C CNN
F 3 "~" H 10250 1025 50  0001 C CNN
	1    10250 1025
	0    1    1    0   
$EndComp
$Comp
L Mechanical:MountingHole_Pad H2
U 1 1 65AE7CE7
P 10250 1250
F 0 "H2" V 10204 1400 50  0000 L CNN
F 1 "MountingHole_Pad" V 10295 1400 50  0000 L CNN
F 2 "MountingHole:MountingHole_3.2mm_M3_DIN965_Pad" H 10250 1250 50  0001 C CNN
F 3 "~" H 10250 1250 50  0001 C CNN
	1    10250 1250
	0    1    1    0   
$EndComp
Wire Wire Line
	10150 1025 10150 1250
Connection ~ 10150 1250
Wire Wire Line
	10150 1250 10150 1475
$Comp
L power:GND #PWR0132
U 1 1 65B0B18F
P 10150 1475
F 0 "#PWR0132" H 10150 1225 50  0001 C CNN
F 1 "GND" H 10155 1302 50  0000 C CNN
F 2 "" H 10150 1475 50  0001 C CNN
F 3 "" H 10150 1475 50  0001 C CNN
	1    10150 1475
	1    0    0    -1  
$EndComp
Wire Bus Line
	1950 900  1950 1800
Wire Wire Line
	1800 3050 2350 3050
Wire Wire Line
	2050 4150 2350 4150
Wire Bus Line
	800  1800 800  2500
Wire Bus Line
	650  1000 650  4250
Wire Bus Line
	1950 3550 1950 4250
Wire Bus Line
	1950 1800 1950 2750
$EndSCHEMATC
