%include "fcntl.inc"
%include "print.inc"
%include "callsys.inc"

EINTR	equ 4

extern malloc
extern calloc
extern realloc
extern free
;extern errno

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
	push	4			; (Pointer size = 32 bits)
	push    dword [nr_lines] 	; 
	call	calloc			; Allocates (4 * nr_lines) bytes &
	add	esp, 8			; initializes it to zeroes

	; Handle malloc failure
	cmp	eax, 0
	jz	err_alloc_queue

	; Save the ptr to allocated mem
	mov 	[linequeue], eax

	; Allocate memory for the flexibuff
	push	dword [flexibuffsize]
	call	malloc
	add	esp,4

	; Handle malloc failure
	cmp	eax, 0
	jz	err_alloc_flexibuff

	; Save the ptr
	mov	[flexibuff], eax

read_char:
	mov	ebx, [fd]
	mov	ecx, singlech
	mov     edx, 1
	call    callsys_readfile	
	cmp     eax, 0
	jz 	file_read_fin
	;cmp	eax, -1
	;jnz	err_reading
	;cmp 	word [errno], EINTR 
	;jz	read_char

process_char:
	mov	al, [singlech]
	cmp	al, 0x0a
	jz	process_lf
	mov     ebx, [flexibuffndx]
	mov	edi, [flexibuff]
	mov	[edi+ebx], al
	inc	ebx
	mov	[flexibuffndx], ebx
	cmp	ebx, [flexibuffsize]	
	jl	read_char

dbg_realloc_flexibuff:
	; ran out of buff, need to realloc
	shl	dword [flexibuffsize], 1 ; Double the buffer size	
	push    dword [flexibuffsize]
	push    dword [flexibuff]
	call	realloc         ; Request for doubled memory 
	add	esp, 8
	or	eax, eax
	jz      err_realloc_flexibuff
	mov	[flexibuff], eax
	jmp	read_char	
	
process_lf:
	mov	ebx, [queuehead]
	shl	ebx, 2
	mov	edi, [linequeue]
	add	edi, ebx
	push	edi		;Save queue ptr
	mov	eax, [edi]
	or	eax, eax
	jz	alloc_for_newline
dbg_free_old_line:
	push	eax 	
	call	free
	add	esp, 4
	
alloc_for_newline:
	mov	eax, [flexibuffndx]
	add	eax, 4		; +4 to store string len in the first byte
	push	eax
	call	malloc
	add	esp, 4
	pop	edi		;Restore queue ptr
	or	eax, eax
	jz	err_alloc_line
	mov	[edi], eax

	; Copy the line
	mov	ecx, [flexibuffndx]
	mov	edi, eax
	mov	[edi], ecx
	add	edi, 4
	mov     esi, [flexibuff]
	cld
	rep	movsb
	
	mov	dword [flexibuffndx], 0

	inc	word [queuehead]
	mov	edx, [queuehead]
dbg_check_need_to_reset_queue_head:
	cmp	edx, [nr_lines]
	jl	read_char

dbg_reset_queue_head:
	mov	word [queuehead], 0
	jmp	read_char	

file_read_fin:
	call	print_queue	
	jmp 	free_resources_finish

err_reading:
	mov	ecx, err_msg_read
	mov	edx, err_msg_len_read
	call 	print_msg
	call 	printn_fname
	jmp	free_resources_finish

err_alloc_line:
err_realloc_flexibuff:
	call	print_alloc_fail_msg
	jmp	free_resources_finish

free_resources_finish:
	; Free all resources and exit gracefully
	call	free_flexibuff
	call	free_linequeue
	call 	close_file
	jmp 	main_end

err_alloc_queue:
	call	print_alloc_fail_msg
	call	close_file
	jmp 	main_end

err_alloc_flexibuff:
	call	print_alloc_fail_msg
	call	free_linequeue
	call 	close_file
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
; Procedure: print_queue
;
print_queue:
	mov	esi, [linequeue]	
	mov	eax, [queuehead]
	mov	ebx, eax
	shl	ebx, 2
	mov	edi, [esi + ebx]
	or	edi, edi
	jz	print_start_to_head
	
	mov	ecx, [nr_lines]
	sub	ecx, eax	
	call	print_part_queue

print_start_to_head:
	mov	ebx, 0	
	mov	edi, [esi + ebx]
	mov	ecx, [queuehead] 
	call	print_part_queue
	ret

;
; Procedure: print_part_queue
;
print_part_queue:
loop_part_queue:	
	push 	ecx
	push	ebx
	lea	ecx, [edi + 4]
	mov	edx, [edi]
	call 	printn_msg
	pop	ebx
	pop	ecx
	add	ebx, 4
	mov	edi, [esi + ebx]
	dec	ecx
	jnz	loop_part_queue
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
; Procedure: free_flexibuff
;
free_flexibuff:
	push 	dword [flexibuff]
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

;
; Procedure:	print_alloc_fail_msg
;
print_alloc_fail_msg:
	mov	ecx, err_msg_alloc_fail
	mov	edx, err_msg_len_alloc_fail
	call	printn_msg
	ret


segment .data
	argc 		dd 0
	argv 		dd 0
	fnameptr 	dd 0
	fnamelen 	dd 0
	fd	 	dd 0
	linequeue 	dd 0	; Ptr to ptr to lines
	queuehead	dd 0
	nr_lines	dd 10	; Read last n lines (default = 10)
	singlech	db 0
	flexibuff     	dd 0
        flexibuffsize 	dd 100  ; We start with 100
	flexibuffndx	dd 0
	linelen		dd 0

	; Error messages
	err_msg_file_open 	db "Error opening file : "
	err_msg_len_file_open 	equ ($ - err_msg_file_open)
	err_msg_read 		db "Unknonwn error reading file : "
	err_msg_len_read 	equ ($ - err_msg_file_open)
	err_msg_alloc_fail 	db "Memory allocation/reallocation failed!"
	err_msg_len_alloc_fail equ ($ - err_msg_alloc_fail)
