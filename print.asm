%include "callsys.inc"

global print_msg
global print_newline

segment .text

;
; Procedure:	print_msg
;
print_msg:
	call callsys_writefile
	ret

;
; Procedure:	printn_msg
;
printn_msg:
	call print_msg
        call print_newline
	ret


;
; Procedure:	print_newline
;
print_newline:
	mov ecx, crlf 
	mov edx, 2
	call print_msg
	ret

segment .data
	crlf	db  0x0d, 0x0a
