EESchema Schematic File Version 4
EELAYER 29 0
EELAYER END
$Descr A4 11693 8268
encoding utf-8
Sheet 1 1
Title "Clock tester"
Date "2023-03-28"
Rev ""
Comp "@zuiko21"
Comment1 ""
Comment2 ""
Comment3 ""
Comment4 ""
$EndDescr
$Comp
L 4xxx:4040 U?
U 1 1 6422F7C2
P 3550 3275
F 0 "U?" H 3550 4256 50  0000 C CNN
F 1 "4040" H 3550 4165 50  0000 C CNN
F 2 "" H 3550 3275 50  0001 C CNN
F 3 "http://www.intersil.com/content/dam/Intersil/documents/cd40/cd4020bms-24bms-40bms.pdf" H 3550 3275 50  0001 C CNN
	1    3550 3275
	1    0    0    -1  
$EndComp
$Comp
L 4xxx:4040 U?
U 1 1 6422FE31
P 5200 4075
F 0 "U?" H 5200 5056 50  0000 C CNN
F 1 "4040" H 5200 4965 50  0000 C CNN
F 2 "" H 5200 4075 50  0001 C CNN
F 3 "http://www.intersil.com/content/dam/Intersil/documents/cd40/cd4020bms-24bms-40bms.pdf" H 5200 4075 50  0001 C CNN
	1    5200 4075
	1    0    0    -1  
$EndComp
$Comp
L Device:LED D1
U 1 1 6423174A
P 4050 4825
F 0 "D1" V 4075 5000 50  0000 R CNN
F 1 "HSYNC" V 3975 5125 50  0000 R CNN
F 2 "" H 4050 4825 50  0001 C CNN
F 3 "~" H 4050 4825 50  0001 C CNN
	1    4050 4825
	0    -1   -1   0   
$EndComp
$Comp
L Device:LED D2
U 1 1 64232939
P 4375 4825
F 0 "D2" V 4414 4707 50  0000 R CNN
F 1 "VS/IRQ" V 4325 4775 50  0000 R CNN
F 2 "" H 4375 4825 50  0001 C CNN
F 3 "~" H 4375 4825 50  0001 C CNN
	1    4375 4825
	0    -1   -1   0   
$EndComp
$Comp
L Device:LED D3
U 1 1 64232C86
P 6150 4825
F 0 "D3" V 6189 4708 50  0000 R CNN
F 1 "MA" V 6098 4708 50  0000 R CNN
F 2 "" H 6150 4825 50  0001 C CNN
F 3 "~" H 6150 4825 50  0001 C CNN
	1    6150 4825
	0    -1   -1   0   
$EndComp
$Comp
L Device:LED D4
U 1 1 64232FCE
P 6475 4825
F 0 "D4" V 6514 4708 50  0000 R CNN
F 1 "PHI2" V 6423 4708 50  0000 R CNN
F 2 "" H 6475 4825 50  0001 C CNN
F 3 "~" H 6475 4825 50  0001 C CNN
	1    6475 4825
	0    -1   -1   0   
$EndComp
$Comp
L Device:R R2
U 1 1 64233AE3
P 4050 4525
F 0 "R2" H 3900 4525 50  0000 L CNN
F 1 "10K" V 4050 4450 50  0000 L CNN
F 2 "" V 3980 4525 50  0001 C CNN
F 3 "~" H 4050 4525 50  0001 C CNN
	1    4050 4525
	1    0    0    -1  
$EndComp
$Comp
L Device:R R3
U 1 1 64234940
P 4375 4525
F 0 "R3" H 4450 4525 50  0000 L CNN
F 1 "10K" V 4375 4450 50  0000 L CNN
F 2 "" V 4305 4525 50  0001 C CNN
F 3 "~" H 4375 4525 50  0001 C CNN
	1    4375 4525
	1    0    0    -1  
$EndComp
$Comp
L Device:R R4
U 1 1 64234CB8
P 6150 4525
F 0 "R4" H 6220 4571 50  0000 L CNN
F 1 "10K" V 6150 4450 50  0000 L CNN
F 2 "" V 6080 4525 50  0001 C CNN
F 3 "~" H 6150 4525 50  0001 C CNN
	1    6150 4525
	1    0    0    -1  
$EndComp
$Comp
L Device:R R5
U 1 1 64234E48
P 6475 4525
F 0 "R5" H 6545 4571 50  0000 L CNN
F 1 "10K" V 6475 4450 50  0000 L CNN
F 2 "" V 6405 4525 50  0001 C CNN
F 3 "~" H 6475 4525 50  0001 C CNN
	1    6475 4525
	1    0    0    -1  
$EndComp
Wire Wire Line
	4050 3575 4700 3575
Wire Wire Line
	4700 4975 5200 4975
Wire Wire Line
	4700 3875 4700 4175
Wire Wire Line
	3550 4175 4700 4175
Connection ~ 4700 4175
Wire Wire Line
	4700 4175 4700 4975
$Comp
L power:GND #PWR?
U 1 1 6423AD3E
P 4700 4975
F 0 "#PWR?" H 4700 4725 50  0001 C CNN
F 1 "GND" H 4705 4802 50  0000 C CNN
F 2 "" H 4700 4975 50  0001 C CNN
F 3 "" H 4700 4975 50  0001 C CNN
	1    4700 4975
	1    0    0    -1  
