#include <stddef.h>
#include <stdint.h>
#include "utils.h"

const char _digits[] = "0123456789ABCDEF";

size_t _prefix(enum WritingMode mode, char* buffer) {
	switch(mode) {
		case HEX:
			buffer[0] = '0';
			buffer[1] = 'x';
			return 2;
		case OCT:
			buffer[0] = '0';
			return 1;
		case BIN:
			buffer[0] = '0';
			buffer[1] = 'b';
			return 2;
		case DEC:
			return 0;
		default:
			return 0;
	}
}

size_t itoa(uint32_t number, char *const buffer, size_t buf_sz, enum WritingMode mode) {
	size_t
		prLen = _prefix(mode, buffer),
		i = 0;
	char *b = buffer + prLen;

	uint8_t modeBase = mode;

	do {
		uint8_t code = number % modeBase;
		char c = _digits[code];
		b[i++] = c;

		if(i + prLen + 1 >= buf_sz) {
			// break if number is too big
			// i + 1 = text of digit and '\0' symbol
			return 0;
		}
	} while ((number /= modeBase) > 0);

	// revert
	size_t mid = (i + 1) / 2;
	for(size_t j = 0; j < mid; ++j) {
		size_t mirrInd = i - j - 1;
		char c = b[j];
		b[j] = b[mirrInd];
		b[mirrInd] = c;
	}

	// end of string and return length
	b[i] = '\0';
	return i + prLen + 1;
}
