10 REM for Durango-X component video adapter
20 REM (c) 2024 Carlos J. Santisteban
25 MODE 2
30 DIM r(2,2)
40 REM R7, R8
41 REM R16, R17
50 DIM bt(2,2): REM BT601 coefficients
55 REM GREEN@Pr, BLUE@Pr
56 REM GREEN@Pb, RED@Pb
58 av = 1.4/1.4: REM Av=1 at base, Rc=Re, SCART Load=150
60 REM ** Load initial values **
70 FOR i=1 TO 2
80 :FOR j=1 TO 2
90 ::READ r(i,j):READ bt(i,j)
100 NEXT j, i
105 REM ** base resistors interleaved with BT601 coeff. **
110 DATA 2700, 0.418688, 12000, 0.081312
120 DATA 3300, 0.331264, 6800, 0.168736
130 REM ** bias resistors ** R1=R10, R2=R11
140 bh = 6800: bl = 3300
150 rb = (1/bh)+(1/bl): REM reciprocal of bias load
160 REM ** MAIN LOOP **
170 DO
180 :FOR c=1 TO 2: REM component
190 ::FOR s=1 TO 2: REM signal input
200 :::GOSUB 1000: REM compute rl minus r(c,s)
210 :::r(c,s) = rl*(1/(bt(c,s)*av)-1)
220 :::REM may round r(c,s) here
250 :NEXT s, c
260 :GOSUB 2000: REM display current values
270 LOOP
280 END
1000 REM ** compute rl minus r(c,s) **
1005 rl = rb
1010 FOR i = 1 TO 2
1030 :IF i<>s THEN rl = rl + 1/r(c,i)
1040 NEXT
1050 rl = 1/rl
1060 RETURN
2000 REM ** display values **
2005 LOCATE 0,0
2010 PRINT "R7  ="; r(1,1)
2020 PRINT "R8  ="; r(1,2)
2040 PRINT "R16 ="; r(2,1)
2050 PRINT "R17 ="; r(2,2)
2070 RETURN
