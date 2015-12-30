#ifndef OS_UTILS
#define OS_UTILS

enum WritingMode {
	BIN = 2,
	OCT = 8,
	DEC = 10,
	HEX = 16
};

size_t itoa(uint32_t number, char *const buffer, size_t buf_sz, enum WritingMode mode);

size_t strlen(const char* str);

#endif // OS_UTILS
