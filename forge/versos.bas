10 REM generador de versos para EhBASIC
20 REM (c) 2024 Carlos J. Santisteban
30 REM ** valores límite **
40 categ=5:palabras=10
50 REM ** estructuras **
60 DIM w$(categ-1,palabras-1)
70 REM ** palabras por categoría **
80 DIM np(categ-1)
90 REM ** carga de datos **
100 nc=0:REM categoría 
110 DO
120 :DO
130 ::i=0:REM palabra en curso
140 ::READ a$
150 ::IF a$<>"*" AND a$<>"#" THEN w$(nc,i)=a$:INC i
160 :LOOP UNTIL a$="*" OR a$="#"
170 :np(nc)=i-1:REM no cuento el delimitador
180 :INC nc
190 LOOP UNTIL ca="#":DEC nc
200 REM *** base de datos ***
210 REM * acaba una categoría
220 REM # acaba la última categoría
300 REM ** [0] artículos masculinos **
310 DATA EL, UN, *
400 REM ** [1] artículos femeninos **
410 DATA LA, UNA, *
500 REM ** [2] sustantivos masculinos **
510 DATA SOL, MAR, COCHE, *
600 REM ** [3] sustantivos fememinos **
610 DATA LUNA, TIERRA, CASA, *
700 REM ** [4] verbos transitivos **
710 DATA COME, MIRA, DICE, *
800 REM ** [5] verbos intransitivos **
810 DATA HABLA, DUERME, CORRE, #
1000 DO
1005 :gen=INT(RND(0)*2):REM masc/fem
1007 :tra=INT(RND(0)*2):REM trans/intrans
1010 :FOR i=0 TO nc
1012 ::IF gen=0 AND (i=1 OR i=3) THEN NEXT i
1014 ::IF gen=1 AND (i=0 OR i=2) THEN NEXT i
1016 ::IF tra=0 AND i=5 THEN NEXT i
1018 ::IF tra=1 AND i=4 THEN NEXT i
1020 ::PRINT w$(i,INT(RND(0)*np(i)));" ";
1030 :NEXT i
1032 :IF tra=0 THEN gen=INT(RND(0)*2):PRINT w$(2+gen,INT(RND(0)*np(2+gen)));
1035 PRINT
1040 LOOP
