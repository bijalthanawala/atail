atail32: atail32.o
	gcc -m32 -o atail32 atail32.o

atail32.o: atail32.asm
	nasm -f elf32 -o atail32.o atail32.asm

clean:
	rm atail32.o atail32
