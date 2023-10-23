EESchema Schematic File Version 4
LIBS:shadow32k-cache
EELAYER 29 0
EELAYER END
$Descr A4 11693 8268
encoding utf-8
Sheet 1 1
Title "Compact 32 KiB Shadow RAM cartridge for Durango-X"
Date "2023-10-22"
Rev "v1"
Comp "@zuiko21"
Comment1 ""
Comment2 ""
Comment3 ""
Comment4 ""
$EndDescr
$Comp
L Memory_EPROM:27C256 U1
U 1 1 6248CC58
P 2900 2375
F 0 "U1" H 2725 1325 50  0000 C CNN
F 1 "27/28C256" H 3150 1325 50  0000 C CNN
F 2 "Package_DIP:DIP-28_W15.24mm" H 2900 2375 50  0001 C CNN
F 3 "http://ww1.microchip.com/downloads/en/DeviceDoc/doc0015.pdf" H 2900 2375 50  0001 C CNN
	1    2900 2375
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR0102
U 1 1 624EBE66
P 5950 5750
F 0 "#PWR0102" H 5950 5500 50  0001 C CNN
F 1 "GND" H 5875 5625 50  0000 C CNN
F 2 "" H 5950 5750 50  0001 C CNN
F 3 "" H 5950 5750 50  0001 C CNN
	1    5950 5750
	1    0    0    -1  
$EndComp
$Comp
L power:+5V #PWR0104
U 1 1 625077D4
P 2900 700
F 0 "#PWR0104" H 2900 550 50  0001 C CNN
F 1 "+5V" H 2800 800 50  0000 C CNN
F 2 "" H 2900 700 50  0001 C CNN
F 3 "" H 2900 700 50  0001 C CNN
	1    2900 700 
	1    0    0    -1  
$EndComp
$Comp
L Device:C C1
U 1 1 62636C82
P 5000 1150
F 0 "C1" V 4900 1050 50  0000 C CNN
F 1 "22n" V 4900 1300 50  0000 C CNN
F 2 "Capacitor_THT:C_Rect_L7.0mm_W3.5mm_P5.00mm" H 5038 1000 50  0001 C CNN
F 3 "~" H 5000 1150 50  0001 C CNN
	1    5000 1150
	0    1    1    0   
$EndComp
$Comp
L power:GND #PWR0107
U 1 1 626370FC
P 5150 1150
F 0 "#PWR0107" H 5150 900 50  0001 C CNN
F 1 "GND" H 5250 1150 50  0000 C CNN
F 2 "" H 5150 1150 50  0001 C CNN
F 3 "" H 5150 1150 50  0001 C CNN
	1    5150 1150
	1    0    0    -1  
$EndComp
$Comp
L edge_conn:Durango_ROM J1
U 1 1 629256A2
P 1550 2225
F 0 "J1" H 1725 3300 50  0000 C CNN
F 1 "to Computer" H 1225 3300 50  0000 C CNN
F 2 "edge_conn:Durango_ROM" H 1250 1225 50  0001 C CNN
F 3 "" H 1250 1225 50  0001 C CNN
	1    1550 2225
	-1   0    0    1   
$EndComp
Wire Wire Line
	1950 1475 2125 1475
Wire Wire Line
	1950 1575 2125 1575
Wire Wire Line
	1950 1675 2125 1675
Wire Wire Line
	1950 1775 2125 1775
Wire Wire Line
	1950 1875 2125 1875
Wire Wire Line
	1950 1975 2125 1975
Wire Wire Line
	1950 2075 2125 2075
Wire Wire Line
	1950 2175 2125 2175
Wire Wire Line
	1950 2275 2125 2275
Wire Wire Line
	1950 2375 2125 2375
Wire Wire Line
	1950 2475 2125 2475
Wire Wire Line
	1950 2575 2125 2575
Wire Wire Line
	1950 2675 2125 2675
Wire Wire Line
	1950 2775 2125 2775
NoConn ~ 1150 1275
NoConn ~ 1150 2975
NoConn ~ 1150 2775
NoConn ~ 1150 2675
Wire Wire Line
	1150 1475 1000 1475
Wire Wire Line
	1150 1575 1000 1575
Wire Wire Line
	1150 1675 1000 1675
Wire Wire Line
	1150 1775 1000 1775
Wire Wire Line
	1150 1875 1000 1875
Wire Wire Line
	1000 1975 1150 1975
