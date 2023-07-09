EESchema Schematic File Version 4
EELAYER 29 0
EELAYER END
$Descr A4 11693 8268
encoding utf-8
Sheet 2 2
Title "Durango-X power & extra features"
Date ""
Rev ""
Comp ""
Comment1 ""
Comment2 ""
Comment3 ""
Comment4 ""
$EndDescr
$Comp
L power:GND #PWR?
U 1 1 6315BD20
P 1350 1300
F 0 "#PWR?" H 1350 1050 50  0001 C CNN
F 1 "GND" H 1355 1127 50  0000 C CNN
F 2 "" H 1350 1300 50  0001 C CNN
F 3 "" H 1350 1300 50  0001 C CNN
	1    1350 1300
	1    0    0    -1  
$EndComp
$Comp
L Device:CP C?
U 1 1 6315BFF0
P 1350 1150
F 0 "C?" H 1400 1250 50  0000 L CNN
F 1 "470uF" H 1350 1050 50  0000 L CNN
F 2 "Capacitor_THT:CP_Radial_D6.3mm_P2.50mm" H 1388 1000 50  0001 C CNN
F 3 "~" H 1350 1150 50  0001 C CNN
	1    1350 1150
	1    0    0    -1  
$EndComp
Wire Wire Line
	850  1300 950  1300
Connection ~ 1350 1300
$Comp
L power:+5V #PWR?
U 1 1 6315CF6B
P 1700 650
F 0 "#PWR?" H 1700 500 50  0001 C CNN
F 1 "+5V" H 1800 750 50  0000 C CNN
F 2 "" H 1700 650 50  0001 C CNN
F 3 "" H 1700 650 50  0001 C CNN
	1    1700 650 
	1    0    0    -1  
$EndComp
$Comp
L Device:C C?
U 1 1 6315D0B4
P 1700 1150
F 0 "C?" H 1750 1250 50  0000 L CNN
F 1 ".1u" H 1700 1050 50  0000 L CNN
F 2 "Capacitor_THT:C_Rect_L7.2mm_W2.5mm_P5.00mm_FKS2_FKP2_MKS2_MKP2" H 1738 1000 50  0001 C CNN
F 3 "~" H 1700 1150 50  0001 C CNN
	1    1700 1150
	1    0    0    -1  
$EndComp
Wire Wire Line
	1350 1000 1700 1000
Wire Wire Line
	1350 1300 1700 1300
$Comp
L 74xx:74LS132 U8
U 5 1 63199332
P 2150 1150
F 0 "U8" H 2150 1600 50  0000 L CNN
F 1 "74HC132" H 2150 1500 50  0000 L CNN
F 2 "Package_DIP:DIP-14_W7.62mm_Socket" H 2150 1150 50  0001 C CNN
F 3 "http://www.ti.com/lit/gpn/sn74LS132" H 2150 1150 50  0001 C CNN
	5    2150 1150
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
	1700 1000 1700 650 
Connection ~ 1700 1000
Wire Wire Line
	1700 1300 1700 1650
Connection ~ 1700 1300
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
Wire Wire Line
	3500 750  3500 650 
Wire Wire Line
	3500 1550 3500 1650
Connection ~ 2150 650 
Connection ~ 2150 1650
Connection ~ 3050 650 
Connection ~ 3050 1650
Wire Wire Line
	1700 650  2150 650 
Wire Wire Line
	1700 1650 2150 1650
Wire Wire Line
	3050 650  3500 650 
Wire Wire Line
	3050 1650 3500 1650
$Comp
L Connector:USB_B J?
U 1 1 61A5663E
P 950 900
F 0 "J?" H 600 950 50  0000 C CNN
F 1 "POWER IN" H 600 850 50  0000 C CNN
F 2 "Connector_USB:USB_B_OST_USB-B1HSxx_Horizontal" H 1100 850 50  0001 C CNN
F 3 " ~" H 1100 850 50  0001 C CNN
	1    950  900 
	1    0    0    -1  
$EndComp
Connection ~ 950  1300
Wire Wire Line
	950  1300 1350 1300
Connection ~ 1700 650 
Wire Wire Line
	1350 700  1250 700 
NoConn ~ 1250 900 
NoConn ~ 1250 1000
$Comp
L Device:Jumper_NC_Small JP?
U 1 1 626C59A2
P 1350 800
F 0 "JP?" V 1304 874 50  0000 L CNN
F 1 "PWR_SW" V 1450 800 50  0000 L CNN
F 2 "Connector_PinHeader_2.54mm:PinHeader_1x02_P2.54mm_Vertical" H 1350 800 50  0001 C CNN
F 3 "~" H 1350 800 50  0001 C CNN
	1    1350 800 
	0    1    1    0   
$EndComp
Wire Wire Line
	1350 900  1350 1000
Connection ~ 1350 1000
Text Label 1250 700  0    50   ~ 0
+5V_IN
$Comp
L Graphic:Logo_Open_Hardware_Large LOGO?
U 1 1 63275510
P 10700 6100
F 0 "LOGO?" H 10700 6600 50  0001 C CNN
F 1 " " H 10700 5700 50  0001 C CNN
F 2 "Symbol:OSHW-Logo2_14.6x12mm_SilkScreen" H 10700 6100 50  0001 C CNN
F 3 "~" H 10700 6100 50  0001 C CNN
	1    10700 6100
	1    0    0    -1  
$EndComp
$Comp
L Graphic:Logo_Open_Hardware_Small LOGO?
U 1 1 636EC7BA
P 10700 5400
F 0 "LOGO?" H 10700 5675 50  0001 C CNN
F 1 " " H 10700 5175 50  0001 C CNN
F 2 "durango:durango-x90" H 10700 5400 50  0001 C CNN
F 3 "~" H 10700 5400 50  0001 C CNN
	1    10700 5400
	1    0    0    -1  
$EndComp
$Comp
L Graphic:Logo_Open_Hardware_Small LOGO?
U 1 1 63C8FA92
P 10700 4950
F 0 "LOGO?" H 10700 5225 50  0001 C CNN
F 1 " " H 10700 4725 50  0001 C CNN
F 2 "durango:jaqueria" H 10700 4950 50  0001 C CNN
F 3 "~" H 10700 4950 50  0001 C CNN
	1    10700 4950
	1    0    0    -1  
$EndComp
Wire Wire Line
	2150 650  3050 650 
Wire Wire Line
	2150 1650 3050 1650
$EndSCHEMATC
