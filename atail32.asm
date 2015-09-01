%include "fcntl.inc"
%include "print.inc"
%include "callsys.inc"

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
	mov [fnamelen], ecx
	
	; Open the file (readonly)
	mov	ebx, [fnameptr]
	mov	ecx, O_RDONLY
	call 	callsys_openfile
	cmp	eax, 0
	jl	err_file_open
	
	mov	[fd], eax


	; Close the file
        mov	ebx, [fd]
	call    callsys_closefile 	

	jmp 	main_end

err_file_open:
	mov	ecx, err_msg_file_open
	mov	edx, err_msg_len_file_open
	call 	print_msg
	call 	printn_fname

	
main_end:
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
;		Length of the filename in ECX
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
; Returns:	ecx: Length of the filename (excluding NULL)
;
get_fname_len:
	push edi
	xor ecx, ecx
	mov edi, eax
loop_fname_char:
	cmp byte [edi], 0
	jz get_fname_len_end
	inc ecx
	inc edi
	jmp loop_fname_char
get_fname_len_end:
	pop edi
	ret

;
; Procedure:	print_fname
;
print_fname:
	; syscall write: eax=0x04, ebx=fd, ecx=ptr to buff, edx=length
	mov ecx, [fnameptr]
	mov edx, [fnamelen] 
	call print_msg
	ret

;
; Procedure:	printn_fname
;
printn_fname:
	call print_fname
	call print_newline
	ret

segment .data
	argc dd 0
	argv dd 0
	fnameptr dd 0
	fnamelen dd 0
	fd	 dd 0
	err_msg_file_open db "Error opening file : "
	err_msg_len_file_open equ ($ - err_msg_file_open)
