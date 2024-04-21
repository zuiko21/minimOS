10 REM generador de versos para EhBASIC
20 REM (c) 2024 Carlos J. Santisteban
30 REM ** max.ind Categ,Palab,Tipos **
40 mc=13:mp=100:mt=100
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
310 DATA el,un,mi,tu,su,nuestro,vuestro,aquel,*

400 REM [b1r] artículos femeninos
410 DATA la,una,mi,tu,su,nuestra,vuestra,aquellas,*

500 REM [c2s] sustantivos masculinos
501 DATA diente,amo,sirviente,cura,Dios,"ÁNGEL"
502 DATA mendigo,presidente,"NIÑO",miedo
503 DATA hombre,mundo,cielo,"DÍA",alma,vestido
504 DATA espejo,pasillo,preso,parado,mago
505 DATA enamorado,"ÁRBOL",pecho,piano,beso
506 DATA "CIEMPIÉS","CORAZÓN",soldado,ojo,"AÑO"
507 DATA bolsillo,"CHAQUETÓN",guardia,reptil
508 DATA poder,pueblo,regalo,rey,jilguero
509 DATA villancico,verso

599 DATA *
600 REM [d3t] sustantivos fememinos
601 DATA verdad,casa,familia,mosca,voz,esperanza
602 DATA "POESÍA",frase,"LÍNEA",gente,obra,cosa
603 DATA enamorada,fruta,yedra,mano,flor,fe,ternura
604 DATA tapia,cereza,mentira,tumba,guerra,"UÑA"
605 DATA garra,fuerza,cultura,"ALEGRÍA","CANCIÓN"
606 DATA cascada,hermosura,sonrisa

699 DATA *
700 REM [e4u] adjetivos masculinos
701 DATA delgado,igual,mejor,brillante,culpable
702 DATA injusto,grande

799 DATA *
800 REM [f5v] adjetivos femeninos
801 DATA delgada,igual,mejor,brillante,culpable
802 DATA injusta,grande

899 DATA *
900 REM [g6] estativos masculinos
901 DATA herido,desaparecido,preso,parado,reunido
902 DATA desnudo

949 DATA *
950 REM [h7] estativos femeninos
951 DATA herida,desaparecida,presa,parada,reunida
952 DATA desnuda

999 DATA *
1000 REM [i8] verbos intransitivos (pres. ind)
1001 DATA miente,desaparece,pregunta,llama
1002 DATA contesta,"SE MUEVE",evoluciona
1003 DATA mengua,crece,escribe,puede,vuelve
1003 DATA cabalga,brota,cae,"SE PONE",escupe
1004 DATA aprende,sufre

1099 DATA *
1100 REM [j9] verbos transitivos ** impar
1101 DATA dice,pregunta,escribe,coge,atrapa,tiene
1102 DATA ama

1199 DATA *
1200 REM [k10] verbo ser/parecer (1ª y 2ª persona sin sujeto)
1210 DATA soy,eres,era,eras,fui,fuiste
1215 DATA parezco,pareces,"PARECÍA","PARECÍAS"
1220 DATA "SERÉ","SERÁS","PARECERÉ","PARECERÁS"
1299 DATA *
1300 REM [l11] verbo estar (1ª y 2ª persona, estativos)
1310 DATA estoy,"ESTÁS",estaba,estabas
1320 DATA estuve,estuviste,"ESTARÉ","ESTARÁS"
1399 DATA *
1400 REM [m12] verbo ser/parecer (3ª persona con sujeto)
1410 DATA es,era,fue,"SERÁ",parece,"PARECÍA","PARECERÁ"
1499 DATA *
1500 REM [n13] verbo estar (3ª persona, estativos)
1510 DATA "ESTÁ",estaba,estuvo,"ESTARÁ"
1599 DATA *
1800 REM *** patrones *** objetos +16 (Q...)
1810 DATA I,IAC,IBD,JQS,JRT,AC,BD,ACE,BDF
1820 DATA ACNG,BDNH,LG,LH,KE,KF

