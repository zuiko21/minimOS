EESchema Schematic File Version 4
LIBS:pal-ntsc-cache
EELAYER 29 0
EELAYER END
$Descr A4 11693 8268
encoding utf-8
Sheet 1 1
Title "PAL/NTSC encoder for Durango·X"
Date "2024-05-16"
Rev "v1"
Comp "@zuiko21"
Comment1 ""
Comment2 ""
Comment3 ""
Comment4 ""
$EndDescr
$Comp
L Video:AD725 U1
U 1 1 6645EBCE
P 6300 2700
F 0 "U1" H 5950 3250 50  0000 C CNN
F 1 "AD724" H 6650 3250 50  0000 C CNN
F 2 "Package_SO:SOIC-16W_7.5x10.3mm_P1.27mm" H 6300 3450 50  0001 C CNN
F 3 "https://www.analog.com/media/en/technical-documentation/data-sheets/AD725.pdf" H 6300 2700 50  0001 C CNN
	1    6300 2700
	1    0    0    -1  
$EndComp
NoConn ~ 7200 2800
NoConn ~ 7200 2400
Wire Wire Line
	6200 3400 6400 3400
Connection ~ 6400 3400
Text Notes 6950 3100 0    50   ~ 0
SELECT
Wire Wire Line
	6200 2050 6350 2050
Wire Wire Line
	5400 2600 5350 2600
Wire Wire Line
	5350 2600 5350 2050
Wire Wire Line
	5350 2050 6200 2050
Connection ~ 6200 2050
$Comp
L Device:C C1
U 1 1 66460D27
P 4750 2900
F 0 "C1" V 4700 2800 50  0000 C CNN
F 1 "100n" V 4800 2750 50  0000 C CNN
F 2 "Capacitor_THT:C_Rect_L7.2mm_W2.5mm_P5.00mm_FKS2_FKP2_MKS2_MKP2" H 4788 2750 50  0001 C CNN
F 3 "~" H 4750 2900 50  0001 C CNN
	1    4750 2900
	0    1    1    0   
$EndComp
$Comp
L Device:C C2
U 1 1 6646193C
P 5050 3000
F 0 "C2" V 5000 2900 50  0000 C CNN
F 1 "100n" V 5100 2850 50  0000 C CNN
F 2 "Capacitor_THT:C_Rect_L7.2mm_W2.5mm_P5.00mm_FKS2_FKP2_MKS2_MKP2" H 5088 2850 50  0001 C CNN
F 3 "~" H 5050 3000 50  0001 C CNN
	1    5050 3000
	0    1    1    0   
$EndComp
$Comp
L Device:C C3
U 1 1 66461DCA
P 4750 3100
F 0 "C3" V 4700 3000 50  0000 C CNN
F 1 "100n" V 4800 2950 50  0000 C CNN
F 2 "Capacitor_THT:C_Rect_L7.2mm_W2.5mm_P5.00mm_FKS2_FKP2_MKS2_MKP2" H 4788 2950 50  0001 C CNN
F 3 "~" H 4750 3100 50  0001 C CNN
	1    4750 3100
	0    1    1    0   
$EndComp
Wire Wire Line
	4900 2900 5400 2900
Wire Wire Line
	5200 3000 5400 3000
Wire Wire Line
	4900 3100 5400 3100
Text Label 5400 2900 2    50   ~ 0
R_AC
Text Label 5400 3000 2    50   ~ 0
G_AC
Text Label 5400 3100 2    50   ~ 0
B_AC
$Comp
L Transistor_BJT:BC548 Q2
U 1 1 6646459E
P 5100 5200
F 0 "Q2" H 4950 5300 50  0000 L CNN
F 1 "BC548" V 5300 5100 50  0000 L CNN
F 2 "Package_TO_SOT_THT:TO-92_Inline" H 5300 5125 50  0001 L CIN
F 3 "http://www.fairchildsemi.com/ds/BC/BC547.pdf" H 5100 5200 50  0001 L CNN
	1    5100 5200
	-1   0    0    -1  
