
# sys_exit   ( 0x01 -> eax (syscall number), exit code -> ebx),
# sys_read   ( 0x03 -> eax (syscall number), file descriptor -> ebx, buffer address -> ecx, buffer length -> edx )
# sys_write  ( 0x04 -> eax (syscall number), file descriptor -> ebx, buffer address -> ecx,  msg len ->edx )

.global		_start

.section .text

_start:


# Read 1st number from console

# show prompt
call	sys_console_newline

movl	$msg, %ecx
movl	$MSG_SIZE, %edx
call 	sys_console_write

# read text from console
movl	$buffer, %ecx
movl	$BUF_LEN, %edx
call 	sys_console_read

# convert 1st number
dec	%eax			# remove newline
movl	%eax, %ecx		# number of bytes read from console
movl	$buffer, %ebx		# ascii text
movl	$num1, %edi		# address to store decoded number
call	convert_from_ascii_to_octal

# Read 2nd number from console

# show prompt
movl	$msg, %ecx
movl	$MSG_SIZE, %edx
call	sys_console_write

# read text form console
movl	$buffer, %ecx
movl	$BUF_LEN, %edx
call 	sys_console_read

# convert 2nd number
dec	%eax
movl	%eax, %ecx		# number of bytes read from console
movl	$buffer, %ebx		# ascii text
movl	$num2, %edi		# address to store decoded number
call	convert_from_ascii_to_octal

# add two number read from console
call	add_numbers

# convert result to readable format
call	hex2string

# show result string
call	sys_console_newline

movl	$msg_res, %ecx
movl	$MSG_RES_SIZE, %edx
call	sys_console_write

movl	$hex_buffer, %ecx	# show result on screen
movl	$HEX_BUF_SIZE, %edx
call	sys_console_write

call	sys_console_newline
call	sys_console_newline

call	save_to_file

movl	$msg_file, %ecx		# final report on screen
movl	$MSG_FILE_SIZE, %edx
call	sys_console_write

movl	$filename, %ecx
movl	$FILE_NAME_SIZE, %edx
call	sys_console_write

call	sys_console_newline
call	sys_console_newline

# exit from program
call 	sys_exit

# ----------------------------------------------------
# parameters:
#    %ebx	character buffer
#    %ecx	character count in buffer
#    %edi	address to store the resulting number

convert_from_ascii_to_octal:

	push	%rax
	push	%rbx
	push	%rcx
	push	%rdx
	push	%rdi

	xor	%rax, %rax
	xor	%rdx, %rdx
	movl	$buffer, %ebx

	movb	(%ebx), %dl			# first digit as ascii code
	sub	$48, %dl			# convert ascii code to numeric value
	add	%rdx, %rax
	inc	%ebx				# next digit
	dec	%ecx

	jz	_one_digit_only

	_loop_addr:

		movb	(%ebx), %dl
		sub	$48, %dl		# convert from ascii code to digit value
		salq	$3, %rax
		add	%rdx, %rax
		inc	%ebx

	loop	_loop_addr

	_one_digit_only:

	movq	%rax, (%edi)

	pop	%rdi
	pop	%rdx
	pop	%rcx
	pop	%rbx
	pop	%rax

	ret

#------------------------------------------------------
# parameters:
#   %ebx -> address of a string to be reversed
#   %ecx -> string char count
# returns:
#   reversed string in buf_rev

reverse_string:					# not used but tested

	push	%rcx
	push	%rbx
	push	%rdi
	push	%rsi

	movl	%ecx, %esi			# store char count
	movl	$buf_rev, %edi

	_loop_reverse:

		movb	(%ebx), %al
		movb	%al, (%edi,%esi)

		dec	%esi			# store next char in lower address (reverse operation)
		inc	%ebx			# next char to read

	loop _loop_reverse

	pop	%rsi
	pop	%rdi
	pop	%rbx
	pop	%rcx

	ret

# ----------------------------------------------------
# Add 2 numbers stored under adresses $num1 and $num2
# Store result under address $num_res

add_numbers:

	push	%rax
	push	%rbx
	push	%rdx

	movl	$num1, %ebx
	movq	(%rbx), %rax
	movl	$num2, %ebx
	movq	(%rbx), %rdx

	add	%rdx, %rax

	movl	$num_res, %ebx
	movq	%rax, (%ebx)

	pop	%rdx
	pop	%rbx
	pop	%rax

	ret


# ----------------------------------------------------
# Convert to string hex number stored in $num_res

