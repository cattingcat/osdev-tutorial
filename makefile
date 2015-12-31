ASM=i686-elf-as
GCC=i686-elf-gcc
QEMU=qemu-system-i386


utils: utils/utils.h utils/*.c
	$(GCC) -c ./utils/*.c -std=gnu99 -ffreestanding -O2 -Wall -Wextra

terminal: terminal/terminal.h terminal/*.c terminal/*.s
	$(GCC) -c ./terminal/*.c -std=gnu99 -ffreestanding -O2 -Wall -Wextra
	$(ASM) ./terminal/*.s

boot.o: boot.s
	$(ASM) boot.s -o boot.o

kernel.o: kernel.c utils/utils.h terminal/terminal.h
	$(GCC) -c kernel.c -o kernel.o -std=gnu99 -ffreestanding -O2 -Wall -Wextra

myos.bin: kernel.o boot.o utils terminal linker.ld
	$(GCC) -T linker.ld -o myos.bin -ffreestanding -O2 -nostdlib ./*.o -lgcc

execute: myos.bin
	$(QEMU) -kernel myos.bin

clean:
	rm ./*.o -f
	rm ./*.bin -f
	rm ./*.iso -f
	rm ./*.out -f
