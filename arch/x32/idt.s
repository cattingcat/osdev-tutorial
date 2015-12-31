# interrupt table setup
.set INT_COUNT, 50	# num of possible interrupts
.set IDT_REC_SZ, 8	# size of IDT record(8 byte - x32, 16 byte - x64)

# TypeAttr(8)
# Present(1) DescriptorPrivelegeLevel(2) StorageSegment(1)
# Type(4):
#	0101 - 32 task gate
#	0110 - 16 interrupt gate
#	0111 - 16 trap gate
#	1110 - 32 interrupt gate
#	1111 - 32 trap gate
.set INT_TYPE, 0x8e # 0b 1000 1110

.section .data
# Interrupt Descriptor Table
idt:
	# Placeholder for IDT entries
	.skip INT_COUNT * IDT_REC_SZ

# to IDT register(size: 48bit for x32, 80bit for x64, because pointer)
idtr:
	# size of IDT table (limit)
	.short INT_COUNT * IDT_REC_SZ - 1
	# location of IDT (base)
	.long idt


.section .text
setup_idt:
	lidt idtr
	ret

.set INT_NUM, 23
setup_test_idt_entry:
	movl $test_int_handler, %eax
	movl $INT_NUM, %ebx
	call set_idt_entry
	int $INT_NUM
	ret
test_int_handler:
    movl $0x123abc, 0x1
    iret


# Offset (32) - pointer to interrupt handler
# Selector (16) - offset in GDT
# Zeroes (8) - 0b00000000
# TypeAttr (8) - see above

# IDT Entry Map:
# Offset(0-15) Selector(0-15) Zeroes(0-7) TypeAttr(8) Offset(16-19)

# eax - handler
# ebx - interrupt no
set_idt_entry:
	# calculate location in IDT table
	leal idt(,%ebx,IDT_REC_SZ), %ecx

	mov %ax, (%ecx)			# lower bytes of handler pointer (16)
	addl $2, %ecx

	mov $0x0008, %bx		# see gdt.s
	mov %bx, (%ecx)			# offset is GDT (16)
	addl $2, %ecx

	movw $0x00, (%ecx)		# zero (8)
	addl $1, %ecx

	movw $INT_TYPE, (%ecx)	# type attr (8)
	addl $1, %ecx

	shr $16, %eax			# access ho higher bytes
	mov %ax, (%ecx)			# setup higher bytes of handler pointer (16)
	ret
