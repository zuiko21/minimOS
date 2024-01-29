10 REM for Durango-X component video output
20 REM (c) 2024 Carlos J. Santisteban
30 DIM r(2,3)
40 REM R644, 645, 646
50 REM R654, 655, 656
60 REM ** Load initial values **
70 FOR i=1 TO 2
80 :FOR j=1 TO 3
90 ::READ r(i,j)
100 NEXT j, i
110 DATA 12000, 22000, 56000
120 DATA 15000, 27000, 33000
130 REM ** bias resistors ** R638=R648, R639=R649
140 bh = 6800: bl = 3300
150 rb = (1/bh)+(1/bl): REM reciprocal of bias load
160 REM ** MAIN LOOP **
170 DO
180 FOR c=1 TO 2: REM component
190 :FOR s=1 TO 3: REM signal input
200 ::GOSUB 1000: REM compute rl minus r(c,s)
205 ::REM GOSUB 2000: REM round rl
210 ::r(c,s) = rl:REM *****NO*****
220 ::GOSUB 2000: REM display current values
220 :NEXT s, c
230 LOOP
240 END
1000 REM ** compute rl minus r(c,s) **
1005 rl = 0
1010 FOR i = 1 TO 3
1030 :IF i<>c
