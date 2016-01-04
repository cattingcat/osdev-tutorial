.set PAGE_DIR_ENTRY_SZ, 4 #byte
.set PAGE_TBL_ENTRY_SZ, 4 #byte
.set SIZE_4KB, 0x1000
.set DIR_LEN, 1024
.set TBL_LEN, 1024
# Entry flags:
.set PRESENT, 	0b1			# presented in memory?
.set WRITABLE, 	0b10		# Writable or Readable?
.set USER, 		0b100		# User or Superuser?
.set ACCESSED, 	0b10000		# Page was accessed by read/write/execute
.set DIRTY, 	0b100000	# Page was edited
.set SIZE_4MB, 	0b1000000	# Page size (0 - 4KB, 1 - 4MB) (only PSE)
.set PAT, 		0b10000000	# Page Attribute Table
.set GLOBAL,	0b100000000	# Will never deleted from TLB

.set EMPTY_ENTRY, WRITABLE	# (not present)
.set FILLED_ENTRY, (PRESENT | WRITABLE)

# Each page table entry represent 4KB

# Page table entry(32) (from lower to higher):
#	Present(1)
#	Read/Write(1) - Read = 0, Write = 1
#	Permissions(1) - Super = 0
#	Reserved(2)
#	Accessed(1) - if accessed since last refresh
#	Dirty(1) - modified since last refresh
#	Reserved(2)
#	Available(3) - Available for kernel use
#	Frame address(20) - Frame addr, shifter right 12 bits (2^12 = 4096 = 4KB)
#		high 20 bits of the frame address in physical memory

# Page table:
#	Page table entry x1024

# Page directory:
#	PageTable pointer(32) x1024
#	Physical addr of tables (32) x1024
#	Physical address(32)

# separated region for PageData, "aw" - writable section
.section .page_data, "aw"
# Must be aligned by 4KB, last 12 bit - flags, see EMPTY_ENTRY
.align SIZE_4KB
page_dir:
	# Each entry is a pointer to Page Table
	.fill DIR_LEN, PAGE_DIR_ENTRY_SZ, EMPTY_ENTRY

# Page table for kernel
page_tbl_0:
	# Reserve space for other page_tables 1..1024
	# 	and virtual address will equal to linear address

	# Each entry is a set of flags and Frame address
	.fill (DIR_LEN * TBL_LEN), PAGE_TBL_ENTRY_SZ, EMPTY_ENTRY
paging_end:


.section .text
# Setup kernel addr area, load CR* registers
# In:
#	eax - max addr in kernel space
setup_page:
	# loadl max addr from EAX, and init pagging
	call allocate_kernel

	# setup cr3 register with page dir pointer
	movl $page_dir, %ecx
	movl %ecx, %cr3

	# setup paging bit in cr0
	movl %cr0, %ecx
	or $0x80000000, %ecx
	movl %ecx, %cr0

	ret

# Setup page tables for kernel
# In:
# 	eax - max addr, end of Kernel addr
allocate_kernel:
	# remove first 12 bits from addr
	andl $0xFFFFF000, %eax
	addl $0x1000, %eax

	movl $0, %ecx			# Physical/Logical addr
	movl $page_tbl_0, %ebx	# PT entry addr

	AK_cycle_begin:
		pushl %ecx
			orl $FILLED_ENTRY, %ecx
			movl %ecx, (%ebx)
		popl %ecx

		# If qurrent addr equal to max addr - break
		cmpl %eax, %ecx
			je AK_end

		addl $0x1000, %ecx	# inc Phys addr for 4KB
		addl $4, %ebx		# int PT addr for entry size
	jmp AK_cycle_begin
	AK_end:

	# fill Page Directory table
	AK_dir_fill:
	shrl $22, %eax		# take index in dir_table
	movl %eax, %ebx		# ebx number of dir tbl entries
	movl $0, %eax		# eax index of page tbl
	movl $0, %ecx		# ecx index in page_dir tbl

	# for add Page dir addresses from maxxx addr
	AK_fill_begin:
		pushl %eax
			movl $0x1000, %edx
			mull %edx
			addl $page_tbl_0, %eax
			orl $FILLED_ENTRY, %eax
			movl %eax, page_dir(,%ecx, 4)
		popl %eax

		cmp %ebx, %eax
			je AK_fill_end

		incl %eax
		incl %ecx
	jmp AK_fill_begin

	AK_fill_end:
	ret

# Get Directory info and PageTable Info from page addr
# In:
#	%eax - addr (32bit)
# Out:
#	%eax - Page Directory entry
#	%ebx - Page Table entry
get_addr_location:
	movl %eax, %ebx
	shrl $22, %ebx
	# find entry bu addr. ecx - pointer to pageDir entry
	leal page_dir(, %ebx, PAGE_DIR_ENTRY_SZ), %ecx
	movl (%ecx), %ecx			# ecx = pageDir entry
		pushl %ecx				# store page dir entry

	testl $0b10, %ecx			# pageDir initialized?
	movl $0x0, %ebx
	je GAL_end

	# getting offset in PageTable
	movl %eax, %ebx
	shrl $12, %ebx
	and $0b0000001111111111, %bx # take last 10 bits
	and $0xFFFFF000, %ecx		# remove flag bits from PageDir entry
	# Find PageTbl entry by addr
	leal (%ecx, %ebx, PAGE_TBL_ENTRY_SZ), %ebx
	movl (%ebx), %ebx			# loadl page entry to ebx
	GAL_end:
		popl %eax			# load pageDir entry
	ret
