10 REM generador de versos para EhBASIC
20 REM (c) 2024 Carlos J. Santisteban
30 REM ** max.ind Categ,Palab,Tipos **
40 mc=5:mp=10:mt=10
50 REM ** estructuras **
60 DIM w$(mc,mp)
65 DIM p$(mt):REM patrones
70 REM ** palabras por categoría **
80 DIM np(mc)
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
300 REM ** [a0] artículos masculinos **
310 DATA EL,UN,*
400 REM ** [b1] artículos femeninos **
410 DATA LA,UNA,*
500 REM ** [c2] sustantivos masculinos **
510 DATA SOL,MAR,COCHE,*
600 REM ** [d3] sustantivos fememinos **
610 DATA LUNA,TIERRA,CASA,*
700 REM ** [e4] verbos transitivos **
710 DATA COME,MIRA,DICE,*
800 REM ** [f5] verbos intransitivos **
810 DATA HABLA,DUERME,CORRE,#
1000 REM *** patrones *** objetos en mayúscula
1010 DATA acf,bdf,aceAC,aceBD,bdeAC,bdeBD,*
1900 PRINT FRE(0)
2000 DO
2010 :ap$=p$(INT(RND(0)*mt):REM escoje patrón
2020 :n1=INT(RND(0)*2):REM sujeto sing.0/plu.1
2030 :FOR i=0 TO LEN(ap$)-1
2040 ::c=(ASC(MID$(ap$,i,1)) OR 32) -97:REM categoría actual
2045 ::o=NOT(ASC(MID$(ap$,i,1)) AND 223):REM flag objeto
2049 REM si es transitiva, escoger número objeto
2050 :IF c=4 THEN n2=INT(RND(0)*2)
2060 ::t$=w$(c,INT(RND(0)*np(c))):REM palabra
2070 ::IF (c=4 OR c=5) AND n1 THEN GOSUB 9500:REM plural verbo
2080 ::IF i<2 AND c<4 AND n1 THEN GOSUB 9000:REM plural sujeto
2090 ::IF o AND n2 THEN GOSUB 9000:REM plural objeto
2100 ::PRINT t$;" ";
2110 :NEXT i
2120 :PRINT CHR$(2);"."
2130 LOOP
9000 REM poner sustantivo/artículo en plural
9100 IF c<2 THEN GOTO 9200:REM artículos
9110 ll$=RIGHT$(t$,1);REM última letra
9120 IF ll$="Z" THEN RIGHT$(t$,1)="C"
9130 GOSUB 9400:REM es vocal?
9140 IF vo THEN t$=t$+"S" ELSE t$=t$+"ES"
9150 RETURN
9200 REM caso particular artículos
9210 IF t$="EL" THEN t$="LOS":RETURN
9300 GOTO 9120: REM caso general
9400 REM vo indica si es vocal
9405 vo=0
9410 IF ll$="A" OR ll$="E" OR ll$="I" THEN vo=1
9415 IF ll$="O" OR ll$="U" THEN vo=1
9420 RETURN 
9500 REM poner verbo en plural
9510 ll$=RIGHT$(t$,1):REM última letra
9519 REM presente de indicativo
9520 IF ll$="A" THEN t$=t$+"N":REM primera
9530 IF ll$="E" THEN t$=t$+"N":REM segunda y tercera
9600 RETURN
