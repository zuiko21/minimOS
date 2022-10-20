EESchema Schematic File Version 4
EELAYER 29 0
EELAYER END
$Descr A4 11693 8268
encoding utf-8
Sheet 1 1
Title "EIA/NTSC daughterboard"
Date "2022-10-19"
Rev ""
Comp "@zuiko21"
Comment1 ""
Comment2 ""
Comment3 ""
Comment4 ""
$EndDescr
$Comp
L Connector_Generic:Conn_02x08_Counter_Clockwise J1
U 1 1 6357945D
P 1650 1200
F 0 "J1" H 1700 1717 50  0000 C CNN
F 1 "U19 Socket" H 1700 1626 50  0000 C CNN
F 2 "Package_DIP:DIP-16_W7.62mm_Socket" H 1650 1200 50  0001 C CNN
F 3 "~" H 1650 1200 50  0001 C CNN
	1    1650 1200
	1    0    0    -1  
$EndComp
$Comp
L Connector_Generic:Conn_02x08_Counter_Clockwise J3
U 1 1 6357A98E
P 6650 1350
F 0 "J3" H 6700 1867 50  0000 C CNN
F 1 "U20 Socket" H 6700 1776 50  0000 C CNN
F 2 "Package_DIP:DIP-16_W7.62mm_Socket" H 6650 1350 50  0001 C CNN
F 3 "~" H 6650 1350 50  0001 C CNN
	1    6650 1350
	1    0    0    -1  
$EndComp
$Comp
L Connector_Generic:Conn_02x07_Counter_Clockwise J2
U 1 1 6357B153
P 4000 3950
F 0 "J2" H 4050 4467 50  0000 C CNN
F 1 "U17 Socket" H 4050 4376 50  0000 C CNN
F 2 "Package_DIP:DIP-14_W7.62mm_Socket" H 4000 3950 50  0001 C CNN
F 3 "~" H 4000 3950 50  0001 C CNN
	1    4000 3950
	1    0    0    -1  
$EndComp
$Comp
L 74xx:74LS21 U17
U 1 1 6357D083
P 2850 3800
F 0 "U17" H 2850 4175 50  0000 C CNN
F 1 "74HC21" H 2850 4084 50  0000 C CNN
F 2 "Package_DIP:DIP-14_W7.62mm" H 2850 3800 50  0001 C CNN
F 3 "http://www.ti.com/lit/gpn/sn74LS21" H 2850 3800 50  0001 C CNN
	1    2850 3800
	-1   0    0    -1  
$EndComp
$Comp
L 74xx:74LS21 U17
U 2 1 63581DA4
P 4750 3900
F 0 "U17" H 4750 3558 50  0000 C CNN
F 1 "74HC21" H 4750 3649 50  0000 C CNN
F 2 "Package_DIP:DIP-14_W7.62mm" H 4750 3900 50  0001 C CNN
F 3 "http://www.ti.com/lit/gpn/sn74LS21" H 4750 3900 50  0001 C CNN
	2    4750 3900
	1    0    0    1   
$EndComp
Wire Wire Line
	4450 3750 4300 3750
Wire Wire Line
	4450 3850 4300 3850
Wire Wire Line
	4450 3950 4350 3950
Wire Wire Line
	4350 3950 4350 4050
Wire Wire Line
	4350 4050 4300 4050
Wire Wire Line
	4450 4050 4400 4050
Wire Wire Line
	4400 4050 4400 4150
Wire Wire Line
	4400 4150 4300 4150
Wire Wire Line
	4300 4250 5050 4250
Wire Wire Line
	5050 4250 5050 3900
NoConn ~ 4300 3950
NoConn ~ 3800 3850
$Comp
L 74xx:74LS21 U17
U 3 1 63585567
P 6350 7050
F 0 "U17" H 6580 7096 50  0000 L CNN
F 1 "74HC21" H 6580 7005 50  0000 L CNN
F 2 "Package_DIP:DIP-14_W7.62mm" H 6350 7050 50  0001 C CNN
F 3 "http://www.ti.com/lit/gpn/sn74LS21" H 6350 7050 50  0001 C CNN
	3    6350 7050
	1    0    0    -1  
$EndComp
$Comp
L power:+5V #PWR0101
U 1 1 6358C2CE
P 6350 6550
F 0 "#PWR0101" H 6350 6400 50  0001 C CNN
F 1 "+5V" H 6365 6723 50  0000 C CNN
F 2 "" H 6350 6550 50  0001 C CNN
F 3 "" H 6350 6550 50  0001 C CNN
	1    6350 6550
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR0102
U 1 1 6358C645
P 6350 7550
F 0 "#PWR0102" H 6350 7300 50  0001 C CNN
F 1 "GND" H 6355 7377 50  0000 C CNN
F 2 "" H 6350 7550 50  0001 C CNN
F 3 "" H 6350 7550 50  0001 C CNN
	1    6350 7550
	1    0    0    -1  
