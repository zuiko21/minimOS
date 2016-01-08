	LDA int_q_n		; number of interrupt tasks
	DEC				; 0...n-1, or suppress?
	ASL				; 2-byte addresses
	TAX				; this is an index, but use TAY in case of dynamically located queue!
queue_loop:
	PHX				; don't lose loop counter! could be Y, see above
	JSR q_call		; it's an indirect jump, will return just after here
	PLX				; retrieve counter
; D_REQ calls should check here whether the interrupt was serviced, BCC will abort loop appropiately
	DEX				; next driver
	DEX
	BPL queue_loop	; ...but only up to 64 tasks! Could just use BNE if no DEC above
; continue with ISR tasks...

q_call:				; simulate indirect call
	JMP (queue, X)	; in case queue address is known in assembly time
;	LDA (queue), Y	; indirect post-indexed address, assume it's pointing to MSB
;	PHA				; put MSB
;	DEY				; down to LSB
;	LDA (queue), Y
;	PHA				; put LSB
;	PHP				; much better this way, no need to correct RTS-expected address!
;	RTI				; go there!
