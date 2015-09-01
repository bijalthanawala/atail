global main

segment .text

;
; Procedure:	main
;
main:
	; Set variables: argc, argv
	mov ebp, esp	
	add ebp, 4		; Skip return address
	mov ebx, [ebp]  	; Fetch argc
	mov [argc], ebx
	add ebp, 4
	mov ebx, [ebp]		; Fetch argv
	mov [argv], ebx
	
	; Isolate filename from the arguments
	call get_fnameptr
	mov [fnameptr], eax
	
	; Print the filename
	call print_fname
        ret	

;
; Procedure:	get_fnameptr
;		Isolates filename from the commandline 
;		arguments
; Returns:	Ptr to filename in EAX
get_fnameptr:
	mov eax, [argv]
	mov eax, [eax+4]
	ret

;
; Procedure:	print_fname
;
print_fname:
	mov edi, [fnameptr]
	mov ecx, edi 
loop_print_fname:
	cmp byte [ecx], 0
	jz print_fname_end
	mov eax, 4
	mov ebx, 1
	mov edx, 1
	int 80h
	inc ecx
	jmp loop_print_fname
print_fname_end:
	ret



segment .data
	argc dd 0
	argv dd 0
	fnameptr dd 0
