# interrupt table setup
.set INT_COUNT, 255	# num of possible interrupts
.set IDT_REC_SZ, 8	# size of IDT record(8 byte - x32, 16 byte - x64)

# TypeAttr(8)
# 	Present(1) DescriptorPrivelegeLevel(2) StorageSegment(1)
# 	Type(4):
#		0101 - 32 task gate
#		0110 - 16 interrupt gate
#		0111 - 16 trap gate
#		1110 - 32 interrupt gate
#		1111 - 32 trap gate
.set INT_TYPE, 0x8E # 0b 1000 1110

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
	call set_idt_interrupts_off
	ret

# Set Present bit to 0 for all interrupts
set_idt_interrupts_off:
	movl $INT_COUNT, %ecx
	SIIO_cycle_begin:
		# Set present bit to 0 (Interrupt disabled)
		# ecx = interrupt no
		movb $0x00, idt(,%ecx,IDT_REC_SZ)
		loop SIIO_cycle_begin
	ret

# Set common handler for all interrupts
# Arguments:
# 	eax - handler addr
set_idt_interrupts_common_handler:
	movl $INT_COUNT, %ecx
	SIICH_cycle_begin:
		# eax = interrupt handler addr
		# ebx = ecx = interrupt no
		movl %ecx, %ebx
		call set_idt_entry
		loop SIICH_cycle_begin
	ret

# IDT Entry description:
# 	Offset (32) - pointer to interrupt handler
# 	Selector (16) - offset in GDT
# 	Zeroes (8) - 0b00000000
# 	TypeAttr (8) - see above
# IDT Entry Map:
# 	Offset(0-15) Selector(0-15) Zeroes(0-7) TypeAttr(8) Offset(16-19)
# Arguments:
# 	eax - handler
# 	ebx - interrupt no
set_idt_entry:
	# calculate location in IDT table
	leal idt(,%ebx,IDT_REC_SZ), %edx
	movl %eax, %esi		# copu eax to esi

	mov %si, (%edx)			# lower bytes of handler pointer (16)
	addl $2, %edx

	mov $0x0008, %bx		# see gdt.s
	mov %bx, (%edx)			# offset is GDT (16)
	addl $2, %edx

	movw $0x00, (%edx)		# zero (8)
	addl $1, %edx

	movw $INT_TYPE, (%edx)	# type attr (8)
	addl $1, %edx

	shr $16, %esi			# access ho higher bytes
	mov %si, (%edx)			# setup higher bytes of handler pointer (16)
	ret
