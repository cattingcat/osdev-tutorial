# Programmable Interval Timer

# I/O ports:
.set PIT_COMMAND,  0x43
.set PIT_CHANNEL0, 0x40	# output connected to IRQ0
.set PIT_CHANNEL1, 0x41 # legacy, not implemented on moderh hardware
.set PIT_CHANNEL2, 0x42 # PC-speaker

# PIT command flags:
.set PIT_BIN_MODE, 0x00    # 16 Bit Binary Counting Mode
.set PIT_BCD_MODE, 0x01    # Four Digit Binary Coded Decimal Counting
##
.set PIT_MODE_0,   0x00    # Interrupt on Terminal Count
.set PIT_MODE_1,   0x02    # Hardware re-triggerable One-Shot
.set PIT_MODE_2,   0x04    # Rate Generator
.set PIT_MODE_3,   0x06    # Square Wave Generator
.set PIT_MODE_4,   0x08    # Software Triggered Strobe
.set PIT_MODE_5,   0x0A    # Hardware Triggered Strobe
##
.set PIT_LATCH,    0x00    # Latch Count Value Command
.set PIT_LOBYTE,   0x10    # Access Low Byte Only
.set PIT_HIBYTE,   0x20    # Access High Byte Only
.set PIT_LHBYTE,   0x30    # Access Both Bytes
##
.set PIT_CHANNEL_0, 0x00    # Select Channel 0
.set PIT_CHANNEL_1, 0x40    # Select Channel 1
.set PIT_CHANNEL_2, 0x80    # Select Channel 2
.set PIT_READBACK,  0xC0    # 8254 Readback Command

.set PIT_CH0_OPTS, (PIT_CHANNEL_0 | PIT_LHBYTE | PIT_MODE_2 | PIT_BIN_MODE)
.set PIT_BASE_FREQ, 1193182
.set DIVISOR, 43863 #(PIT_BASE_FREQ / 50)
.set DIV_LOW, (DIVISOR & 0xFF)
.set DIV_HIGH, ((DIVISOR >> 8) & 0xFF)

.section .data
timer_counter:
	.long 0x0

.section .text
timer_handler:
	cli
	pusha
	movl timer_counter, %eax
	incl %eax
	movl %eax, timer_counter
	pushl %eax
	call k_print
	popl %eax
	call pic_ack
	popa
	sti
	iret

# Initialize timer and set interrupt handler
init_pit:
	cli
	# add interrupt listener for IRQ0 (interrupt no 32)
	movl $timer_handler, %eax
	movl $32, %ebx
	call set_idt_entry

	# command byte
	movb $PIT_CH0_OPTS, %al
	outb %al, $PIT_COMMAND
	# set frequency
	movb $DIV_LOW, %al
	outb %al, $PIT_CHANNEL0
	movb $DIV_HIGH, %al
	outb %al, $PIT_CHANNEL0
	sti
	ret