Wire Wire Line
	1150 2075 1000 2075
Wire Wire Line
	1000 2175 1150 2175
$Comp
L power:GND #PWR0101
U 1 1 62935634
P 1550 1125
F 0 "#PWR0101" H 1550 875 50  0001 C CNN
F 1 "GND" V 1555 997 50  0000 R CNN
F 2 "" H 1550 1125 50  0001 C CNN
F 3 "" H 1550 1125 50  0001 C CNN
	1    1550 1125
	0    -1   -1   0   
$EndComp
$Comp
L power:+5V #PWR0105
U 1 1 6253888C
P 1550 3425
F 0 "#PWR0105" H 1550 3275 50  0001 C CNN
F 1 "+5V" V 1550 3625 50  0000 C CNN
F 2 "" H 1550 3425 50  0001 C CNN
F 3 "" H 1550 3425 50  0001 C CNN
	1    1550 3425
	0    -1   -1   0   
$EndComp
Wire Wire Line
	1550 3425 1550 3325
Wire Wire Line
	2125 2875 1950 2875
Text Label 1975 1475 0    50   ~ 0
A0
Text Label 1975 1575 0    50   ~ 0
A1
Text Label 1975 1675 0    50   ~ 0
A2
Text Label 1975 1775 0    50   ~ 0
A3
Text Label 1975 1875 0    50   ~ 0
A4
Text Label 1975 1975 0    50   ~ 0
A5
Text Label 1975 2075 0    50   ~ 0
A6
Text Label 1975 2175 0    50   ~ 0
A7
Text Label 1975 2275 0    50   ~ 0
A8
Text Label 1975 2375 0    50   ~ 0
A9
Text Label 1975 2475 0    50   ~ 0
A10
Text Label 1975 2575 0    50   ~ 0
A11
Text Label 1975 2675 0    50   ~ 0
A12
Text Label 1975 2775 0    50   ~ 0
A13
Text Label 1975 2875 0    50   ~ 0
A14
Text Label 1125 2175 2    50   ~ 0
D7
Text Label 1125 2075 2    50   ~ 0
D6
Text Label 1125 1975 2    50   ~ 0
D5
Text Label 1125 1875 2    50   ~ 0
D4
Text Label 1125 1775 2    50   ~ 0
D3
Text Label 1125 1675 2    50   ~ 0
D2
Text Label 1125 1575 2    50   ~ 0
D1
Text Label 1125 1475 2    50   ~ 0
D0
Wire Wire Line
	2325 1475 2500 1475
Wire Wire Line
	2325 1575 2500 1575
Wire Wire Line
	2325 1675 2500 1675
Wire Wire Line
	2325 1775 2500 1775
Wire Wire Line
	2325 1875 2500 1875
Wire Wire Line
	2325 1975 2500 1975
Wire Wire Line
	2325 2075 2500 2075
Wire Wire Line
	2325 2175 2500 2175
Wire Wire Line
	2325 2275 2500 2275
Wire Wire Line
	2325 2375 2500 2375
Wire Wire Line
	2325 2475 2500 2475
Wire Wire Line
	2325 2575 2500 2575
Wire Wire Line
	2325 2675 2500 2675
Wire Wire Line
	2325 2775 2500 2775
Text Label 2350 1575 0    50   ~ 0
A1
Text Label 2350 1675 0    50   ~ 0
A2
Text Label 2350 1775 0    50   ~ 0
A3
Text Label 2350 1875 0    50   ~ 0
A4
Text Label 2350 1975 0    50   ~ 0
A5
Text Label 2350 2075 0    50   ~ 0
A6
Text Label 2350 2175 0    50   ~ 0
A7
Text Label 2350 2275 0    50   ~ 0
A8
Text Label 2350 2375 0    50   ~ 0
A9
Text Label 2350 2475 0    50   ~ 0
A10
Text Label 2350 2575 0    50   ~ 0
A11
Text Label 2350 2675 0    50   ~ 0
A12
Text Label 2350 2775 0    50   ~ 0
A13
Wire Wire Line
	3450 1475 3300 1475
Wire Wire Line
	3450 1575 3300 1575
Wire Wire Line
	3450 1675 3300 1675
Wire Wire Line
	3450 1775 3300 1775
Wire Wire Line
	3450 1875 3300 1875
Wire Wire Line
	3300 1975 3450 1975
Wire Wire Line
	3450 2075 3300 2075
Wire Wire Line
	3300 2175 3450 2175
