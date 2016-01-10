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

#if defined(__cplusplus)
extern "C" /* Use C linkage for kernel_main. */
#endif

void k_print(uint32_t val) {
	initialize_terminal();

	const size_t bufSz = 128;
	char buffer[bufSz];

	write_string("kernel_print: ");
	itoa(val, buffer, bufSz, DEC);
	write_string(buffer);
	write_string(" : ");
	itoa(val, buffer, bufSz, HEX);
	write_string(buffer);
	write_string(" : ");
	itoa(val, buffer, bufSz, BIN);
	write_string(buffer);
	write_string("\n");
}

void kernel_main(uint32_t ds) {
	initialize_terminal();

	const size_t bufSz = 128;
	char buffer[bufSz];

	write_string("Hello, kernel World!\n");
}