$EndComp
$Comp
L Transistor_BJT:BC548 Q3
U 1 1 664651D8
P 5550 5000
F 0 "Q3" H 5741 5046 50  0000 L CNN
F 1 "BC548" H 5741 4955 50  0000 L CNN
F 2 "Package_TO_SOT_THT:TO-92_Inline" H 5750 4925 50  0001 L CIN
F 3 "http://www.fairchildsemi.com/ds/BC/BC547.pdf" H 5550 5000 50  0001 L CNN
	1    5550 5000
	1    0    0    -1  
$EndComp
$Comp
L Transistor_BJT:BC548 Q1
U 1 1 6646590F
P 4250 3700
F 0 "Q1" H 4441 3746 50  0000 L CNN
F 1 "BC548" H 4441 3655 50  0000 L CNN
F 2 "Package_TO_SOT_THT:TO-92_Inline" H 4450 3625 50  0001 L CIN
F 3 "http://www.fairchildsemi.com/ds/BC/BC547.pdf" H 4250 3700 50  0001 L CNN
	1    4250 3700
	1    0    0    -1  
$EndComp
$Comp
L Device:CP C8
U 1 1 66466536
P 7100 2050
F 0 "C8" V 7150 2150 50  0000 C CNN
F 1 "220µ" V 7150 1750 50  0000 C CNN
F 2 "Capacitor_THT:CP_Radial_D6.3mm_P2.50mm" H 7138 1900 50  0001 C CNN
F 3 "~" H 7100 2050 50  0001 C CNN
	1    7100 2050
	0    -1   -1   0   
$EndComp
$Comp
L Device:CP C7
U 1 1 66466ACD
P 7450 3900
F 0 "C7" V 7600 3900 50  0000 C CNN
F 1 "100µ" V 7300 3900 50  0000 C CNN
F 2 "Capacitor_THT:CP_Radial_D4.0mm_P1.50mm" H 7488 3750 50  0001 C CNN
F 3 "~" H 7450 3900 50  0001 C CNN
	1    7450 3900
	0    -1   -1   0   
$EndComp
$Comp
L Device:CP C6
U 1 1 66467060
P 3600 3700
F 0 "C6" V 3750 3700 50  0000 C CNN
F 1 "100µ" V 3450 3700 50  0000 C CNN
F 2 "Capacitor_THT:CP_Radial_D4.0mm_P1.50mm" H 3638 3550 50  0001 C CNN
F 3 "~" H 3600 3700 50  0001 C CNN
	1    3600 3700
	0    1    1    0   
$EndComp
$Comp
L Device:CP C4
U 1 1 66467527
P 5800 5300
F 0 "C4" V 5900 5200 50  0000 C CNN
F 1 "100µ" V 5700 5150 50  0000 C CNN
F 2 "Capacitor_THT:CP_Radial_D4.0mm_P1.50mm" H 5838 5150 50  0001 C CNN
F 3 "~" H 5800 5300 50  0001 C CNN
	1    5800 5300
	0    -1   -1   0   
$EndComp
$Comp
L Jumper:SolderJumper_3_Bridged12 JP1
U 1 1 66467F7F
P 5150 2050
F 0 "JP1" H 5150 2267 50  0000 C CNN
F 1 "NTSC/~PAL" H 5150 2169 50  0000 C CNN
F 2 "Jumper:SolderJumper-3_P1.3mm_Bridged12_RoundedPad1.0x1.5mm" H 5150 2050 50  0001 C CNN
F 3 "~" H 5150 2050 50  0001 C CNN
	1    5150 2050
	-1   0    0    -1  
$EndComp
Connection ~ 5350 2050
$Comp
L power:GND #PWR0101
U 1 1 6646A315
P 6400 3400
F 0 "#PWR0101" H 6400 3150 50  0001 C CNN
F 1 "GND" H 6405 3227 50  0000 C CNN
F 2 "" H 6400 3400 50  0001 C CNN
F 3 "" H 6400 3400 50  0001 C CNN
	1    6400 3400
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR0102
U 1 1 6646A4EF
P 4950 2050
F 0 "#PWR0102" H 4950 1800 50  0001 C CNN
F 1 "GND" V 4955 1922 50  0000 R CNN
F 2 "" H 4950 2050 50  0001 C CNN
F 3 "" H 4950 2050 50  0001 C CNN
	1    4950 2050
	0    1    1    0   