Text Label 3425 2175 2    50   ~ 0
D7
Text Label 3425 2075 2    50   ~ 0
D6
Text Label 3425 1975 2    50   ~ 0
D5
Text Label 3425 1875 2    50   ~ 0
D4
Text Label 3425 1775 2    50   ~ 0
D3
Text Label 3425 1675 2    50   ~ 0
D2
Text Label 3425 1575 2    50   ~ 0
D1
Text Label 3425 1475 2    50   ~ 0
D0
$Comp
L 62256:62256 U2
U 1 1 63B6D4DA
P 4850 2350
F 0 "U2" H 4625 1250 50  0000 C CNN
F 1 "62256" H 5075 1250 50  0000 C CNN
F 2 "Package_SO:SOIC-28W_7.5x17.9mm_P1.27mm" H 4850 2350 50  0001 C CNN
F 3 "http://ww1.microchip.com/downloads/en/DeviceDoc/doc0015.pdf" H 4850 2350 50  0001 C CNN
	1    4850 2350
	1    0    0    -1  
$EndComp
Wire Wire Line
	4075 1450 4250 1450
Wire Wire Line
	4075 1550 4250 1550
Wire Wire Line
	4075 1650 4250 1650
Wire Wire Line
	4075 1750 4250 1750
Wire Wire Line
	4075 1850 4250 1850
Wire Wire Line
	4075 1950 4250 1950
Wire Wire Line
	4075 2050 4250 2050
Wire Wire Line
	4075 2150 4250 2150
Wire Wire Line
	4075 2250 4250 2250
Wire Wire Line
	4075 2350 4250 2350
Wire Wire Line
	4075 2450 4250 2450
Wire Wire Line
	4075 2550 4250 2550
Wire Wire Line
	4075 2650 4250 2650
Wire Wire Line
	4075 2750 4250 2750
Wire Wire Line
	4250 2850 4075 2850
Text Label 4100 1450 0    50   ~ 0
A0
Text Label 4100 1550 0    50   ~ 0
A1
Text Label 4100 1650 0    50   ~ 0
A2
Text Label 4100 1750 0    50   ~ 0
A3
Text Label 4100 1850 0    50   ~ 0
A4
Text Label 4100 1950 0    50   ~ 0
A5
Text Label 4100 2050 0    50   ~ 0
A6
Text Label 4100 2150 0    50   ~ 0
A7
Text Label 4100 2250 0    50   ~ 0
A8
Text Label 4100 2350 0    50   ~ 0
A9
Text Label 4100 2450 0    50   ~ 0
A10
Text Label 4100 2550 0    50   ~ 0
A11
Text Label 4100 2650 0    50   ~ 0
A12
Text Label 4100 2750 0    50   ~ 0
A13
Text Label 4100 2850 0    50   ~ 0
A14
Wire Wire Line
	5600 1450 5450 1450
Wire Wire Line
	5600 1550 5450 1550
Wire Wire Line
	5600 1650 5450 1650
Wire Wire Line
	5600 1750 5450 1750
Wire Wire Line
	5600 1850 5450 1850
Wire Wire Line
	5450 1950 5600 1950
Wire Wire Line
	5600 2050 5450 2050
Wire Wire Line
	5450 2150 5600 2150
Text Label 5575 2150 2    50   ~ 0
D7
Text Label 5575 2050 2    50   ~ 0
D6
Text Label 5575 1950 2    50   ~ 0
D5
Text Label 5575 1850 2    50   ~ 0
D4
Text Label 5575 1750 2    50   ~ 0
D3
Text Label 5575 1650 2    50   ~ 0
D2
Text Label 5575 1550 2    50   ~ 0
D1
Text Label 5575 1450 2    50   ~ 0
D0
Entry Wire Line
	2125 1475 2225 1375
Entry Wire Line
	2125 1575 2225 1475
Entry Wire Line
	2125 1675 2225 1575
Entry Wire Line
	2125 1775 2225 1675
Entry Wire Line
	2125 1875 2225 1775
Entry Wire Line
	2125 1975 2225 1875
Entry Wire Line
	2125 2075 2225 1975
Entry Wire Line
	2125 2175 2225 2075
Entry Wire Line
	2125 2275 2225 2175
Entry Wire Line
	2125 2375 2225 2275
Entry Wire Line
	2125 2475 2225 2375
Entry Wire Line
	2125 2575 2225 2475
Entry Wire Line
	2125 2675 2225 2575
