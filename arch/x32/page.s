.set PAGE_DIR_ENTRY_SZ, 4 #byte
.set PAGE_TBL_ENTRY_SZ, 4 #byte
.set SIZE_4KB, 0x1000
.set DIR_LEN, 1024
.set TBL_LEN, 1024
# Entry flags:
.set PRESENT, 	0b1
.set WRITABLE, 	0b10
.set USER, 		0b100
.set ACCESSED, 	0b10000
.set DIRTY, 	0b100000
.set EMPTY_ENTRY, WRITABLE # (not present)
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
	.skip DIR_LEN * PAGE_DIR_ENTRY_SZ

# Page table for kernel
.align SIZE_4KB	# Must be aligned by 4KB
page_tbl_0:
	# Each entry is a set of flags and Frame address
	.skip TBL_LEN * PAGE_TBL_ENTRY_SZ
paging_end:


.section .text
setup_page:
	pushl %ecx
	call clear_page_dir
	popl %ecx

	call setup_tbl_0

	# set first rage_dir with tbl0
	movl $page_tbl_0, %ecx
	or $FILLED_ENTRY, %ecx	# 0b11
	movl %ecx, page_dir

	# setup cr3 register with page dir pointer
	movl $page_dir, %ecx
	movl %ecx, %cr3
	# setup paging bit in cr0
	movl %cr0, %ecx
	or $0x80000000, %ecx
	movl %ecx, %cr0

	ret

clear_page_dir:
	movl $DIR_LEN, %ecx
	movl $0, %ebx
	CPD_cycle_begin:
		cmp %ebx, %ecx
		je CPD_cycle_end
		leal page_dir(,%ebx, PAGE_DIR_ENTRY_SZ), %eax
		# We can use EMPTY_TBL_ENTRY because table start aligned by 4KB
		#	and last 12 bits used for flags(Present, RW, Permissions)
		movl $EMPTY_ENTRY, (%eax)
		incl %ebx
		jmp CPD_cycle_begin
	CPD_cycle_end:
	ret

# Setup tbl 0, first ecx chunks
# ecx - number of chunks (by 4KB)
setup_tbl_0:
	movl $0, %ebx
	ST0_cycle_start:
		cmp %ebx, %ecx
		je ST0_cycle_end
		# pointer to Table Entry
		leal page_tbl_0(,%ebx, PAGE_TBL_ENTRY_SZ), %eax
		# push address
		pushl %eax
			# mul index and 4KB size
			movl %ebx, %eax
			movl $SIZE_4KB, %esi
			mull %esi
			# last bits-flag(Presetn, Write, SuperUser)
			or $FILLED_ENTRY, %eax	# 0b11
			# move mul result to edx
			movl %eax, %edx
		# pop addr
		popl %eax
		# Set table entry
		movl %edx, (%eax)

		# goto next entry
		incl %ebx
		jmp ST0_cycle_start
	ST0_cycle_end:
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