$EndComp
Wire Wire Line
	5400 2400 5150 2400
Wire Wire Line
	5150 2400 5150 2200
Text Label 5150 2400 0    50   ~ 0
~PAL
Wire Wire Line
	5400 2700 5300 2700
Wire Wire Line
	5300 2700 5300 3400
Text Label 5300 3400 2    50   ~ 0
XTAL
$Comp
L Device:Crystal Y1
U 1 1 6646B88B
P 5450 3400
F 0 "Y1" H 5450 3550 50  0000 C CNN
F 1 "3.58 MHz (PAL=4.43)" H 5450 3250 50  0000 C CNN
F 2 "Crystal:Crystal_HC49-4H_Vertical" H 5450 3400 50  0001 C CNN
F 3 "~" H 5450 3400 50  0001 C CNN
	1    5450 3400
	1    0    0    -1  
$EndComp
Wire Wire Line
	5600 3400 6200 3400
Connection ~ 6200 3400
$Comp
L Device:C C9
U 1 1 6646C871
P 7100 1850
F 0 "C9" V 7050 1750 50  0000 C CNN
F 1 "22n" V 7050 2000 50  0000 C CNN
F 2 "Capacitor_THT:C_Rect_L7.2mm_W2.5mm_P5.00mm_FKS2_FKP2_MKS2_MKP2" H 7138 1700 50  0001 C CNN
F 3 "~" H 7100 1850 50  0001 C CNN
	1    7100 1850
	0    1    1    0   
$EndComp
Wire Wire Line
	6350 2050 6950 2050
Connection ~ 6350 2050
Wire Wire Line
	6950 1850 6950 2050
Connection ~ 6950 2050
Wire Wire Line
	7250 2050 7250 1850
Wire Wire Line
	7250 2050 7250 3000
Connection ~ 7250 2050
Wire Wire Line
	6400 3400 7250 3400
Wire Wire Line
	7200 3000 7250 3000
Connection ~ 7250 3000
Wire Wire Line
	7250 3000 7250 3400
$Comp
L Device:R R13
U 1 1 66471925
P 7950 2600
F 0 "R13" V 7850 2600 50  0000 C CNN
F 1 "75" V 7950 2600 50  0000 C CNN
F 2 "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P10.16mm_Horizontal" V 7880 2600 50  0001 C CNN
F 3 "~" H 7950 2600 50  0001 C CNN
	1    7950 2600
	0    1    1    0   
$EndComp
Wire Wire Line
	7300 2600 7200 2600
Text Label 7200 2600 1    50   ~ 0
COUT
Text Label 8100 2600 0    50   ~ 0
SV_C
$Comp
L Device:C C5
U 1 1 664730A6
P 7450 2600
F 0 "C5" V 7300 2600 50  0000 C CNN
F 1 "22n" V 7600 2600 50  0000 C CNN
F 2 "Capacitor_THT:C_Rect_L7.2mm_W2.5mm_P5.00mm_FKS2_FKP2_MKS2_MKP2" H 7488 2450 50  0001 C CNN
F 3 "~" H 7450 2600 50  0001 C CNN
	1    7450 2600
	0    1    1    0   
$EndComp
Text Label 7600 2600 0    50   ~ 0
C_AC
Wire Wire Line
	7600 2600 7800 2600
$Comp
L power:+5V #PWR0103
U 1 1 664750A6
P 6350 2050
F 0 "#PWR0103" H 6350 1900 50  0001 C CNN
F 1 "+5V" H 6365 2223 50  0000 C CNN
F 2 "" H 6350 2050 50  0001 C CNN
F 3 "" H 6350 2050 50  0001 C CNN
	1    6350 2050
	1    0    0    -1  
