global main

segment .text

main:
	mov ebp, esp	
	add ebp, 4		; Skip return address
	mov ebx, [ebp]  	; Fetch argc
	mov [argc], ebx
	add ebp, 4
	mov ebx, [ebp]		; Fetch argv
	mov [argv], ebx
	
	call get_fnameptr
	mov [fnameptr], eax
	
	call print_fname
        ret	

get_fnameptr:
	mov eax, [argv]
	mov eax, [eax+4]
	ret

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
