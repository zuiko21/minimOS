; SS-22 auto-configuration protocol
; (c)2020 Carlos J. Santisteban

/*
Init:
	Set 15625 bps
	Send $55, receive (CA2=entry1)
Entry 1:
	Got $55? Send $22, receive (CA2=entry2)
	Got $22?	if not shifted, DISABLE!
			else Send S, receive (CA2=entry3)
	Got anything else? DISABLE!
Entry 2:
	Get X=other end's speed
	Send S=my speed, go to link
Entry 3:
	If not shifted, DISABLE!
	else Get X
Link:
	Set bps via T2 value:
		if x>s, T2=0
		else if x=s, T2=1
		else T2=myTab[x]
	Set CA2 to standard buffer reception
*/
