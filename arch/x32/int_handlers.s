.section .text

.set INT_NUM, 230
setup_test_idt_entry:
	movl $test_int_handler, %eax
	movl $INT_NUM, %ebx
	call set_idt_entry
	ret

test_int_handler:
	cli		# disable interrupts
	pusha	# push all registers to stack

	# just print 11 to console when interrupt called
	pushl $0x123ABC
	call kernel_print
	popl %eax

	popa	# pop all registers
	sti		# enable interrupts
    iret