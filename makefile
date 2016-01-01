ASM=i686-elf-as
GCC=i686-elf-gcc
QEMU=qemu-system-i386

GCC_FLAGS=-std=gnu11 -ffreestanding -O2 -Wall -Wextra


utils_objs: utils/utils.h utils/*.c
	$(GCC) -c utils/*.c $(GCC_FLAGS)

terminal_objs: terminal/terminal.h terminal/*.c terminal/*.s
	$(GCC) -c ./terminal/*.c $(GCC_FLAGS)
	$(ASM) ./terminal/*.s

boot.o: boot.s
	$(ASM) boot.s -o boot.o

kernel.o: kernel.c utils/utils.h terminal/terminal.h
	$(GCC) -c kernel.c -o kernel.o $(GCC_FLAGS)

myos.bin: kernel.o boot.o utils_objs terminal_objs linker.ld
	$(GCC) -T linker.ld -o myos.bin -ffreestanding -O2 -nostdlib ./*.o -lgcc

execute: myos.bin
	$(QEMU) -kernel myos.bin

execute-iso: myos.bin
	cp myos.bin isodir/boot/myos.bin
	grub-mkrescue -o myos.iso isodir
	$(QEMU) -cdrom myos.iso

clean:
	rm ./*.o -f
	rm ./*.bin -f
	rm ./isodir/boot/*.bin -f
	rm ./*.iso -f
	rm ./*.out -f
