EESchema Schematic File Version 4
EELAYER 30 0
EELAYER END
$Descr A4 11693 8268
encoding utf-8
Sheet 1 1
Title ""
Date ""
Rev ""
Comp ""
Comment1 ""
Comment2 ""
Comment3 ""
Comment4 ""
$EndDescr
$Comp
L we-rescue:74HC04 U1
U 1 1 60475C4A
P 2650 2550
F 0 "U1" H 2650 2865 50  0000 C CNN
F 1 "74HC04" H 2650 2774 50  0000 C CNN
F 2 "" H 2650 2550 50  0000 C CNN
F 3 "" H 2650 2550 50  0000 C CNN
	1    2650 2550
	1    0    0    -1  
$EndComp
$Comp
L we-rescue:74HC04 U1
U 1 1 60475CBD
P 2650 3850
F 0 "U1" H 2800 3950 50  0000 C CNN
F 1 "74HC04" H 2850 3750 50  0000 C CNN
F 2 "" H 2650 3850 50  0000 C CNN
F 3 "" H 2650 3850 50  0000 C CNN
	1    2650 3850
	1    0    0    -1  
$EndComp
$Comp
L we-rescue:74HC04 U1
U 2 1 60475D8A
P 3550 3850
F 0 "U1" H 3700 3950 50  0000 C CNN
F 1 "74HC04" H 3750 3750 50  0000 C CNN
F 2 "" H 3550 3850 50  0000 C CNN
F 3 "" H 3550 3850 50  0000 C CNN
	2    3550 3850
	1    0    0    -1  
$EndComp
Wire Wire Line
	2200 2300 2200 2550
Connection ~ 2200 2550
Wire Wire Line
	1950 2700 2200 2700
Connection ~ 2200 2700
Wire Wire Line
	2450 2700 2450 2900
Wire Wire Line
	1950 2700 1950 2900
Wire Wire Line
	2200 3600 2200 3850
Connection ~ 2200 3850
Wire Wire Line
	3100 3850 3100 4100
Wire Wire Line
	4000 3850 4000 4100
Wire Wire Line
	4000 3850 4250 3850
Wire Wire Line
	4250 3850 4250 4100
Connection ~ 4000 3850
Connection ~ 3100 3850
Text Notes 2100 2250 0    60   ~ 0
/Y3
Text Notes 1800 3150 0    60   ~ 0
VRAM\n/WE
Text Notes 2100 3150 0    60   ~ 0
LATCH\n/OE
Text Notes 2400 3150 0    60   ~ 0
DB\n/OE
Text Notes 3150 2700 0    60   ~ 0
COUNT\n /OE
Text Notes 2100 3550 0    60   ~ 0
/Y3
Text Notes 2050 4350 0    60   ~ 0
VRAM\n/WE
Text Notes 2950 4350 0    60   ~ 0
COUNT\n /OE
Text Notes 3850 4350 0    60   ~ 0
LATCH\n /OE
Text Notes 4200 4350 0    60   ~ 0
DB\n/OE
Wire Wire Line
	2200 2550 2200 2700
Wire Wire Line
	2200 2700 2450 2700
Wire Wire Line
	2200 2700 2200 2900
Wire Wire Line
	2200 3850 2200 4100
Connection ~ 4200 4700
$EndSCHEMATC
