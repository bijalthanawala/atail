%include "fcntl.inc"
%include "print.inc"
%include "callsys.inc"

extern malloc
extern free

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
	
	; Save file descriptor
	mov	[fd], eax
	
	; Allocate memory to store pointers to lines
	mov	ebx, [nr_lines]
	shl	ebx, 2		; Multiply by 4 (Pointer size = 32 bits)
	push 	ebx
	call	malloc
	add	esp, 4

	; Handle malloc failure
	cmp	eax, 0
	jz	err_malloc_fail

read_rawbuff:
	mov	ebx, [fd]
	mov	ecx, rawbuff
	mov     edx, rawbuffsize
	call    callsys_readfile	
	cmp     eax, 0
	jz 	err_free_finish
	cmp	eax, -1
	jz	err_free_finish

	mov	ecx, rawbuff
	mov     edx, eax
	call	print_msg
	
	jmp	read_rawbuff


err_free_finish:
	; Free all resources and exit gracefully
	call	free_linequeue
	call 	close_file
	jmp 	main_end


err_malloc_fail:
	mov	ecx, err_msg_malloc_fail
	mov	edx, err_msg_len_malloc_fail
	call	printn_msg
	call	close_file
	jmp 	main_end

err_file_open:
	mov	ecx, err_msg_file_open
	mov	edx, err_msg_len_file_open
	call 	print_msg
	call 	printn_fname
	jmp 	main_end

	
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
; Procedure: close_file
;
close_file:
        mov	ebx, [fd]
	call    callsys_closefile 	
	ret	

;
; Procedure: free_linequeue
;
free_linequeue:
	push 	dword [linequeue]
	call 	free
	add 	esp, 4
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
	argc 		dd 0
	argv 		dd 0
	fnameptr 	dd 0
	fnamelen 	dd 0
	fd	 	dd 0
	linequeue 	dd 0	; Ptr to ptr to lines
	queue_head	dd 0
	nr_lines	dd 10	; Read last n lines (default = 10)
	rawbuff         times 100 db 0
	rawbuffsize	equ ($ - rawbuff)

	; Error messages
	err_msg_file_open 	db "Error opening file : "
	err_msg_len_file_open 	equ ($ - err_msg_file_open)
	err_msg_malloc_fail 	db "Error Allocating Memory"
	err_msg_len_malloc_fail equ ($ - err_msg_malloc_fail)
