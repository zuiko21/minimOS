10 REM Cylindrical vignetting computation
20 REM (c) 2024 Carlos J. Santisteban
30 REM Runs on EhBASIC for Durango-X
100 CURSOR 0:PAPER 0:MODE 0
110 DIM mt(31)
120 FOR i=0 TO 31
122 :mt(i)=0
125 :REM draw separating circles
130 :CIRCLE 64,64-i,32,15
140 :CIRCLE 64,64+i,32,15
145 :REM compute relative area
150 :pt=$6FC0:REM screen center
152 :DO
155 ::DO
160 :::IF PEEK(pt) THEN 200
165 :::POKE pt,$11
170 :::INC mt(i)
180 :::INC pt
190 ::LOOP
195 ::b=PEEK(pt)
200 ::IF b<16 THEN mt(i)=mt(i)+.5:POKE pt,$EF
210 ::pt=(pt AND $FFDF)-64
220 :LOOP WHILE b>15
225 :CLS
230 NEXT i
240 REM display axis
250 LINE 32,96,96,96,15:REM white axis
260 LINE 32,96,32,32,13:REM cyan
270 LINE 96,32,96,96,2:REM red
275 FOR i=32 TO 96 STEP 16:PLOT 97,i,2:NEXT
280 REM display graph
285 k=LOG(2)/16
290 FOR i=0 TO 31
300 :m=mt(i)/mt(0)
310 :y=(1-m)*64+32
320 :s=32-LOG(m)/k
330 :PLOT i,y,13:REM linear
340 :IF s<96 THEN PLOT i,s,2:REM stops
350 NEXT i
