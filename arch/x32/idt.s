# interrupt table setup
.set INT_COUNT, 50	# num of possible interrupts
.set IDT_REC_SZ, 8	# size of IDT record(8 byte - x32, 16 byte - x64)
.set INT_NUM, 23

.section .data
# Interrupt Descriptor Table
idt:
	# Placeholder for IDT entries
	.skip INT_COUNT*IDT_REC_SZ

# to IDT register(size: 48bit for x32, 80bit for x64, because pointer)
idtr:
	# size of IDT table (limit)
	.short INT_COUNT*IDT_REC_SZ-1

	# location of IDT (base)
	.long idt


.section .text
int_handler:
    movl $0x123abc, 0x1
    hlt

setup_idt:
	lidt idtr
	ret