$EndComp
$Comp
L power:PWR_FLAG #FLG0101
U 1 1 6358C985
P 6350 7550
F 0 "#FLG0101" H 6350 7625 50  0001 C CNN
F 1 "PWR_FLAG" V 6350 7678 50  0000 L CNN
F 2 "" H 6350 7550 50  0001 C CNN
F 3 "~" H 6350 7550 50  0001 C CNN
	1    6350 7550
	0    1    1    0   
$EndComp
Connection ~ 6350 7550
$Comp
L power:PWR_FLAG #FLG0102
U 1 1 6358CC2E
P 6350 6550
F 0 "#FLG0102" H 6350 6625 50  0001 C CNN
F 1 "PWR_FLAG" V 6350 6678 50  0000 L CNN
F 2 "" H 6350 6550 50  0001 C CNN
F 3 "~" H 6350 6550 50  0001 C CNN
	1    6350 6550
	0    1    1    0   
$EndComp
Connection ~ 6350 6550
$Comp
L power:+5V #PWR0103
U 1 1 6358CFB5
P 4300 3650
F 0 "#PWR0103" H 4300 3500 50  0001 C CNN
F 1 "+5V" H 4315 3823 50  0000 C CNN
F 2 "" H 4300 3650 50  0001 C CNN
F 3 "" H 4300 3650 50  0001 C CNN
	1    4300 3650
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR0104
U 1 1 6358D301
P 3800 4250
F 0 "#PWR0104" H 3800 4000 50  0001 C CNN
F 1 "GND" H 3805 4077 50  0000 C CNN
F 2 "" H 3800 4250 50  0001 C CNN
F 3 "" H 3800 4250 50  0001 C CNN
	1    3800 4250
	1    0    0    -1  
$EndComp
Wire Wire Line
	2550 3800 2550 4150
Wire Wire Line
	2550 4150 3800 4150
$Comp
L power:+5V #PWR0105
U 1 1 6358EE20
P 1950 800
F 0 "#PWR0105" H 1950 650 50  0001 C CNN
F 1 "+5V" H 1965 973 50  0000 C CNN
F 2 "" H 1950 800 50  0001 C CNN
F 3 "" H 1950 800 50  0001 C CNN
	1    1950 800 
	1    0    0    -1  
$EndComp
$Comp
L power:+5V #PWR0106
U 1 1 6358F12A
P 6950 1050
F 0 "#PWR0106" H 6950 900 50  0001 C CNN
F 1 "+5V" H 6965 1223 50  0000 C CNN
F 2 "" H 6950 1050 50  0001 C CNN
F 3 "" H 6950 1050 50  0001 C CNN
	1    6950 1050
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR0107
U 1 1 6358F477
P 1450 1600
F 0 "#PWR0107" H 1450 1350 50  0001 C CNN
F 1 "GND" H 1455 1427 50  0000 C CNN
F 2 "" H 1450 1600 50  0001 C CNN
F 3 "" H 1450 1600 50  0001 C CNN
	1    1450 1600
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR0108
U 1 1 6358F795
P 6450 1750
F 0 "#PWR0108" H 6450 1500 50  0001 C CNN
F 1 "GND" H 6455 1577 50  0000 C CNN
F 2 "" H 6450 1750 50  0001 C CNN
F 3 "" H 6450 1750 50  0001 C CNN
	1    6450 1750
	1    0    0    -1  
$EndComp
$Comp
L 4xxx:4040 U19
U 1 1 6358FC21
P 2700 1600
F 0 "U19" H 2700 2581 50  0000 C CNN
F 1 "74HC4040" H 2700 2490 50  0000 C CNN
F 2 "Package_DIP:DIP-16_W7.62mm" H 2700 1600 50  0001 C CNN
F 3 "http://www.intersil.com/content/dam/Intersil/documents/cd40/cd4020bms-24bms-40bms.pdf" H 2700 1600 50  0001 C CNN
	1    2700 1600
	1    0    0    -1  
$EndComp
NoConn ~ 3200 2000
NoConn ~ 3200 2100
NoConn ~ 3200 2200
NoConn ~ 1450 900 
NoConn ~ 1950 1000
NoConn ~ 1950 1100
NoConn ~ 6450 1450
NoConn ~ 6450 1650
Wire Wire Line
	1950 1400 2200 1400
