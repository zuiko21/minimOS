10 REM generador de versos para EhBASIC
20 REM (c) 2024 Carlos J. Santisteban
30 REM ** max.ind Categ,Palab,Tipos **
40 mc=9:mp=100:mt=100
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
300 REM [a0q] artículos masculinos
310 DATA el,un,*
400 REM [b1r] artículos femeninos
410 DATA la,una,*
500 REM [c2s] sustantivos masculinos
501 DATA diente,amo,sirviente,cura
502 DATA mendigo,presidente,niño
503 DATA hombre,mundo,cielo,día

598 DATA SOL,MAR,COCHE
599 DATA *
600 REM [d3t] sustantivos fememinos
601 DATA verdad,casa,familia,mosca,voz
602 DATA poesía,frase,línea,gente

698 DATA LUNA,TIERRA
699 DATA *
700 REM [e4u] adjetivos masculinos
701 DATA delgado,igual,mejor

798 DATA bueno,bonito,barato,grande
799 DATA *
800 REM [f5v] adjetivos femeninos
801 DATA delgada,igual,mejor


898 DATA linda,fea,grande
899 DATA *
1000 REM [g6] verbos intransitivos (pres. ind)
1001 DATA miente,desaparece,pregunta,llama
1002 DATA contesta,"SE MUEVE",evoluciona
1003 DATA mengua,crece,escribe,puede

1099 DATA *
1100 REM [h7] verbos transitivos ** impar
1101 DATA dice,pregunta,escribe,parece

1198 DATA COME,MIRA,DICE
1199 DATA *
1200 REM [i8] verbo estar (atributo es adjetivo)
1210 DATA soy,eres,es,era,eras,fui,fuiste,fue
1220 DATA seré,serás,será
1299 DATA *
1300 REM [j9] verbo ser (atributo es adj/sust)
1310 DATA estoy,estás,está,estaba,estabas
1320 DATA estuve,estuviste,estuvo
1330 DATA estaré,estarás,estará
1399 DATA *
1800 REM *** patrones *** objetos +16 (Q...)
1810 DATA G,GAC,GBD,HQS,HRT,

1995 DATA ACG,BDG,ACHQS,ACHRT,BDHQS,BDHRT
1996 DATA AC,BD,ACEG,BDFG,ACEHQS,ACEHRT
1997 DATA BDFHQS,BDHQSU
1998 DATA *
1999 x=25:REM contador líneas
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
2125 :IF x THEN DEC x: GOTO 2160
2127 :PRINT CHR$(14); 
2130 :FOR i=1 TO 5:PAUSE 250:NEXT
2140 :LIST:x=25
2150 :FOR i=1 TO 5:PAUSE 250:NEXT
2155 :PRINT CHR$(15);
2160 LOOP
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
9412 IF l$="á" OR l$="é" OR l$="í" THEN v=1
9415 IF l$="O" OR l$="U" THEN v=1
9417 IF l$="ó" OR l$="ú" THEN v=1
9420 RETURN 
9500 REM poner verbo t$ en plural
9510 REM copulativos, cualquier persona
9511 IF t$="SOY" THEN t$="SOMOS"
9512 IF t$="ERES" THEN t$="SOIS"
9513 IF t$="ES" THEN t$="SON"
9514 IF t$="ESTOY" THEN t$="ESTAMOS"
9515 IF t$="ESTáS" THEN t$="ESTÁIS"
9516 IF t$="ERA" AND RND(0)<0.5 THEN t$="ÉRAMOS"
9517 IF t$="ERAS" THEN t$="ÉRAIS"
9518 IF t$="FUI" THEN t$="FUIMOS"
9520 IF t$="FUE" THEN t$="FUERON"
9522 IF t$="ESTABA" AND RND(0)<0.5 THEN t$="ESTÁBAMOS"
9523 IF t$="ESTABAS" THEN t$="ESTÁBAIS"
9524 IF t$="ESTUVE" THEN t$="ESTUVIMOS"
9526 IF t$="ESTUVO" THEN t$="ESTUVIERON"

9800 REM casos generales
9801 IF RIGHT$(t$,LEN(t$)-3)="STE" THEN t$=t$+"IS"
9810 l$=RIGHT$(t$,1):REM última letra
9820 REM copulativos
9821 IF l$="á" THEN t$=t$+"N":REM muchos
9830 REM presente de indicativo
9831 IF l$="A" THEN t$=t$+"N":REM primera conj.
9832 IF l$="E" THEN t$=t$+"N":REM segunda y tercera
9840 REM futuro
9841 IF l$="é" AND c<10 THEN t$=LEFT(t$,LEN(t$)-1)+"EMOS"
9842 IF RIGHT$(t$,2)="áS" THEN t$=LEFT(t$,LEN(t$)-2)+"ÉIS"
9900 RETURN