Entry Wire Line
	2125 2775 2225 2675
Entry Wire Line
	2125 2875 2225 2775
Entry Wire Line
	3450 1475 3550 1375
Entry Wire Line
	3450 1575 3550 1475
Entry Wire Line
	3450 1675 3550 1575
Entry Wire Line
	3450 1775 3550 1675
Entry Wire Line
	3450 1875 3550 1775
Entry Wire Line
	3450 1975 3550 1875
Entry Wire Line
	3450 2075 3550 1975
Entry Wire Line
	3450 2175 3550 2075
Entry Wire Line
	5600 1450 5700 1350
Entry Wire Line
	5600 1550 5700 1450
Entry Wire Line
	5600 1650 5700 1550
Entry Wire Line
	5600 1750 5700 1650
Entry Wire Line
	5600 1850 5700 1750
Entry Wire Line
	5600 1950 5700 1850
Entry Wire Line
	5600 2050 5700 1950
Entry Wire Line
	5600 2150 5700 2050
Entry Wire Line
	2225 1375 2325 1475
Entry Wire Line
	2225 1475 2325 1575
Entry Wire Line
	2225 1575 2325 1675
Entry Wire Line
	2225 1675 2325 1775
Entry Wire Line
	2225 1775 2325 1875
Entry Wire Line
	2225 1875 2325 1975
Entry Wire Line
	2225 1975 2325 2075
Entry Wire Line
	2225 2075 2325 2175
Entry Wire Line
	2225 2175 2325 2275
Entry Wire Line
	2225 2275 2325 2375
Entry Wire Line
	2225 2375 2325 2475
Entry Wire Line
	2225 2475 2325 2575
Entry Wire Line
	2225 2575 2325 2675
Entry Wire Line
	2225 2675 2325 2775
Entry Wire Line
	900  1375 1000 1475
Entry Wire Line
	900  1475 1000 1575
Entry Wire Line
	900  1575 1000 1675
Entry Wire Line
	900  1675 1000 1775
Entry Wire Line
	900  1775 1000 1875
Entry Wire Line
	900  1875 1000 1975
Entry Wire Line
	900  1975 1000 2075
Entry Wire Line
	900  2075 1000 2175
Entry Wire Line
	3975 1350 4075 1450
Entry Wire Line
	3975 1450 4075 1550
Entry Wire Line
	3975 1550 4075 1650
Entry Wire Line
	3975 1650 4075 1750
Entry Wire Line
	3975 1750 4075 1850
Entry Wire Line
	3975 1850 4075 1950
Entry Wire Line
	3975 1950 4075 2050
Entry Wire Line
	3975 2050 4075 2150
Entry Wire Line
	3975 2150 4075 2250
Entry Wire Line
	3975 2250 4075 2350
Entry Wire Line
	3975 2350 4075 2450
Entry Wire Line
	3975 2450 4075 2550
Entry Wire Line
	3975 2550 4075 2650
Entry Wire Line
	3975 2650 4075 2750
Entry Wire Line
	3975 2750 4075 2850
Text Label 2350 1475 0    50   ~ 0
A0
Wire Bus Line
	900  875  3550 875 
Connection ~ 3550 875 
Wire Bus Line
	3550 875  5700 875 
Text GLabel 900  875  0    50   Input ~ 0
D[0..7]
Wire Bus Line
	2225 775  3975 775 
Text GLabel 2225 775  0    50   Input ~ 0
A[0..14]
Wire Bus Line
	3550 875  4075 875 
Wire Wire Line
	2900 3550 2900 3475
Wire Wire Line
	2900 700  2900 1150
Wire Wire Line
	4850 1150 2900 1150
Connection ~ 4850 1150
Connection ~ 2900 1150
Wire Wire Line
	2900 1150 2900 1275
Wire Wire Line
	1950 3125 2175 3125
Wire Wire Line
	2175 3125 2175 3925
Wire Wire Line
	2175 3925 2875 3925
Text Label 2875 5025 0    50   ~ 0
~WE
Wire Wire Line
	1150 2475 1100 2475
Wire Wire Line
	1100 2475 1100 3825
Wire Wire Line
	1100 3825 2450 3825
Wire Wire Line
	4100 3825 4100 3050
Wire Wire Line
	4100 3050 4250 3050
Text Label 2925 3925 0    50   ~ 0
~CS
Wire Wire Line
	2500 3175 2450 3175