Wire Wire Line
	2200 1100 2150 1100
Wire Wire Line
	2150 1100 2150 1500
Wire Wire Line
	2150 1500 1950 1500
$Comp
L power:GND #PWR0109
U 1 1 63599765
P 2700 2500
F 0 "#PWR0109" H 2700 2250 50  0001 C CNN
F 1 "GND" H 2705 2327 50  0000 C CNN
F 2 "" H 2700 2500 50  0001 C CNN
F 3 "" H 2700 2500 50  0001 C CNN
	1    2700 2500
	1    0    0    -1  
$EndComp
Wire Wire Line
	2700 800  1950 800 
Wire Wire Line
	1950 900  1950 800 
Connection ~ 1950 800 
Wire Wire Line
	1950 1600 2100 1600
Wire Wire Line
	2100 1600 2100 750 
Wire Wire Line
	2100 750  3200 750 
Wire Wire Line
	3200 750  3200 1100
Wire Wire Line
	1450 1500 1350 1500
Wire Wire Line
	1350 1500 1350 2750
Wire Wire Line
	1350 2750 3250 2750
Wire Wire Line
	3250 2750 3250 1200
Wire Wire Line
	3250 1200 3200 1200
Wire Wire Line
	1450 1400 1300 1400
Wire Wire Line
	1300 1400 1300 2800
Wire Wire Line
	1300 2800 3300 2800
Wire Wire Line
	3300 2800 3300 1300
Wire Wire Line
	3300 1300 3200 1300
Wire Wire Line
	1450 1300 1250 1300
Wire Wire Line
	1250 1300 1250 2850
Wire Wire Line
	1250 2850 3350 2850
Wire Wire Line
	3350 2850 3350 1400
Wire Wire Line
	3350 1400 3200 1400
Text Label 1950 1600 0    50   ~ 0
VA6
Text Label 1950 1500 0    50   ~ 0
CLK
Text Label 1950 1400 0    50   ~ 0
RST
Text Label 1350 1500 0    50   ~ 0
VA7
Text Label 1350 1400 0    50   ~ 0
VA8
Text Label 1350 1300 0    50   ~ 0
VA9
Text Label 1300 1200 0    50   ~ 0
VA12
Text Label 1300 1100 0    50   ~ 0
VA10
Text Label 1300 1000 0    50   ~ 0
VA11
Text Label 1950 1200 0    50   ~ 0
VA13
Wire Wire Line
	1450 1200 1200 1200
Wire Wire Line
	1200 2900 3400 2900
Wire Wire Line
	3400 2900 3400 1700
Wire Wire Line
	3400 1700 3200 1700
Wire Wire Line
	1200 1200 1200 2900
Wire Wire Line
	1450 1100 1150 1100
Wire Wire Line
	1150 1100 1150 2950
Wire Wire Line
	1150 2950 3450 2950
Wire Wire Line
	3450 2950 3450 1500
Wire Wire Line
	3450 1500 3200 1500
Wire Wire Line
	1450 1000 1100 1000
Wire Wire Line
	1100 1000 1100 3000
Wire Wire Line
	1100 3000 3500 3000
Wire Wire Line
	3500 3000 3500 1600
Wire Wire Line
	3500 1600 3200 1600
Wire Wire Line
	1950 1200 2050 1200
Wire Wire Line
	2050 1200 2050 3050
Wire Wire Line
	2050 3050 3550 3050
Wire Wire Line
	3550 3050 3550 1800
Wire Wire Line
	3550 1800 3200 1800
Wire Wire Line
	3600 3850 3600 1900
Wire Wire Line
	3600 1900 3200 1900
Text Label 4300 3750 0    50   ~ 0
+5
Text Label 4300 3850 0    50   ~ 0
VA1
Text Label 4450 3950 2    50   ~ 0
~LINE
Text Label 4400 4150 2    50   ~ 0
VA5
Text Label 5050 4250 2    50   ~ 0
LEND
Text Label 2550 4150 0    50   ~ 0
FEND
$Comp
L power:+5V #PWR0110
U 1 1 635B73BE
P 3150 3650
F 0 "#PWR0110" H 3150 3500 50  0001 C CNN
F 1 "+5V" H 3165 3823 50  0000 C CNN
F 2 "" H 3150 3650 50  0001 C CNN
F 3 "" H 3150 3650 50  0001 C CNN
	1    3150 3650
	1    0    0    -1  
$EndComp
Wire Wire Line
	3250 2750 3250 3750
Wire Wire Line
	3250 3750 3150 3750
Connection ~ 3250 2750
Wire Wire Line
	3300 2800 3300 3950
Wire Wire Line
	3300 3950 3150 3950