hex2string:

	push	%rax
	push	%rbx
	push	%rcx
	push	%rdx
	push	%rdi
	push	%rsi

	movl	$16, %ecx			# 16 halfbytes in 64-bit register
	movl	$num_res, %ebx
	movq	(%ebx), %rax			# load number to convert
	movl	$hex_lkp_tbl, %esi
	movl	$hex_buffer, %edi

	_loop_hex2string:

		xor	%ebx, %ebx
		movb	%al, %bl		# hex digit prepared as an index into hex lookup table
		and	$0x0F, %bl		# clear upper halfbyte - we only need one digit
		movb	(%esi,%ebx), %dl	# find ascii representation of a hex digit from a lookup table
		movb	%dl, -1(%edi,%ecx)	# store ascii representation of a hex digit to a conversion buffer

		shr	$4, %rax

	loop _loop_hex2string

	pop	%rsi
	pop	%rdi
	pop	%rdx
	pop	%rcx
	pop	%rbx
	pop	%rax

	ret

# -----------------------------------------------------
# Save result to a file

save_to_file:

	push	%rax
	push	%rbx
	push	%rcx
	push	%rdx

	movl	$filename, %ebx
	call	sys_open_file_for_write

	# now %eax contains file handle (if positive), save it on stack
	push	%rax			# better safe than sorry

	movl	%eax, %ebx
	movl	$hex_buffer, %ecx
	movl	$HEX_BUF_SIZE, %edx
	call	write_to_file

	pop	%rax			# file handle saved previously
	movl	%eax, %ebx
	call	sys_close_file

	pop	%rdx
	pop	%rcx
	pop	%rbx
	pop	%rax

	ret

# -----------------------------------------------------
# read message from console
# 	-> return number of bytes read in %eax

sys_console_read:

	push	%rbx

	movl	$0x03, %eax
	movl	$0, %ebx

	int	$0x80

	pop	%rbx

	ret

# -------------------------------------------------------
# new line to console

sys_console_newline:

	push	%rcx
	push	%rdx

	movl	$new_line, %ecx
	movl	$1, %edx

	call	sys_console_write

	pop	%rdx
	pop	%rcx

	ret

# -------------------------------------------------------
# write message to console

sys_console_write:

	push	%rax
	push	%rbx

	movl	$0x04, %eax
	movl	$1, %ebx

	int	$0x80

	pop	%rbx
	pop	%rax

	ret

# -------------------------------------------------------
# Open file for read/write, create if it does not exist
#	%ebx -> address of filename string
# returns
#	%eax <- file handle if positive or error if negative

sys_open_file_for_write:

	push	%rcx
	push	%rdx

	movl	$0x05, %eax		# sys_open system call
	movl	$0102, %ecx		# O_RDWR | O_CREAT
	movl	$0666, %edx		# file permissions

	int	$0x80

	pop	%rdx
	pop	%rcx

	ret

# ------------------------------------------------------
# Close file
#	%ebx -> handle for a file to be closed

sys_close_file:

	push	%rax

	movl	$0x06, %eax
	int	$0x80

	pop	%rax

	ret

# -------------------------------------------------------
# Write to file
#	%ebx -> file handle for open file
#	%ecx -> string buffer with content to write
#	%edx -> character count to write

write_to_file:

	push	%rax

	movl	$0x04, %eax
	int	$0x80

	pop	%rax

	ret

# -------------------------------------------------------
# exit to console

sys_exit:

	movl	$1, %eax
	movl	$0, %ebx

	int	$0x80

	ret

# ------------------------------------------------------
.section .data

msg:		.ascii	"Podaj liczbe (oct): "
.equ		MSG_SIZE, . - msg

msg_res:	.ascii "Wynik dodawania (hex): "
.equ		MSG_RES_SIZE, . - msg_res

msg_file:	.ascii "Wynik zapisany do pliku "
.equ		MSG_FILE_SIZE, . - msg_file

filename:	.asciz	"./res.txt"
.equ		FILE_NAME_SIZE, . - filename

new_line:	.byte	0x0A, 0x00

num1:		.8byte	0
num2:		.8byte	0
num_res:	.8byte	0

.equ	BUF_LEN, 256

buffer:		.space	BUF_LEN
buf_rev:	.space	BUF_LEN

hex_buffer:	.space 16, 0x0A
.equ	HEX_BUF_SIZE, . - hex_buffer

hex_lkp_tbl:	.ascii	"0123456789ABCDEF"
hex_exm:	.8byte	0x1234567890ABCDEF

# ------------------------------------------------------
.section .bss