$EndComp
$Comp
L power:PWR_FLAG #FLG0101
U 1 1 66475376
P 6200 2050
F 0 "#FLG0101" H 6200 2125 50  0001 C CNN
F 1 "PWR_FLAG" H 5950 2100 50  0000 C CNN
F 2 "" H 6200 2050 50  0001 C CNN
F 3 "~" H 6200 2050 50  0001 C CNN
	1    6200 2050
	1    0    0    -1  
$EndComp
$Comp
L power:PWR_FLAG #FLG0102
U 1 1 66475A40
P 6200 3400
F 0 "#FLG0102" H 6200 3475 50  0001 C CNN
F 1 "PWR_FLAG" H 5950 3450 50  0000 C CNN
F 2 "" H 6200 3400 50  0001 C CNN
F 3 "~" H 6200 3400 50  0001 C CNN
	1    6200 3400
	1    0    0    1   
$EndComp
Text Label 7600 3900 0    50   ~ 0
SV_L
Text Label 3750 3700 0    50   ~ 0
Y_BIAS
Wire Wire Line
	3750 3700 4050 3700
Text Label 3400 3700 2    50   ~ 0
Y
Text Label 4450 3900 0    50   ~ 0
Y_BUF
$Comp
L Device:R R1
U 1 1 66482099
P 4050 3550
F 0 "R1" H 3900 3600 50  0000 L CNN
F 1 "150" V 4050 3550 50  0000 C CNN
F 2 "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P10.16mm_Horizontal" V 3980 3550 50  0001 C CNN
F 3 "~" H 4050 3550 50  0001 C CNN
	1    4050 3550
	1    0    0    -1  
$EndComp
Connection ~ 4050 3700
$Comp
L Device:R R2
U 1 1 66482A39
P 4050 4050
F 0 "R2" H 3900 4100 50  0000 L CNN
F 1 "150" V 4050 4050 50  0000 C CNN
F 2 "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P10.16mm_Horizontal" V 3980 4050 50  0001 C CNN
F 3 "~" H 4050 4050 50  0001 C CNN
	1    4050 4050
	1    0    0    -1  
$EndComp
$Comp
L Device:R R3
U 1 1 664831E7
P 4350 4050
F 0 "R3" H 4200 4100 50  0000 L CNN
F 1 "150" V 4350 4050 50  0000 C CNN
F 2 "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P10.16mm_Horizontal" V 4280 4050 50  0001 C CNN
F 3 "~" H 4350 4050 50  0001 C CNN
	1    4350 4050
	1    0    0    -1  
$EndComp
Connection ~ 4350 3900
Wire Wire Line
	4050 4200 4350 4200
Wire Wire Line
	4350 3500 4350 3400
Wire Wire Line
	4350 3400 4050 3400
Wire Wire Line
	5350 2600 4350 2600
Wire Wire Line
	4350 2600 4350 3400
Connection ~ 5350 2600
Connection ~ 4350 3400
Wire Wire Line
	4050 3900 4050 3700
$Comp
L power:GND #PWR0104
U 1 1 66486960
P 4350 4200
F 0 "#PWR0104" H 4350 3950 50  0001 C CNN
F 1 "GND" H 4500 4150 50  0000 C CNN
F 2 "" H 4350 4200 50  0001 C CNN
F 3 "" H 4350 4200 50  0001 C CNN
	1    4350 4200
	1    0    0    -1  
$EndComp
Connection ~ 4350 4200
$Comp
L Device:R R4
U 1 1 66487800
P 5300 4800
F 0 "R4" H 5150 4850 50  0000 L CNN
F 1 "6K8" V 5300 4800 50  0000 C CNN
F 2 "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P10.16mm_Horizontal" V 5230 4800 50  0001 C CNN
F 3 "~" H 5300 4800 50  0001 C CNN
	1    5300 4800
	1    0    0    -1  
$EndComp
$Comp
L Device:R R5
U 1 1 66488335
P 5300 5550
F 0 "R5" H 5150 5600 50  0000 L CNN
F 1 "3K3" V 5300 5550 50  0000 C CNN
F 2 "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P10.16mm_Horizontal" V 5230 5550 50  0001 C CNN
F 3 "~" H 5300 5550 50  0001 C CNN
	1    5300 5550
	1    0    0    -1  