Wire Wire Line
	2450 3175 2450 3825
Connection ~ 2450 3825
Wire Wire Line
	2450 3825 2925 3825
Wire Wire Line
	2500 2875 2500 3075
Wire Wire Line
	1550 3425 1650 3425
Wire Wire Line
	2400 3425 2400 3075
Wire Wire Line
	2400 3075 2500 3075
Connection ~ 1550 3425
Connection ~ 2500 3075
Text Notes 2925 3525 0    50   ~ 0
Upper 16K only
Text Label 1950 1275 0    50   ~ 0
~RST
$Comp
L 74xx:74LS174 U4
U 1 1 63C3EBA2
P 1650 4950
F 0 "U4" H 1475 4275 50  0000 C CNN
F 1 "74HC174" H 1850 4275 50  0000 C CNN
F 2 "Package_DIP:DIP-16_W7.62mm" H 1650 4950 50  0001 C CNN
F 3 "http://www.ti.com/lit/gpn/sn74LS174" H 1650 4950 50  0001 C CNN
	1    1650 4950
	1    0    0    -1  
$EndComp
Wire Wire Line
	1650 4250 1650 3725
Connection ~ 1650 3425
Wire Wire Line
	1650 3425 2400 3425
Wire Wire Line
	1150 4550 1000 4550
Wire Wire Line
	1150 4650 1000 4650
Text Label 1125 4750 2    50   ~ 0
D2
Text Label 1125 4650 2    50   ~ 0
D1
Text Label 1125 4550 2    50   ~ 0
D0
Entry Wire Line
	900  4450 1000 4550
Entry Wire Line
	900  4550 1000 4650
Entry Wire Line
	900  4650 1000 4750
Wire Wire Line
	1000 4850 1150 4850
Wire Wire Line
	1150 4950 1000 4950
Text Label 1125 4950 2    50   ~ 0
D6
Text Label 1125 4850 2    50   ~ 0
D5
Entry Wire Line
	900  4750 1000 4850
Entry Wire Line
	900  4850 1000 4950
Wire Wire Line
	1000 4750 1150 4750
Text Label 2150 4550 0    50   ~ 0
MCLK
Text Label 2150 4650 0    50   ~ 0
MOSI
Text Label 2150 4750 0    50   ~ 0
~SSEL
Text Label 2150 4850 0    50   ~ 0
~WRITEN
Text Label 2150 4950 0    50   ~ 0
~ROMEN
$Comp
L 74xx:74LS139 U7
U 2 1 63C55C3D
P 3550 5375
F 0 "U7" H 3550 5742 50  0000 C CNN
F 1 "74HC139" H 3550 5651 50  0000 C CNN
F 2 "Package_DIP:DIP-16_W7.62mm" H 3550 5375 50  0001 C CNN
F 3 "http://www.ti.com/lit/gpn/sn74LS139" H 3550 5375 50  0001 C CNN
	2    3550 5375
	1    0    0    -1  
$EndComp
$Comp
L 74xx:74LS139 U5
U 3 1 63C56CFD
P 5950 1200
F 0 "U5" H 6180 1246 50  0000 L CNN
F 1 "74HC139" H 6180 1155 50  0000 L CNN
F 2 "Package_DIP:DIP-16_W7.62mm" H 5950 1200 50  0001 C CNN
F 3 "http://www.ti.com/lit/gpn/sn74LS139" H 5950 1200 50  0001 C CNN
	3    5950 1200
	1    0    0    -1  
$EndComp
Wire Wire Line
	2900 700  5950 700 
Connection ~ 2900 700 
Wire Wire Line
	4850 3550 5950 3550
Wire Wire Line
	5950 3550 5950 1700
Connection ~ 4850 3550
$Comp
L power:PWR_FLAG #FLG0101
U 1 1 63C697A9
P 6750 700
F 0 "#FLG0101" H 6750 775 50  0001 C CNN
F 1 "PWR_FLAG" H 6750 873 50  0000 C CNN
F 2 "" H 6750 700 50  0001 C CNN
F 3 "~" H 6750 700 50  0001 C CNN
	1    6750 700 
	1    0    0    -1  
$EndComp
Connection ~ 5950 700 
$Comp
L power:PWR_FLAG #FLG0102
U 1 1 63C69A23
P 6750 1700
F 0 "#FLG0102" H 6750 1775 50  0001 C CNN
F 1 "PWR_FLAG" H 6750 1873 50  0000 C CNN
F 2 "" H 6750 1700 50  0001 C CNN
F 3 "~" H 6750 1700 50  0001 C CNN
	1    6750 1700
	-1   0    0    1   
