#by Jakub Wawak 2018
#kubawawak@gmail.com

# sys_exit   ( 0x01 -> eax (syscall number), exit code -> ebx),
# sys_read   ( 0x03 -> eax (syscall number), file descriptor -> ebx, buffer address -> ecx, buffer length -> edx )
# sys_write  ( 0x04 -> eax (syscall number), file descriptor -> ebx, buffer address -> ecx,  msg len ->edx )
.global _start

.section .text


_start:

call sys_console_newline

movl $msg, %ecx
movl $MSG_SIZE, %edx
call sys_console_write


# reading

movl $buffer, %ecx
movl $BUF_LEN, %edx
call sys_console_read

# converting

dec %eax
movl %eax, %ecx
movl $buffer, %ebx
call convert_from_ascii_to_dec		# wynik w %rax

# calculating

push  %rax
call recurrent2
add $8, %rsp 		#korekta wskaznika stosu z powodu push przed wywolaniem

call hex2string

call sys_console_newline

movl $msg_res, %ecx
movl $MSG_RES_SIZE, %edx
call sys_console_write

movl $hex_buffer, %ecx
movl $HEX_BUF_SIZE, %edx

call sys_console_write

call sys_console_newline
call sys_console_newline

call sys_exit

# -----------------------F U N C T I O N-------------------------------
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
# read message from console
sys_console_read:

	push	%rbx

	movl	$0x03, %eax
	movl	$0, %ebx

	int	$0x80

	pop	%rbx

	ret
# Convert to string hex number in %eax
hex2string:

	push	%rbx
	push	%rcx
	push	%rdx
	push	%rdi
	push	%rsi

	movl	$16, %ecx			# 16 halfbytes in 64-bit register
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

	ret

#converting from ascii to dec
# zwraca wynik w %rax

convert_from_ascii_to_dec:

	push	%rbx
	push	%rcx
	push	%rdx
	push	%rdi

	mov	%ecx, %eax
	jnz	_not_empty
	xor	%rax, %rax			# empty buffer means 0
	jmp	_exit_from_convert

	_not_empty:

	xor	%rax, %rax
	xor	%rdx, %rdx
	movl	$buffer, %ebx

	movb	(%ebx), %dl			# first digit as ascii code
	sub	$48, %dl			# convert ascii code to numeric value
	add	%rdx, %rax
	inc	%ebx				# next digit
	dec	%ecx

	jz	_exit_from_convert

	_loop_addr:

		movb	(%ebx), %dl
		sub	$48, %dl		# convert from ascii code to digit value
		mull	dec_val
		add	%rdx, %rax
		inc	%ebx

	loop	_loop_addr

	_exit_from_convert:

	pop	%rdi
	pop	%rdx
	pop	%rcx
	pop	%rbx

	ret


#recurrent function(stack version)
# co robi, co jest na wejsciu(rejestry), co jest na wyjsciu, jakich rejestrow nie zahowuje %eax
recurrent2:
	push %rbx

	mov %rsp, %rbx

	mov 16(%rbx),%eax #w %eax mam parametr wywolania

	push %rcx
	push %rdx

	cmp $1, %eax #sprawdzam pierwszy warunek
	jne set1_2
	mov $-1,%eax #jesli sie zgadza zapisuje -1 w rejestrze i przechodze dalej
	jmp _exit2

	set1_2: # sprawdzam drugi warunek
		cmp $2,%eax
		jne set2_2 # jesli nie przechodze do 3 warunku
		mov $-3,%eax
		jmp _exit2

	set2_2:
		dec %eax # parametr n-1
		movl %eax, %ecx # w %ecx paramentr n-1

		push %rax
		call recurrent2
		add $8, %rsp

		movl %eax, %edx # w %eax wartosc zwracana przez funkcje, %edx - wynik pierwszego obliczenia dla n-1
		movl %ecx,%eax # w %eax parametr n-1
		dec %eax # wykonuje dekrement, w %eax mam teraz n-2

		push %rax
		call recurrent2 # w %eax mam wartosc funkcji dla parametru n-2
		add $8, %rsp

		imul %edx #zakladamy ze wszystko miesci sie w %eax

	_exit2:
		pop %rdx
		pop %rcx
		pop %rbx
		ret
		
# exit to console
sys_exit:

	movl	$1, %eax
	movl	$0, %ebx

	int	$0x80

	ret
# ---------------D A T A -------------S E C T I O N-------------------
.section .data
msg: .ascii "Podaj dane dla funkcji reccurent2: "
.equ MSG_SIZE, .-msg

msg_res: .ascii "Wynik dzialania: "
.equ MSG_RES_SIZE, .-msg_res

.equ BUF_LEN, 256

buffer: .space BUF_LEN
buf_rev: .space BUF_LEN

new_line: .byte 0x0A

dec_val: .int 10

hex_buffer: .space 16, 0x0A
.equ HEX_BUF_SIZE, . - hex_buffer

hex_lkp_tbl: .ascii "0123456789ABCDEF"
hex_exm: .8byte 0x1234567890ABCDEF

# -------------------------------------------------------
.section .bss