$EndComp
Wire Wire Line
	5300 4950 5300 5200
Connection ~ 5300 5200
Wire Wire Line
	5300 5200 5300 5400
Text Label 5300 5400 2    50   ~ 0
BIAS
$Comp
L Device:R R6
U 1 1 6648A036
P 5000 4800
F 0 "R6" H 4850 4850 50  0000 L CNN
F 1 "680" V 5000 4800 50  0000 C CNN
F 2 "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P10.16mm_Horizontal" V 4930 4800 50  0001 C CNN
F 3 "~" H 5000 4800 50  0001 C CNN
	1    5000 4800
	1    0    0    -1  
$EndComp
Wire Wire Line
	5000 4950 5000 5000
Wire Wire Line
	5350 5000 5000 5000
Connection ~ 5000 5000
Text Label 5050 5000 0    50   ~ 0
ZMIX
Wire Wire Line
	5650 4800 5650 4650
Wire Wire Line
	5650 4650 5300 4650
Connection ~ 5300 4650
Wire Wire Line
	5300 4650 5000 4650
$Comp
L Device:R R7
U 1 1 6648DF87
P 5000 5550
F 0 "R7" H 4850 5600 50  0000 L CNN
F 1 "180" V 5000 5550 50  0000 C CIN
F 2 "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P10.16mm_Horizontal" V 4930 5550 50  0001 C CNN
F 3 "~" H 5000 5550 50  0001 C CNN
	1    5000 5550
	1    0    0    -1  
$EndComp
Wire Wire Line
	5000 5700 5300 5700
$Comp
L Device:R R8
U 1 1 6648F445
P 5650 5550
F 0 "R8" H 5500 5600 50  0000 L CNN
F 1 "330" V 5650 5550 50  0000 C CNN
F 2 "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P10.16mm_Horizontal" V 5580 5550 50  0001 C CNN
F 3 "~" H 5650 5550 50  0001 C CNN
	1    5650 5550
	1    0    0    -1  
$EndComp
Wire Wire Line
	5650 5700 5300 5700
Connection ~ 5300 5700
Wire Wire Line
	5650 5400 5650 5300
Text Label 5650 5400 2    50   ~ 0
MIX
Connection ~ 5650 5300
Wire Wire Line
	5650 5300 5650 5200
$Comp
L Device:R R14
U 1 1 66492C88
P 4800 4050
F 0 "R14" H 4600 4050 50  0000 L CNN
F 1 "330" V 4800 4050 50  0000 C CNN
F 2 "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P10.16mm_Horizontal" V 4730 4050 50  0001 C CNN
F 3 "~" H 4800 4050 50  0001 C CNN
	1    4800 4050
	1    0    0    -1  
$EndComp
Connection ~ 4800 3900
Wire Wire Line
	4800 3900 7300 3900
Wire Wire Line
	4350 3900 4800 3900
Wire Wire Line
	4800 4200 4800 4300
Wire Wire Line
	4800 5400 5000 5400
Connection ~ 5000 5400
$Comp
L Device:R R15
U 1 1 66495915
P 5050 4300
F 0 "R15" V 4950 4300 50  0000 C CNN
F 1 "680" V 5050 4300 50  0000 C CIN
F 2 "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P10.16mm_Horizontal" V 4980 4300 50  0001 C CNN
F 3 "~" H 5050 4300 50  0001 C CNN
	1    5050 4300
	0    1    1    0   
$EndComp
Wire Wire Line
	4900 4300 4800 4300
Connection ~ 4800 4300
Wire Wire Line
	4800 4300 4800 5400
Text Label 4800 5400 2    50   ~ 0
MIX_IN
Wire Wire Line
	5200 4300 7800 4300
Wire Wire Line
	7800 4300 7800 2600
Connection ~ 7800 2600
Text Label 5950 5300 0    50   ~ 0
MIX_AC
$Comp
L Device:R R9
U 1 1 66498DE9
P 6400 5300
F 0 "R9" V 6300 5300 50  0000 C CNN
F 1 "75" V 6400 5300 50  0000 C CNN
F 2 "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P10.16mm_Horizontal" V 6330 5300 50  0001 C CNN
F 3 "~" H 6400 5300 50  0001 C CNN
	1    6400 5300
	0    1    1    0   
