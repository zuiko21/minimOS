10 REM generador de versos para EhBASIC
20 REM (c) 2024 Carlos J. Santisteban
30 REM ** max.ind Categ,Palab,Tipos **
40 mc=7:mp=100:mt=100
50 REM ** estructuras **
60 DIM w$(mc,mp)
65 DIM p$(mt):REM patrones
70 REM ** palabras por categoría **
80 DIM np(mc)
90 REM ** carga de palabras **
100 FOR nc=0 TO mc:REM categoría 
120 :i=0:REM palabra en curso
130 :DO
140 ::READ a$
150 ::IF a$<>"*" THEN w$(nc,i)=a$:INC i
160 :LOOP UNTIL a$="*"
170 :np(nc)=i
190 NEXT nc
200 REM ** carga de patrones **
210 pt=0:REM número de patrones
220 DO
230 :READ a$
240 :IF a$<>"*" THEN p$(pt)=a$:INC pt
250 LOOP UNTIL a$="*"
270 REM *** base de datos ***
280 REM * acaba una categoría
300 REM ** [a0q] artículos masculinos **
310 DATA EL,UN,*
400 REM ** [b1r] artículos femeninos **
410 DATA LA,UNA,*
500 REM ** [c2s] sustantivos masculinos **
510 DATA SOL,MAR,COCHE,*
600 REM ** [d3t] sustantivos fememinos **
610 DATA LUNA,TIERRA,CASA,*
700 REM ** [e4u] adjetivos masculinos **
710 DATA bueno,bonito,barato,grande,*
800 REM ** [f5v] adjetivos femeninos **
810 DATA linda,fea,grande,*
1000 REM ** [g6] verbos intransitivos **
1010 DATA HABLA,DUERME,CORRE,*
1100 REM ** [h7] verbos transitivos ** impar
1110 DATA COME,MIRA,DICE,*
1800 REM *** patrones *** objetos +16 (Q...)
1810 DATA ACG,BDG,ACHQS,ACHRT,BDHQS,BDHRT
1820 DATA AC,BD,ACEG,BDFG,ACEHQS,ACEHRT
1830 DATA BDFHQS,BDHQSU,*
1999 PRINT FRE(0):x=25:REM contador líneas
2000 DO
2010 :a$=p$(INT(RND(0)*pt)):REM escoje patrón
2020 :n1=INT(RND(0)*2):REM sujeto plural
2030 :FOR i=1 TO LEN(a$)
2040 ::c=(ASC(MID$(a$,i,1)) AND 239)-65:REM categoría actual
2045 ::o=ASC(MID$(a$,i,1)) AND 16:REM flag objeto
2049 REM si es transitiva, escoger número objeto
2050 :IF c>5 AND (c AND 1) THEN n2=INT(RND(0)*2)
2060 ::t$=w$(c,INT(RND(0)*np(c))):REM palabra
2070 ::IF (c>5) AND n1 THEN GOSUB 9500:REM plural verbo
2080 ::IF NOT o AND c<6 AND n1 THEN GOSUB 9000:REM plural sujeto
2090 ::IF o AND c<6 AND n2 THEN GOSUB 9000:REM plural objeto
2100 ::PRINT t$;" ";
2110 :NEXT i
2120 :PRINT CHR$(2);"."
2125 :IF x THEN DEC x: GOTO 2130
2126 :FOR i=1 TO 5:PAUSE 250:NEXT
2127 :LIST:x=25
2128 :FOR i=1 TO 5:PAUSE 250:NEXT
2130 LOOP
9000 REM poner sustantivo/artículo t$ en plural
9100 IF c<2 THEN GOTO 9200:REM artículos
9110 l$=RIGHT$(t$,1):REM última letra
9120 IF l$="Z" THEN t$=LEFT$(t$,LEN(t$)-1)+"C"
9130 GOSUB 9400:REM es vocal?
9140 IF v THEN t$=t$+"S" ELSE t$=t$+"ES"
9150 RETURN
9200 REM caso particular artículos
9210 IF t$="EL" THEN t$="LOS":RETURN
9220 IF t$="UN" THEN t$="UNOS":RETURN
9300 GOTO 9110: REM caso general
9400 REM v indica si l$ es vocal
9405 v=0
9410 IF l$="A" OR l$="E" OR l$="I" THEN v=1
9415 IF l$="O" OR l$="U" THEN v=1
9420 RETURN 
9500 REM poner verbo t$ en plural
9510 l$=RIGHT$(t$,1):REM última letra
9519 REM presente de indicativo
9520 IF l$="A" THEN t$=t$+"N":REM primera
9530 IF l$="E" THEN t$=t$+"N":REM segunda y tercera
9600 RETURN