$EndComp
Connection ~ 5950 3550
Wire Wire Line
	3050 6525 2875 6525
Wire Wire Line
	2875 6525 2875 4625
NoConn ~ 4050 6725
Wire Wire Line
	1150 5250 1100 5250
Wire Wire Line
	1100 5250 1100 6075
Wire Wire Line
	1100 6075 4050 6075
Text Label 3425 6075 0    50   ~ 0
~LATCH
$Comp
L 74xx:74HC245 U6
U 1 1 63C85F32
P 4950 4650
F 0 "U6" H 5125 4000 50  0000 C CNN
F 1 "74HC245" H 4750 4000 50  0000 C CNN
F 2 "Package_DIP:DIP-20_W7.62mm" H 4950 4650 50  0001 C CNN
F 3 "http://www.ti.com/lit/gpn/sn74HC245" H 4950 4650 50  0001 C CNN
	1    4950 4650
	-1   0    0    -1  
$EndComp
Wire Wire Line
	4950 5750 4950 5450
$Comp
L power:GND #PWR0103
U 1 1 63C8EA90
P 1650 5750
F 0 "#PWR0103" H 1650 5500 50  0001 C CNN
F 1 "GND" H 1655 5577 50  0000 C CNN
F 2 "" H 1650 5750 50  0001 C CNN
F 3 "" H 1650 5750 50  0001 C CNN
	1    1650 5750
	1    0    0    -1  
$EndComp
Connection ~ 1650 5750
Wire Wire Line
	1950 3025 2350 3025
Wire Wire Line
	2350 3025 2350 3975
Text Label 2825 6725 2    50   ~ 0
~IOC
Wire Wire Line
	4450 4450 4450 4550
NoConn ~ 2150 5050
Wire Wire Line
	1650 4250 850  4250
Wire Wire Line
	850  4250 850  5050
Wire Wire Line
	850  5050 1150 5050
Connection ~ 1650 4250
Text Label 4450 4150 2    50   ~ 0
MCLK
Text Label 4450 4250 2    50   ~ 0
MOSI
Text Label 4450 4350 2    50   ~ 0
~SSEL
Text Label 4450 4750 2    50   ~ 0
~ROMEN
Text Label 4450 4850 2    50   ~ 0
MISO
Wire Wire Line
	5450 6525 5450 5150
Wire Wire Line
	5450 5050 5950 5050
Wire Wire Line
	5600 4150 5450 4150
Wire Wire Line
	5600 4250 5450 4250
Wire Wire Line
	5600 4350 5450 4350
Wire Wire Line
	5600 4450 5450 4450
Wire Wire Line
	5600 4550 5450 4550
Wire Wire Line
	5450 4650 5600 4650
Wire Wire Line
	5600 4750 5450 4750
Wire Wire Line
	5450 4850 5600 4850
Text Label 5575 4850 2    50   ~ 0
D7
Text Label 5575 4750 2    50   ~ 0
D6
Text Label 5575 4650 2    50   ~ 0
D5
Text Label 5575 4550 2    50   ~ 0
D4
Text Label 5575 4450 2    50   ~ 0
D3
Text Label 5575 4350 2    50   ~ 0
D2
Text Label 5575 4250 2    50   ~ 0
D1
Text Label 5575 4150 2    50   ~ 0
D0
Entry Wire Line
	5600 4150 5700 4050
Entry Wire Line
	5600 4250 5700 4150
Entry Wire Line
	5600 4350 5700 4250
Entry Wire Line
	5600 4450 5700 4350
Entry Wire Line
	5600 4550 5700 4450
Entry Wire Line
	5600 4650 5700 4550
Entry Wire Line
	5600 4750 5700 4650
Entry Wire Line
	5600 4850 5700 4750
Wire Wire Line
	4050 6425 4050 6075
Wire Wire Line
	4050 6525 5450 6525
Text Label 4425 6525 0    50   ~ 0
~STATUS
Wire Wire Line
	2350 3975 2825 3975
$Comp
L 74xx:74LS139 U5
U 1 1 63C54FD8
P 3550 6525
F 0 "U5" H 3550 6892 50  0000 C CNN
F 1 "74HC139" H 3550 6801 50  0000 C CNN
F 2 "Package_DIP:DIP-16_W7.62mm" H 3550 6525 50  0001 C CNN
F 3 "http://www.ti.com/lit/gpn/sn74LS139" H 3550 6525 50  0001 C CNN
	1    3550 6525
	1    0    0    -1  