$EndComp
Wire Wire Line
	5950 5300 6250 5300
Text Label 6550 5300 0    50   ~ 0
CVBS
$Comp
L power:+5V #PWR0105
U 1 1 6649B0C4
P 5650 4650
F 0 "#PWR0105" H 5650 4500 50  0001 C CNN
F 1 "+5V" H 5665 4823 50  0000 C CNN
F 2 "" H 5650 4650 50  0001 C CNN
F 3 "" H 5650 4650 50  0001 C CNN
	1    5650 4650
	1    0    0    -1  
$EndComp
Connection ~ 5650 4650
$Comp
L power:GND #PWR0106
U 1 1 6649B42D
P 5650 5700
F 0 "#PWR0106" H 5650 5450 50  0001 C CNN
F 1 "GND" H 5655 5527 50  0000 C CNN
F 2 "" H 5650 5700 50  0001 C CNN
F 3 "" H 5650 5700 50  0001 C CNN
	1    5650 5700
	1    0    0    -1  
$EndComp
Connection ~ 5650 5700
$Comp
L Device:R R10
U 1 1 6649BFBE
P 3050 3300
F 0 "R10" V 3000 3400 50  0000 L CNN
F 1 "75" V 3050 3300 50  0000 C CNN
F 2 "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P10.16mm_Horizontal" V 2980 3300 50  0001 C CNN
F 3 "~" H 3050 3300 50  0001 C CNN
	1    3050 3300
	1    0    0    -1  
$EndComp
$Comp
L Device:R R11
U 1 1 6649E01A
P 3150 3300
F 0 "R11" V 3100 3400 50  0000 L CNN
F 1 "75" V 3150 3300 50  0000 C CNN
F 2 "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P10.16mm_Horizontal" V 3080 3300 50  0001 C CNN
F 3 "~" H 3150 3300 50  0001 C CNN
	1    3150 3300
	1    0    0    -1  
$EndComp
$Comp
L Device:R R12
U 1 1 6649E459
P 3250 3300
F 0 "R12" V 3200 3400 50  0000 L CNN
F 1 "75" V 3250 3300 50  0000 C CNN
F 2 "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P10.16mm_Horizontal" V 3180 3300 50  0001 C CNN
F 3 "~" H 3250 3300 50  0001 C CNN
	1    3250 3300
	1    0    0    -1  
$EndComp
Wire Wire Line
	3250 3150 3250 3100
Wire Wire Line
	3250 3100 4600 3100
Wire Wire Line
	3150 3150 3150 3000
Wire Wire Line
	3150 3000 4900 3000
Wire Wire Line
	3050 3150 3050 2900
Wire Wire Line
	3050 2900 4600 2900
Wire Wire Line
	3050 3450 3150 3450
Connection ~ 3150 3450
Wire Wire Line
	3150 3450 3250 3450
Wire Wire Line
	4050 4200 3250 4200
Wire Wire Line
	3250 4200 3250 3450
Connection ~ 4050 4200
Connection ~ 3250 3450
Text Label 3300 2900 0    50   ~ 0
RED
Text Label 3300 3000 0    50   ~ 0
GREEN
Text Label 3300 3100 0    50   ~ 0
BLUE
$Comp
L Connector_Generic:Conn_01x01 J103
U 1 1 66479FC9
P 4350 1850
F 0 "J103" V 4320 1762 50  0000 R CNN
F 1 "~CSYNC" V 4450 1850 50  0000 C CNN
F 2 "Connector_PinHeader_2.54mm:PinHeader_1x01_P2.54mm_Vertical" H 4350 1850 50  0001 C CNN
F 3 "~" H 4350 1850 50  0001 C CNN
	1    4350 1850
	0    -1   -1   0   
$EndComp
Wire Wire Line
	5400 2500 4350 2500
Wire Wire Line
	4350 2500 4350 2050
