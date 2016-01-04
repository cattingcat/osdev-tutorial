# Declare constants used for creating a multiboot header.
.set ALIGN,    1<<0             # align loaded modules on page boundaries
.set MEMINFO,  1<<1             # provide memory map
.set FLAGS,    ALIGN | MEMINFO  # this is the Multiboot 'flag' field
.set MAGIC,    0x1BADB002       # 'magic number' lets bootloader find the header
.set CHECKSUM, -(MAGIC + FLAGS) # checksum of above, to prove we are multiboot

.set STACK_SIZE, 5*1024

# Declare a header as in the Multiboot Standard. We put this into a special
# section so we can force the header to be in the start of the final program.
# You don't need to understand all these details as it is just magic values that
# is documented in the multiboot standard. The bootloader will search for this
# magic sequence and recognize us as a multiboot kernel.
.section .multiboot
.align 4
.long MAGIC
.long FLAGS
.long CHECKSUM
# links from ld-file
.long __mboot
.long __code
.long __bss
.long __end
.long _start

# Currently the stack pointer register (esp) points at anything and using it may
# cause massive harm. Instead, we'll provide our own stack. We will allocate
# room for a small temporary stack by creating a symbol at the bottom of it,
# then allocating 16384 bytes for it, and finally creating a symbol at the top.
.section .bootstrap_stack, "aw", @nobits
stack_bottom:
.skip STACK_SIZE
stack_top:

.include "arch/x32/gdt.s"
.include "arch/x32/idt.s"
.include "arch/x32/int_handlers.s"
.include "arch/x32/pic.s"
.include "arch/x32/pit.s"
.include "arch/x32/page.s"

# The linker script specifies _start as the entry point to the kernel and the
# bootloader will jump to this position once the kernel has been loaded. It
# doesn't make sense to return from this function as the bootloader is gone.
.section .text
.global _start
.type _start, @function
_start:
	# To set up a stack, we simply set the esp register to point to the top of
	# our stack (as it grows downwards).
	movl $stack_top, %esp

	# GRUB pushhed info about bootloading in structure with addr = %ebx
	pushl %ebx

	call setup_gdt
	call setup_idt
	call setup_pic

	# Test functions for Software and Hardware interrupts
	# call setup_test_idt_entry
	# call init_pit

	movl $__end, %eax
    call setup_page
	call register_page_fault

	# try to throw PageFault
	# movl (0xFFFFFFFFFFFFFFFA), %eax

	# enable IRQ (PIT interrupts)
	mov $0x00, %ax
	call set_pic_mask



	# call C-code
	call kernel_main
	popl %ebp

	# infinity loop that waiting interrupts
.Lhang:
	hlt
	jmp .Lhang

# Set the size of the _start symbol to the current location '.' minus its start.
# This is useful when debugging or when you implement call tracing.
.size _start, . - _start
