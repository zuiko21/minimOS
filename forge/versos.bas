10 REM generador de versos para EhBASIC
20 REM (c) 2024 Carlos J. Santisteban
30 REM ** valores límite **
40 categ=6:palabras=10:tipos=3
50 REM ** estructuras **
60 DIM w$(categ-1,palabras-1)
65 DIM p$(tipos-1):REM patrones
70 REM ** palabras por categoría **
80 DIM np(categ-1)
90 REM ** carga de palabras **
100 nc=0:REM categoría 
110 DO
120 :i=0:REM palabra en curso
130 :DO
140 ::READ a$
150 ::IF a$<>"*" AND a$<>"#" THEN w$(nc,i)=a$:INC i
160 :LOOP UNTIL a$="*" OR a$="#"
170 :np(nc)=i
180 :INC nc
190 LOOP UNTIL a$="#":DEC nc
200 REM ** carga de patrones **
210 pt=0:REM número de patrones
220 DO
230 :READ a$
240 :IF a$<>"*" THEN p$(pt)=a$:INC pt
250 LOOP UNTIL a$="*"
270 REM *** base de datos ***
280 REM * acaba una categoría
290 REM # acaba la última categoría
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
1000 REM *** patrones ***
1010 DATA abc, *
1900 PRINT FRE(0)
2000 DO
2005 :gen=INT(RND(0)*2):REM masc/fem
2007 :tra=INT(RND(0)*2):REM trans/intrans
2010 :FOR i=0 TO nc
2012 ::IF gen=0 AND (i=1 OR i=3) THEN 2030
2014 ::IF gen=1 AND (i=0 OR i=2) THEN 2030
2016 ::IF tra=0 AND i=5 THEN 2030
2018 ::IF tra=1 AND i=4 THEN 2030
2020 ::PRINT w$(i,INT(RND(0)*np(i)));" ";
2030 :NEXT i
2032 IF tr=0 THEN ge=INT(RND(0)*2):?w$(2+ge,INT(RND(0)*np(2+ge)));
2035 PRINT
2040 LOOP