Connection ~ 3300 2800
NoConn ~ 3800 3650
NoConn ~ 3800 3750
NoConn ~ 3800 4050
Text Label 1950 1300 0    50   ~ 0
~FRAME
NoConn ~ 3800 3950
Wire Wire Line
	3150 3850 3600 3850
$Comp
L power:GND #PWR0111
U 1 1 635DB0E4
P 5600 2150
F 0 "#PWR0111" H 5600 1900 50  0001 C CNN
F 1 "GND" H 5605 1977 50  0000 C CNN
F 2 "" H 5600 2150 50  0001 C CNN
F 3 "" H 5600 2150 50  0001 C CNN
	1    5600 2150
	1    0    0    -1  
$EndComp
$Comp
L power:+5V #PWR0112
U 1 1 635DACF9
P 5600 750
F 0 "#PWR0112" H 5600 600 50  0001 C CNN
F 1 "+5V" H 5615 923 50  0000 C CNN
F 2 "" H 5600 750 50  0001 C CNN
F 3 "" H 5600 750 50  0001 C CNN
	1    5600 750 
	1    0    0    -1  
$EndComp
$Comp
L 74xx:74LS85 U20
U 1 1 635DA132
P 5600 1450
F 0 "U20" H 5350 2000 50  0000 C CNN
F 1 "74HC85" H 5800 2000 50  0000 C CNN
F 2 "Package_DIP:DIP-16_W7.62mm" H 5600 1450 50  0001 C CNN
F 3 "http://www.ti.com/lit/gpn/sn74LS85" H 5600 1450 50  0001 C CNN
	1    5600 1450
	1    0    0    -1  
$EndComp
Wire Wire Line
	6100 1150 6450 1150
Wire Wire Line
	6100 1250 6450 1250
Wire Wire Line
	6100 1050 6250 1050
Wire Wire Line
	6250 1050 6250 1350
Wire Wire Line
	6250 1350 6450 1350
Text Label 6100 1050 0    50   ~ 0
I>
Text Label 6100 1150 0    50   ~ 0
I<
Text Label 6100 1250 0    50   ~ 0
I=
NoConn ~ 6100 1650
NoConn ~ 6100 1750
Wire Wire Line
	6100 1850 6250 1850
Wire Wire Line
	6250 1850 6250 1550
Wire Wire Line
	6250 1550 6450 1550
Text Label 6250 1550 0    50   ~ 0
UVS
$Comp
L 74xx:74LS85 U100
U 1 1 635EF003
P 4300 1450
F 0 "U100" H 4050 2000 50  0000 C CNN
F 1 "74HC85" H 4500 2000 50  0000 C CNN
F 2 "Package_DIP:DIP-16_W7.62mm" H 4300 1450 50  0001 C CNN
F 3 "http://www.ti.com/lit/gpn/sn74LS85" H 4300 1450 50  0001 C CNN
	1    4300 1450
	1    0    0    -1  
$EndComp
$Comp
L power:+5V #PWR0113
U 1 1 635F16FE
P 4300 750
F 0 "#PWR0113" H 4300 600 50  0001 C CNN
F 1 "+5V" H 4315 923 50  0000 C CNN
F 2 "" H 4300 750 50  0001 C CNN
F 3 "" H 4300 750 50  0001 C CNN
	1    4300 750 
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR0114
U 1 1 635F1B29
P 4300 2150
F 0 "#PWR0114" H 4300 1900 50  0001 C CNN
F 1 "GND" H 4305 1977 50  0000 C CNN
F 2 "" H 4300 2150 50  0001 C CNN
F 3 "" H 4300 2150 50  0001 C CNN
	1    4300 2150
	1    0    0    -1  
$EndComp
NoConn ~ 4800 1750
NoConn ~ 4800 1850
Wire Wire Line
	4800 1650 4850 1650
Wire Wire Line
	4850 1650 4850 3150
Wire Wire Line
	4850 3150 2000 3150
Wire Wire Line
	2000 3150 2000 1300
Wire Wire Line
	2000 1300 1950 1300
Wire Wire Line
	4800 1250 4800 1150
Wire Wire Line
	4800 750  4300 750 
Connection ~ 4800 1050
Wire Wire Line
	4800 1050 4800 750 
Connection ~ 4800 1150
Wire Wire Line
	4800 1150 4800 1050
Connection ~ 4300 750 
Text Notes 1250 1200 0    50   ~ 0
*
Text Notes 5750 850  0    50   ~ 0
@272\n\n 5432\n=0110
Text Notes 4450 700  0    50   ~ 0
 8765\n>0101
$EndSCHEMATC