$EndComp
Wire Wire Line
	5950 5050 5950 3550
Wire Wire Line
	2900 3550 4850 3550
$Comp
L power:+5V #PWR0106
U 1 1 63DFAAE7
P 4450 4450
F 0 "#PWR0106" H 4450 4300 50  0001 C CNN
F 1 "+5V" V 4465 4578 50  0000 L CNN
F 2 "" H 4450 4450 50  0001 C CNN
F 3 "" H 4450 4450 50  0001 C CNN
	1    4450 4450
	0    -1   -1   0   
$EndComp
Connection ~ 4450 4450
$Comp
L 74xx:74LS139 U7
U 1 1 63E2DFD0
P 3550 4625
F 0 "U7" H 3550 4992 50  0000 C CNN
F 1 "74HC139" H 3550 4901 50  0000 C CNN
F 2 "Package_DIP:DIP-16_W7.62mm" H 3550 4625 50  0001 C CNN
F 3 "http://www.ti.com/lit/gpn/sn74LS139" H 3550 4625 50  0001 C CNN
	1    3550 4625
	1    0    0    -1  
$EndComp
Wire Wire Line
	2925 4825 2925 3825
Connection ~ 2925 3825
Wire Wire Line
	2925 3825 4100 3825
Wire Wire Line
	2925 4825 3050 4825
Wire Wire Line
	3050 4625 2875 4625
Wire Wire Line
	2150 4850 2775 4850
Wire Wire Line
	2775 4850 2775 4525
Wire Wire Line
	2775 4525 3050 4525
NoConn ~ 4050 4625
NoConn ~ 4050 4725
NoConn ~ 4050 4825
Connection ~ 2875 4625
Wire Wire Line
	2875 4625 2875 3925
Wire Wire Line
	4050 4525 4050 3250
Wire Wire Line
	4050 3250 4250 3250
Wire Wire Line
	1150 2375 1050 2375
Wire Wire Line
	1050 2375 1050 4150
Wire Wire Line
	1050 4150 2675 4150
Wire Wire Line
	2675 4150 2675 5575
Wire Wire Line
	2675 5575 3050 5575
Text Label 2625 4150 0    50   ~ 0
~OE
Wire Wire Line
	2150 4950 2625 4950
Wire Wire Line
	2625 4950 2625 5275
Wire Wire Line
	2625 5275 3050 5275
Text Label 4450 4650 2    50   ~ 0
~WRITEN
NoConn ~ 4050 5275
NoConn ~ 4050 5475
Wire Wire Line
	2500 3275 2500 5150
Wire Wire Line
	2500 5150 4100 5150
Wire Wire Line
	4100 5150 4100 5375
Wire Wire Line
	4100 5375 4050 5375
Wire Wire Line
	4050 5575 4150 5575
Wire Wire Line
	4150 5575 4150 3150
Wire Wire Line
	4150 3150 4250 3150
Text Label 4150 5575 0    50   ~ 0
RAM~OE
Text Label 3850 5150 0    50   ~ 0
ROM~OE
$Comp
L 74xx:74LS139 U7
U 3 1 63EE4A54
P 6750 1200
F 0 "U7" H 6980 1246 50  0000 L CNN
F 1 "74HC139" H 6980 1155 50  0000 L CNN
F 2 "Package_DIP:DIP-16_W7.62mm" H 6750 1200 50  0001 C CNN
F 3 "http://www.ti.com/lit/gpn/sn74LS139" H 6750 1200 50  0001 C CNN
	3    6750 1200
	1    0    0    -1  
$EndComp
Wire Wire Line
	5950 700  6750 700 
Wire Wire Line
	6750 1700 5950 1700
Connection ~ 5950 1700
Wire Wire Line
	4950 5750 5950 5750
Wire Wire Line
	5950 5750 5950 5050
Connection ~ 4950 5750
Connection ~ 5950 5050
Connection ~ 5950 5750
Connection ~ 6750 1700
Connection ~ 6750 700 
Wire Wire Line
	4950 3850 4950 3725
Wire Wire Line
	4950 3725 2575 3725
Connection ~ 1650 3725
Wire Wire Line
	1650 3725 1650 3425
