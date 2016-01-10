# Kayboard ports:
.set KB_DATA, 0x60
.set KB_CTRL, 0x64


keyboard_handler:
	cli
	pusha

	pushl 0xBAD
	call k_print
	popl %eax

	# ack for pic 1
	call pic_ack
	
	popa
	sti
	iret

init_keyboard:
	# add interrupt listener for IRQ1 (interrupt no 33)
	movl $keyboard_handler, %eax
	movl $33, %ebx
	call set_idt_entry

	ret
