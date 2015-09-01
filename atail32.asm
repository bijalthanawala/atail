global main

segment .text

;
; Procedure:	main
;
; Parameters:	The standard 'C' main() parameters
;		Recall the prototype, 
;		int main(int argc, char *argv[], char *env[])
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
	
	; Get information about the filename
	call get_fnameinfo
	mov [fnameptr], eax
	mov [fnamelen], cx
	
	; Print the filename
	call print_fname

	; Gracefuly exit main()
	mov eax, 0
        ret	

;
; Procedure:	get_fnameinfo
;		Isolates filename pointer from the commandline arguments, 
;		returns that and the length of the filename
; Expects:	Variable argv to hold valid argv pointer
;
; Returns:	Pointer to the filename in EAX
;		Length of the filename in CX (Note: CX, not ECX)
;
get_fnameinfo:
	mov eax, [argv]
	mov eax, [ebx+4]
	call get_fname_len
	ret

;
; Procedure:	get_fname_len
;
; Parameter:    eax: Pointer to the filename
;
; Returns:	cx: Length of the filename (excluding NULL)
;
get_fname_len:
	push edi
	xor cx, cx
	mov edi, eax
loop_print_fname:
	cmp byte [edi], 0
	jz get_fname_len_end
	inc cx
	inc edi
	jmp loop_print_fname
get_fname_len_end:
	pop edi
	ret

;
; Procedure:	print_fname
;
print_fname:
	mov eax, 4
	mov ebx, 1
	mov ecx, [fnameptr]
	mov edx, [fnamelen] 
	int 80h
	ret



segment .data
	argc dd 0
	argv dd 0
	fnameptr dd 0
	fnamelen dw 0
