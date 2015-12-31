#if !defined(__cplusplus)
#include <stdbool.h>
#endif

#include <stddef.h>
#include <stdint.h>
#include "utils/utils.h"
#include "terminal/terminal.h"

#if defined(__linux__)
#error "You are not using a cross-compiler, you will most certainly run into trouble"
#endif

#if !defined(__i386__)
#error "This tutorial needs to be compiled with a ix86-elf compiler"
#endif



#if defined(__cplusplus)
extern "C" /* Use C linkage for kernel_main. */
#endif
void kernel_main(void* raw_memory, uint32_t size) {
	initialize_terminal();

	uint32_t rawMemAddr = (uint32_t)raw_memory;
	char* buffer = raw_memory;
	size_t len = itoa(rawMemAddr, buffer, size, DEC);

	write_string("raw memory address: ");
	write_string(buffer);
	write_string("\n");

	len = itoa(size, buffer, size, DEC);
	write_string("raw memory size address: ");
	write_string(buffer);
	write_string("\n");

	write_string("check innterrupt 23 access to 0x1: ");
	uint32_t atZero = *((uint32_t*)0x1);
	len = itoa(0xC0, buffer, size, BIN);
	write_string(buffer);
	write_string("\n");

	write_string("Hello, kernel World!\nqwe");
}
