# interrupt table setup
.set INT_COUNT, 50	# num of possible interrupts
.set IDT_REC_SZ, 8	# size of IDT record(8 byte - x32, 16 byte - x64)
.set INT_NUM, 23

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
int_handler:
    movl $0x123abc, 0x1
    iret

setup_idt:
	lidt idtr
	movl $int_handler, %eax
	movl $INT_NUM, %ebx
	call set_idt_entry

	int $INT_NUM
	ret

# eax - handler
# ebx - interrupt no
set_idt_entry:
	leal idt(,%ebx,IDT_REC_SZ), %ecx
	mov %ax, (%ecx)
	addl $2, %ecx
	movw $0x8, (%ecx)
	addl $2, %ecx	# skip 1 byte
	movw $0x8e00, (%ecx)
	addl $2, %ecx
	shr $16, %eax
	mov %ax, (%ecx)
	ret
