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
		default:
			return 0;
	}
}

size_t itoa(uint32_t number, char *const buffer, size_t buf_sz, enum WritingMode mode) {
	size_t
		initialPos = _prefix(mode, buffer),
		i = initialPos;

	uint8_t modeBase = mode;

	do {
		uint8_t code = number % modeBase;
		char c = _digits[code];
		buffer[i++] = c;

		if(i + 1 >= buf_sz) {
			// break if number is too big
			// i + 1 = text of digit and '\0' symbol
			return 0;
		}
	} while ((number /= modeBase) > 0);

	// revert
	for(size_t j = initialPos; j < i / 2; ++j) {
		size_t mirrorIndex = i - j - 1;
		char c = buffer[j];
		buffer[j] = buffer[mirrorIndex];
		buffer[mirrorIndex] = c;
	}

	// end of string and return length
	buffer[i] = '\0';
	return i + 1;
}
