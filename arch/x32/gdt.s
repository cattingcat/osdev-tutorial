# GDT table size, number of records and one entry size
.set GDT_COUNT, 4
.set GDT_ENTRY_SZ, 8

.set KERNEL_CODE_ACCESS, 0x9A # (0b 1101 1010)
.set KERNEL_DATA_ACCESS, 0x92 # (0b 1001 0010)

.set GRAN_1KB_32, 0xC0 # (0b 1100 0000)

.section .data

# Global Descriptor Table
gdt:
	# null-descriptor
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00

	# code segment for kernel, data sgment for kernel, TSS,
	# and other segments
	.skip GDT_ENTRY_SZ*(GDT_COUNT - 1)

# To GDT register (size: 48bit for x32, 80bit for x64, because pointer)
gdtr:
	# length of GDT table
	.short GDT_ENTRY_SZ*GDT_COUNT-1
	# pointer to GDT tabel
	.long gdt

.section .text
setup_gdt:
	lgdt gdtr

	# kernel code segment
	movl $1, %eax			# addr
	movl $0x00000000, %ebx	# base
	movl $0xFFFFFFFF, %ecx	# limit
	movb $KERNEL_CODE_ACCESS, %dh
	movb $GRAN_1KB_32, %dl
	call set_gdt_entry

	# kernel data segment
	movl $2, %eax			# addr
	movl $0x00000000, %ebx	# base
	movl $0xFFFFFFFF, %ecx	# limit
	movb $KERNEL_DATA_ACCESS, %dh
	movb $GRAN_1KB_32, %dl
	call set_gdt_entry

	ret

# Addr in GDT (index in table)
# Base (32) 		(start position)
# Limit (20) 		(length of segment, number of Granule, depends on Granularity)
# Access (8) 		(code | data, readable | writable, valid | invalid, ring: 0, 1, 2, 3)
# Granularity (4) 	(size of Granule,  1Byte block or 1KByte block)

# limit(0-15) base(0-15) base(16-23) access(8) limit(16-19) flags(4) bace(24-31)

# eax - Addr
# ebx - Base
# ecx - Limit
# edx/dx:
#	dh - Access
#	dl - Granularity (last 4 bit) (1111 0000)
set_gdt_entry:
	movl $GDT_ENTRY_SZ, %edi
	mull %edi			# Get GDT entry position in %eax
	movl %ecx, (%eax)	# Set limit(0-15)
	addl $2, %eax
	movl %ebx, (%eax)	# Set base(0-15) and  base(16-23)
	addl $4, %eax
	movb %dh, (%eax)	# Set access(8)
	addl $1, %eax
	shr $16, %ecx		# access to limit(16-19)
	andb $0x0F, %cl		# first 4 bit of cl is limit (0000 1111)
	orb %dl, %cl		# last 4 bit in cl is flags(granularity) (1111 0000)
	movb %cl, (%eax)
	addl $1, %eax
	shr $16, %ebx		# bh now il last bits of base
	movb %bh, (%eax)
	ret