$Comp
L Connector:Mini-DIN-4 J4
U 1 1 6647E176
P 8600 2700
F 0 "J4" H 8600 3067 50  0000 C CNN
F 1 "S-Video" H 8600 2976 50  0000 C CNN
F 2 "Connector_PinHeader_2.54mm:PinHeader_1x04_P2.54mm_Horizontal" H 8600 2700 50  0001 C CNN
F 3 "http://service.powerdynamics.com/ec/Catalog17/Section%2011.pdf" H 8600 2700 50  0001 C CNN
	1    8600 2700
	1    0    0    -1  
$EndComp
Wire Wire Line
	8100 2600 8300 2600
Wire Wire Line
	8900 2600 8950 2600
Wire Wire Line
	8950 2600 8950 3900
Wire Wire Line
	8950 3900 7600 3900
Wire Wire Line
	7250 3400 8300 3400
Wire Wire Line
	8300 3400 8300 2700
Connection ~ 7250 3400
Wire Wire Line
	8300 3400 8900 3400
Wire Wire Line
	8900 3400 8900 2700
Connection ~ 8300 3400
$Comp
L Connector:Conn_Coaxial_x3 J5
U 1 1 66487181
P 7050 5100
F 0 "J5" H 7150 5103 50  0000 L CNN
F 1 "COMPOSITE" H 7150 5012 50  0000 L CNN
F 2 "durango:3xRCA" H 7050 5100 50  0001 C CNN
F 3 " ~" H 7050 5100 50  0001 C CNN
	1    7050 5100
	1    0    0    -1  
$EndComp
Wire Wire Line
	6550 5300 6850 5300
Wire Wire Line
	6800 5000 6800 5200
Connection ~ 6800 5200
Wire Wire Line
	6800 5200 6800 5400
Wire Wire Line
	5650 5700 6800 5700
Wire Wire Line
	6800 5700 6800 5400
Connection ~ 6800 5400
Wire Wire Line
	6850 5100 6750 5100
Wire Wire Line
	6750 5100 6750 4900
Wire Wire Line
	6750 4900 6850 4900
$Comp
L Connector_Generic:Conn_2Rows-21Pins J101
U 1 1 66525640
P 2600 4950
F 0 "J101" H 2650 5667 50  0000 C CNN
F 1 "SCART" H 2650 5576 50  0000 C CNN
F 2 "durango:SCART" H 2600 4950 50  0001 C CNN
F 3 "~" H 2600 4950 50  0001 C CNN
	1    2600 4950
	-1   0    0    -1  
$EndComp
Wire Wire Line
	2800 4750 2850 4750
Wire Wire Line
	2850 4750 2850 3100
Wire Wire Line
	2850 3100 3250 3100
Connection ~ 3250 3100
Wire Wire Line
	2800 4950 2900 4950
Wire Wire Line
	2900 4950 2900 3000
Wire Wire Line
	2900 3000 3150 3000
Connection ~ 3150 3000
Wire Wire Line
	3050 2900 2950 2900
Wire Wire Line
	2950 2900 2950 5150
Wire Wire Line
	2950 5150 2800 5150
Connection ~ 3050 2900
NoConn ~ 2800 4450
NoConn ~ 2800 4550
NoConn ~ 2800 5350
NoConn ~ 2300 4850
NoConn ~ 2300 4950
Wire Wire Line
	2800 4650 3000 4650
Wire Wire Line
	3000 4650 3000 4850
Wire Wire Line
	3000 4850 2800 4850
Wire Wire Line
	3000 4850 3000 5050
Wire Wire Line
	3000 5050 2800 5050
Connection ~ 3000 4850
Wire Wire Line
	3000 5050 3000 5250
Wire Wire Line
	3000 5250 2800 5250
Connection ~ 3000 5050
Wire Wire Line
	3000 5250 3000 5450
Wire Wire Line
	3000 5450 2800 5450
Connection ~ 3000 5250
Wire Wire Line
	3000 5450 3000 5700
Wire Wire Line
	3000 5700 5000 5700
Connection ~ 3000 5450
Connection ~ 5000 5700
Wire Wire Line
	2300 5350 2300 5600
