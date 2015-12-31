#include <stddef.h>
#include <stdint.h>
#include "../utils/utils.h"
#include "terminal.h"

uint8_t make_color(enum VgaColor fg, enum VgaColor bg) {
	return fg | bg << 4;
}

uint16_t make_vgaentry(char c, uint8_t color) {
	uint16_t c16 = c;
	uint16_t color16 = color;
	return c16 | color16 << 8;
}

#define VGA_WIDTH 80
#define VGA_HEIGHT 25
#define buffer ((uint16_t*) 0xB8000)

size_t row = 0;
size_t column = 0;
uint8_t color = 0;

void initialize_terminal() {
	if(color != 0) return;
	
	color = make_color(COLOR_BLACK, COLOR_DARK_GREY);
	for (size_t y = 0; y < VGA_HEIGHT; y++) {
		for (size_t x = 0; x < VGA_WIDTH; x++) {
			const size_t index = y * VGA_WIDTH + x;
			buffer[index] = make_vgaentry(' ', color);
		}
	}
}

void set_color(uint8_t _color) {
	color = _color;
}

void put_entry_at(char c, uint8_t color, size_t x, size_t y) {
	const size_t index = y * VGA_WIDTH + x;
	buffer[index] = make_vgaentry(c, color);
}

void put_char(char c) {
	if(c == '\n') {
		++row;
		column = 0;
		return;
	}

	put_entry_at(c, color, column, row);
	if (++column == VGA_WIDTH) {
		column = 0;
		if (++row == VGA_HEIGHT) {
			row = 0;
		}
	}
}

void write_string(const char* data) {
	size_t datalen = strlen(data);
	for (size_t i = 0; i < datalen; i++)
		put_char(data[i]);
}