Text Label 1150 5450 2    50   Italic 0
~RST
$Comp
L 74xx:74LS139 U5
U 2 1 63F159D8
P 3550 7250
F 0 "U5" H 3550 7617 50  0000 C CNN
F 1 "74HC139" H 3550 7526 50  0000 C CNN
F 2 "Package_DIP:DIP-16_W7.62mm" H 3550 7250 50  0001 C CNN
F 3 "http://www.ti.com/lit/gpn/sn74LS139" H 3550 7250 50  0001 C CNN
	2    3550 7250
	1    0    0    -1  
$EndComp
Wire Wire Line
	3050 5375 2575 5375
Wire Wire Line
	2575 5375 2575 3725
Connection ~ 2575 3725
Wire Wire Line
	2575 3725 1650 3725
NoConn ~ 4050 7250
NoConn ~ 4050 7350
NoConn ~ 4050 7450
Wire Wire Line
	5950 5750 6700 5750
Wire Wire Line
	5950 5050 6700 5050
NoConn ~ 6700 5150
Wire Wire Line
	4950 3725 6650 3725
Wire Wire Line
	6650 3725 6650 5250
Wire Wire Line
	6650 5250 6700 5250
Connection ~ 4950 3725
Text Label 6700 5350 2    50   ~ 0
~SSEL
Text Label 6700 5450 2    50   ~ 0
MOSI
Text Label 6700 5550 2    50   ~ 0
MCLK
Text Label 6700 5650 2    50   ~ 0
MISO
$Comp
L Connector_Generic:Conn_02x08_Odd_Even J2
U 1 1 63B847A5
P 7000 5350
F 0 "J2" H 7050 5867 50  0000 C CNN
F 1 "SD Interface" H 7050 5776 50  0000 C CNN
F 2 "Connector_PinHeader_2.54mm:PinHeader_2x08_P2.54mm_Horizontal" H 7000 5350 50  0001 C CNN
F 3 "~" H 7000 5350 50  0001 C CNN
	1    7000 5350
	-1   0    0    -1  
$EndComp
Wire Wire Line
	6700 5050 7200 5050
Connection ~ 6700 5050
NoConn ~ 7200 5150
Wire Wire Line
	6700 5250 7200 5250
Connection ~ 6700 5250
Wire Wire Line
	6700 5350 7200 5350
Wire Wire Line
	6700 5450 7200 5450
Wire Wire Line
	6700 5550 7200 5550
Wire Wire Line
	6700 5650 7200 5650
Wire Wire Line
	6700 5750 7200 5750
Connection ~ 6700 5750
$Comp
L Graphic:Logo_Open_Hardware_Small LOGO2
U 1 1 63BF61E9
P 10600 1875
F 0 "LOGO2" H 10600 2150 50  0001 C CNN
F 1 "Logo_Open_Hardware_Small" H 10600 1650 50  0001 C CNN
F 2 "durango:jaqueria" H 10600 1875 50  0001 C CNN
F 3 "~" H 10600 1875 50  0001 C CNN
	1    10600 1875
	1    0    0    -1  
$EndComp
Text Label 4050 4150 1    50   ~ 0
G~WE
NoConn ~ 4050 6625
Wire Wire Line
	1650 5750 4950 5750
Wire Wire Line
	3000 6925 4050 6925
Wire Wire Line
	4050 6925 4050 7150
Text Label 3050 7450 2    50   ~ 0
A3
Text Label 3050 7150 2    50   ~ 0
A5
Text Label 3050 7250 2    50   ~ 0
A4
Text Label 4050 7050 0    50   ~ 0
~BL0
Text Notes 5950 2875 0    200  ~ 40
32 KiB shadow RAM + SD\n$DFC0-$DFC7
Text Notes 6700 4725 0    100  ~ 20
D0 = MCLK\nD1 = MOSI\nD2 = ~SSEL\nD5 = ~WRITEN\nD6 = ~ROMEN\nD7 = MISO
Wire Wire Line
	3000 6925 3000 6425
Wire Wire Line
	3000 6425 3050 6425
Wire Wire Line
	3050 6725 2825 6725
Wire Wire Line
	2825 3975 2825 6725
Wire Bus Line
	3550 875  3550 2075
Wire Bus Line
	2225 775  2225 2775
Wire Bus Line
	900  875  900  4850
Wire Bus Line
	3975 775  3975 2750
Wire Bus Line
	5700 875  5700 4750
$EndSCHEMATC