Wire Wire Line
	2300 5600 3450 5600
Wire Wire Line
	3450 5600 3450 3700
Wire Wire Line
	4350 2600 2250 2600
Wire Wire Line
	2250 2600 2250 4750
Wire Wire Line
	2250 4750 2300 4750
Connection ~ 4350 2600
Wire Wire Line
	2300 4650 2200 4650
Wire Wire Line
	2200 4650 2200 4450
Wire Wire Line
	2200 4450 2300 4450
Wire Wire Line
	6750 4900 6750 4400
Wire Wire Line
	6750 4400 2200 4400
Wire Wire Line
	2200 4400 2200 4450
Connection ~ 6750 4900
Connection ~ 2200 4450
Text Label 3050 4400 0    50   ~ 0
AUDIO
Wire Wire Line
	2300 4550 2150 4550
Wire Wire Line
	2150 4550 2150 5050
Wire Wire Line
	2150 5050 2300 5050
Wire Wire Line
	2150 5050 2150 5250
Wire Wire Line
	2150 5250 2300 5250
Connection ~ 2150 5050
Wire Wire Line
	3000 5700 2150 5700
Wire Wire Line
	2150 5700 2150 5250
Connection ~ 3000 5700
Connection ~ 2150 5250
Wire Wire Line
	5400 2300 2100 2300
Wire Wire Line
	2100 2300 2100 5150
Wire Wire Line
	2100 5150 2300 5150
Text Label 2100 2300 0    50   ~ 0
RGB
Text Notes 2300 2600 0    50   ~ 0
POWER
$Comp
L Connector_Generic:Conn_02x05_Odd_Even J202
U 1 1 66483205
P 2550 1750
F 0 "J202" H 2600 1350 50  0000 C CNN
F 1 "RGB" H 2600 1450 50  0000 C CNN
F 2 "Connector_PinHeader_2.54mm:PinHeader_2x05_P2.54mm_Horizontal" H 2550 1750 50  0001 C CNN
F 3 "~" H 2550 1750 50  0001 C CNN
	1    2550 1750
	-1   0    0    1   
$EndComp
$Comp
L power:GND #PWR?
U 1 1 664B4163
P 2750 1950
F 0 "#PWR?" H 2750 1700 50  0001 C CNN
F 1 "GND" H 2755 1777 50  0000 C CNN
F 2 "" H 2750 1950 50  0001 C CNN
F 3 "" H 2750 1950 50  0001 C CNN
	1    2750 1950
	1    0    0    -1  
$EndComp
Wire Wire Line
	3050 2900 3050 1850
Wire Wire Line
	3050 1850 2750 1850
Wire Wire Line
	2750 1750 3150 1750
Wire Wire Line
	3150 1750 3150 3000
Wire Wire Line
	3250 3100 3250 1650
Wire Wire Line
	3250 1650 2750 1650
NoConn ~ 2750 1550
Wire Wire Line
	2250 1850 2000 1850
Wire Wire Line
	2000 1850 2000 3700
Wire Wire Line
	2000 3700 3450 3700
Connection ~ 3450 3700
Text Label 2200 1850 2    50   ~ 0
Y
Text Label 2800 1850 0    50   ~ 0
RED
Text Label 2800 1750 0    50   ~ 0
GREEN
Text Label 2800 1650 0    50   ~ 0
BLUE
Wire Wire Line
	2250 1750 1900 1750
Wire Wire Line
	1900 1750 1900 2500
Wire Wire Line
	1900 2500 4350 2500
Connection ~ 4350 2500
Text Label 2200 1750 2    50   ~ 0
~CSYNC
Wire Wire Line
	2250 1950 2250 2600
Connection ~ 2250 2600
Wire Wire Line
	2100 2300 2100 1650
Wire Wire Line
	2100 1650 2250 1650
Connection ~ 2100 2300
Text Label 2200 1550 2    50   ~ 0
AUDIO
Wire Wire Line
	2200 4400 1800 4400
Wire Wire Line
	1800 4400 1800 1550
Wire Wire Line
	1800 1550 2250 1550
Connection ~ 2200 4400
$EndSCHEMATC