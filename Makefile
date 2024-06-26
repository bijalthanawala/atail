atail32_80: atail32.o callsys_0x80.o print.o
	gcc -g -m32 -o atail32_80 atail32.o print.o callsys_0x80.o

atail32.o: atail32.asm
	nasm -g -f elf32 -o atail32.o atail32.asm

print.o: print.asm
	nasm -g -f elf32 -o print.o print.asm

callsys_0x80.o: callsys_0x80.asm
	nasm -g -f elf32 -o callsys_0x80.o callsys_0x80.asm

clean:
	rm atail32.o print.o callsys_0x80.o atail32_80