1995 DATA ACI,BDI,ACJQS,ACJRT,BDJQS,BDJRT
1996 DATA AC,BD,ACEI,BDFI,ACEJQS,ACEJRT
1997 DATA BDFJQS,BDJQSU
1998 DATA *
1999 x=9925:PRINT FRE(0):REM contador líneas
2000 DO
2010 :a$=p$(INT(RND(0)*pt)):REM escoje patrón
2020 :n1=INT(RND(0)*2):REM sujeto plural
2030 :FOR i=1 TO LEN(a$)
2040 ::c=(ASC(MID$(a$,i,1)) AND 239)-65:REM categoría actual
2045 ::o=ASC(MID$(a$,i,1)) AND 16:REM flag objeto
2049 REM si es transitiva, escoger número objeto
2050 ::IF c>7 AND (c AND 1) THEN n2=INT(RND(0)*2) ELSE n2=0
2060 ::t$=w$(c,INT(RND(0)*np(c))):REM palabra
2070 ::IF (c>7) AND n1 THEN GOSUB 9500:REM plural verbo
2080 ::IF NOT o AND c<8 AND n1 THEN GOSUB 9000:REM plural sujeto
2090 ::IF o AND c<8 AND n2 THEN GOSUB 9000:REM plural objeto
2100 ::PRINT t$;" ";
2110 :NEXT i
2120 :PRINT CHR$(2);"."
2125 :IF x THEN DEC x: GOTO 2160
2127 :PRINT CHR$(14); 
2130 :d=5:GOSUB 3000
2132 :LIST -210:GOSUB 3000
2134 :LIST 220-699:GOSUB 3000
2136 :LIST 700-1199:GOSUB 3000
2138 :LIST 1200-1999:GOSUB 3000
2140 :LIST 2000-2130:GOSUB 3000
2142 :LIST 2132-9150:GOSUB 3000
2144 :LIST 9200-9526:GOSUB 3000
2146 :LIST 9800-9900:GOSUB 3000
2150 :x=25
2155 :PRINT CHR$(15);
2160 LOOP
3000 REM ** retardo 'd' segundos **
3010 FOR i=1 TO d:PAUSE 250:NEXT
3020 RETURN
9000 REM ** poner sustantivo/artículo t$ en plural **
9100 IF c<2 THEN GOTO 9200:REM artículos
9105 z=LEN(t$)-1:REM muy usada
9110 l$=RIGHT$(t$,1):REM última letra
9120 IF l$="Z" THEN t$=LEFT$(t$,z)+"C"
9125 IF RIGHT$(t$,2)="ÓN" THEN t$=LEFT$(t$,z-1)+"ONES":RETURN
9130 GOSUB 9400:REM es vocal?
9140 IF v THEN t$=t$+"S" ELSE t$=t$+"ES"
9150 RETURN
9200 REM caso particular artículos
9210 IF t$="EL" THEN t$="LOS":RETURN
9220 IF t$="UN" THEN t$="UNOS":RETURN
9230 IF t$="AQUEL" THEN t$="AQUELLOS"
9300 GOTO 9105: REM caso general
9400 REM ** v indica si l$ es vocal **
9405 v=0
9410 IF l$="A" OR l$="E" OR l$="I" THEN v=1
9412 IF l$="Á" OR l$="É" OR l$="Í" THEN v=1
9415 IF l$="O" OR l$="U" THEN v=1
9417 IF l$="Ó" OR l$="Ú" THEN v=1
9420 RETURN 
9500 REM ** poner verbo t$ en plural **
9505 o$=t$:REM original
9510 REM copulativos, cualquier persona
9511 IF t$="SOY" THEN t$="SOMOS"
9512 IF t$="ERES" THEN t$="SOIS"
9513 IF t$="ES" THEN t$="SON"
9514 IF t$="ESTOY" THEN t$="ESTAMOS"
9515 IF t$="ESTÁS" THEN t$="ESTÁIS"
9516 IF t$="ERA" AND c=10 THEN t$="ÉRAMOS"
9517 IF t$="ERAS" THEN t$="ÉRAIS"
9520 IF t$="FUE" THEN t$="FUERON"
9522 IF t$="ESTABA" AND c=11 THEN t$="ESTÁBAMOS"
9523 IF t$="ESTABAS" THEN t$="ESTÁBAIS"
9524 IF t$="ESTUVE" THEN t$="ESTUVIMOS"
9526 IF t$="ESTUVO" THEN t$="ESTUVIERON"
9527 IF t$="PAREZCO" THEN t$="PARECEMOS"
9799 IF t$<>o$ THEN RETURN:REM ya en plural
9800 REM casos generales
9805 z=LEN(t$)-1:REM muy usado
9810 l$=RIGHT$(t$,1):REM última letra
9811 l2$=RIGHT$(t$,2):REM dos últimas
9812 l3$=RIGHT$(t$,3):REM tres últimas
9815 IF l3$="STE" THEN t$=t$+"IS":RETURN
9816 IF l2$="ÍA" THEN t$=t$+"IS":RETURN
9820 REM copulativos y presente
9821 IF l$="Á" OR l$="A" OR l$="E" THEN t$=t$+"N":REM muchos
9822 IF l2$="ES" THEN t$=LEFT$(t$,z-1)+"ÉIS"
9830 REM futuro
9831 IF l$="É" THEN t$=LEFT$(t$,z)+"EMOS"
9832 IF l2$="ÁS" THEN t$=LEFT$(t$,z-1)+"ÉIS"
9840 REM pretérito
9842 IF l$="I" OR l$="Í" THEN t$=LEFT$(t$,z)+"IMOS"
9900 RETURN