$EndComp
Connection ~ 4700 4975
$Comp
L power:PWR_FLAG #FLG?
U 1 1 6423B27B
P 3550 4175
F 0 "#FLG?" H 3550 4250 50  0001 C CNN
F 1 "PWR_FLAG" H 3550 4348 50  0000 C CNN
F 2 "" H 3550 4175 50  0001 C CNN
F 3 "~" H 3550 4175 50  0001 C CNN
	1    3550 4175
	-1   0    0    1   
$EndComp
Connection ~ 3550 4175
Wire Wire Line
	3550 2475 4250 2475
Wire Wire Line
	5200 2475 5200 3275
$Comp
L power:+5V #PWR?
U 1 1 6423B97E
P 4700 2475
F 0 "#PWR?" H 4700 2325 50  0001 C CNN
F 1 "+5V" H 4715 2648 50  0000 C CNN
F 2 "" H 4700 2475 50  0001 C CNN
F 3 "" H 4700 2475 50  0001 C CNN
	1    4700 2475
	1    0    0    -1  
$EndComp
Connection ~ 4700 2475
Wire Wire Line
	4700 2475 5200 2475
$Comp
L power:PWR_FLAG #FLG?
U 1 1 6423BB59
P 5200 2475
F 0 "#FLG?" H 5200 2550 50  0001 C CNN
F 1 "PWR_FLAG" H 5200 2648 50  0000 C CNN
F 2 "" H 5200 2475 50  0001 C CNN
F 3 "~" H 5200 2475 50  0001 C CNN
	1    5200 2475
	1    0    0    -1  
$EndComp
Connection ~ 5200 2475
Wire Wire Line
	3050 3075 3050 4175
Wire Wire Line
	3050 4175 3550 4175
$Comp
L Device:R R1
U 1 1 6423C1AC
P 3050 2925
F 0 "R1" H 2900 2925 50  0000 L CNN
F 1 "220K" V 3050 2825 50  0000 L CNN
F 2 "" V 2980 2925 50  0001 C CNN
F 3 "~" H 3050 2925 50  0001 C CNN
	1    3050 2925
	1    0    0    -1  
$EndComp
Connection ~ 3050 3075
$Comp
L Connector_Generic:Conn_01x01 J1
U 1 1 6423CFD9
P 3050 2575
F 0 "J1" V 3014 2487 50  0000 R CNN
F 1 "Probe" V 3150 2675 50  0000 R CNN
F 2 "" H 3050 2575 50  0001 C CNN
F 3 "~" H 3050 2575 50  0001 C CNN
	1    3050 2575
	0    -1   -1   0   
$EndComp
Connection ~ 3050 2775
$Comp
L Connector_Generic:Conn_01x01 J2
U 1 1 6423DE89
P 4250 2275
F 0 "J2" V 4214 2187 50  0000 R CNN
F 1 "Power" V 4350 2375 50  0000 R CNN
F 2 "" H 4250 2275 50  0001 C CNN
F 3 "~" H 4250 2275 50  0001 C CNN
	1    4250 2275
	0    -1   -1   0   
$EndComp
Connection ~ 4250 2475
Wire Wire Line
	4250 2475 4700 2475
$Comp
L Connector_Generic:Conn_01x01 J3
U 1 1 6423E8ED
P 5200 5175
F 0 "J3" V 5164 5087 50  0000 R CNN
F 1 "GND" V 5300 5275 50  0000 R CNN
F 2 "" H 5200 5175 50  0001 C CNN
F 3 "~" H 5200 5175 50  0001 C CNN
	1    5200 5175
	0    1    1    0   
$EndComp
Connection ~ 5200 4975
Text Label 4450 3575 0    50   ~ 0
DIV512
Text Label 5700 4675 0    50   ~ 0
DIV2M_PHI
Text Label 4050 3875 0    50   ~ 0
DIV4K_HS
Text Label 4050 3275 0    50   ~ 0
DIV64_VS_IRQ
NoConn ~ 4050 2775
NoConn ~ 4050 2875
NoConn ~ 4050 2975
NoConn ~ 4050 3075
NoConn ~ 4050 3175
NoConn ~ 4050 3375
NoConn ~ 4050 3475
NoConn ~ 4050 3675
NoConn ~ 4050 3775
NoConn ~ 5700 3575
NoConn ~ 5700 3675
NoConn ~ 5700 3775
NoConn ~ 5700 3875
NoConn ~ 5700 3975
NoConn ~ 5700 4575
NoConn ~ 5700 4475
NoConn ~ 5700 4375
NoConn ~ 5700 4275
NoConn ~ 5700 4075
Text Label 5700 4175 0    50   ~ 0
DIV64K_MA
Wire Wire Line
	4050 4975 4375 4975
Wire Wire Line
	4050 3875 4050 4375
Connection ~ 4375 4975
Wire Wire Line
	4375 4975 4700 4975
Wire Wire Line
	4375 4375 4375 3275
Wire Wire Line
	4375 3275 4050 3275
Wire Wire Line
	5200 4975 6150 4975
Wire Wire Line
	5700 4175 6150 4175
Wire Wire Line
	6150 4175 6150 4375
Wire Wire Line
	5700 4675 5925 4675
Wire Wire Line
	5925 4675 5925 4275
Wire Wire Line
	5925 4275 6475 4275
Wire Wire Line
	6475 4275 6475 4375
Wire Wire Line
	6150 4975 6475 4975
Connection ~ 6150 4975
$EndSCHEMATC