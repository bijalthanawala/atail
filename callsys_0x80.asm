global callsys_openfile
global callsys_closefile
global callsys_readfile
global callsys_writefile

segment .text

;
; Procedure: callsys_openfile
;
; Parameters: ebx: Pointer to the filename, ecx: flags
;
; Returns:    eax: File handle if successful, -1 otherwise
callsys_openfile:
	; syscall open: eax=0x05, ebx=ptr to filename, ecx=flags
	mov eax, 5
	int 80h
	ret	

;
; Procedure: callsys_closefile
;
; Parameters: ebx: file descriptor to close
;
; Returns:    eax: 0 if successful, -1 otherwise
callsys_closefile:
	; syscall open: eax=0x06, ebx=file descriptor
	mov eax, 6
	int 80h
	ret	

;
; Procedure:	callsys_readfile
;
callsys_readfile:
	; syscall write: eax=0x03, ebx=fd, ecx=ptr to buff, edx=length
	mov eax, 3
	int 80h
	ret

;
; Procedure:	callsys_writefile
;
callsys_writefile:
	; syscall write: eax=0x04, ebx=fd, ecx=ptr to buff, edx=length
	mov eax, 4
	int 80h
	ret

