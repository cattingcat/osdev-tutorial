# Programmable Interrupt Controller
# Manage hardware interrupts and send them to system Interrupt
# Mappinw between hardware signals and system interrupts number
# Keyboard KeyClick -> interrupt line(IPQ1) -> PIC-chip -> system interrupt -> CPU

# I/O ports for PIC:
.set PIC1, 0x20			# IO addr for master pic
.set PIC2, 0xA0			# IO addr for slave pic
# Command and Data ports for PIC1 and PIC2
.set PIC1_C, PIC1
.set PIC1_D, (PIC1 + 1)
.set PIC2_C, PIC2
.set PIC2_D, (PIC2 + 1)
.set PIC_READ_IRR, 0x0A	# interrupt request register
.set PIC_READ_ISR, 0x0B	# interrupt is-service register
# When IRQ interrupt was completed, we should acknowledge PIC
#	about it. Or we will receive only one IRQ
.set PIC_ACK, 0x20

.section .text
# Set PIC interrupt offset from 8-15 and 0x70-0x77 to 32-48
#	because first 32 ints is CPU-fault interrupts
#	Interrupts from PIC named IRQ
# 	Custom interrupts - ISR
setup_pic:
	# Sent initialize command
	#	now PICs wait for 3 extra 'init words' to data port
	movb $0x11, %al
	outb %al, $PIC1_C
	outb %al, $PIC2_C

	# Master PIC: IRQ(Interrupt nums) 0..7,  Vetcor offset: 0x08, IntNums: 0x08..0x0F
	# Slave PIC:  IRQ(Interrupt nums) 8..15, Vetcor offset: 0x70, IntNums: 0x70..0x77

	# 1_Master: Master PIC vector offset (remap IRQ from 0x8-0xF to 0x20-0x28)
	movb $0x20, %al
	outb %al, $PIC1_D
	# 1_Slave: Slave PIC vector ofsset (remap IRQ from 0x70-0x77 to 0x28-0x...)
	movb $0x28, %al
	outb %al, $PIC2_D
	# 2_Master: tell Master PIC that there is a slave PIC at IRQ2 (0000 0100)
	movb $0x04, %al
	outb %al, $PIC1_D
	# 2_Slave: tell Slave PIC its cascade identity (0000 0010)
	movb $0x02, %al
	outb %al, $PIC2_D
	# 3_Master/3_Slave: Set mode: ICW4_8086	0x01  8086/88 (MCS-80/85) mode
	movb $0x01, %al
	outb %al, $PIC1_D
	outb %al, $PIC2_D

	# Restore masks (Set masks to 0b00000000)
	/* The PIC has an internal register called the IMR(Interrupt Mask Register).
	It is 8 bits wide. This register is a bitmap of the request lines going into
	the PIC. When a bit is set, the PIC ignores the request and continues normal
	operation. */
	# set mask to 0xFF / 0b11111111 for disable PIC
	movb $0xFF, %al
	outb %al, $PIC1_D
	outb %al, $PIC2_D
	ret

# mask at ax:
#	pic1 - al
#	pic2 - ah
get_pic_irr:
	movb $PIC_READ_IRR, %al
	outb %al, $PIC1_C
	outb %al, $PIC2_C
	inb $PIC2_C, %al
	shl $8, %ax
	inb $PIC1_C, %al
	ret

# mask at ax:
#	pic1 - al
#	pic2 - ah
get_pic_isr:
	movb $PIC_READ_ISR, %al
	outb %al, $PIC1_C
	outb %al, $PIC2_C
	inb $PIC2_C, %al
	shl $8, %ax
	inb $PIC1_C, %al
	ret

# ax - mask:
#	pic1 - al
#	pic2 - ah
set_pic_mask:
	outb %al, $PIC1_D
	shr $8, %ax
	outb %al, $PIC2_D
	ret

# PIC 1 Acknowledge about int done
pic_ack:
	movb $0x20, %al
	outb %al, $PIC1
	ret
