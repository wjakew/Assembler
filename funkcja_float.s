#przyklad uzycia scanf do pobrania tekstu

#by Jakub Wawak 2018
#kubawawak@gmail.com

# sys_exit   ( 0x01 -> eax (syscall number), exit code -> ebx),
# sys_read   ( 0x03 -> eax (syscall number), file descriptor -> ebx, buffer address -> ecx, buffer length -> edx )
# sys_write  ( 0x04 -> eax (syscall number), file descriptor -> ebx, buffer address -> ecx,  msg len ->edx )
.global _main

.section .text
_main:

#wyswietla "Podaj pierwsza liczbe:"
mov $format2,%rdi
mov info_text,%rax
call printf

#pobiera do bufor pierwszy int
mov $format, %rdi
mov $bufor,%rsi
mov $1,%rax
call scanf

#wyswietla "Podaj druga liczbe:"
mov $format2,%rdi
mov info_text2,%rax
call printf

#pobiera do bufor2 drugi int
mov $format, %rdi
mov $bufor2,%rsi
mov $1,%rax
call scanf

mov $bufor, %rax
call convert_from_ascii_to_dec

mov %rax, %rdi			#%rdi -> tutaj znajduje sie pierwszy int

mov $bufor, %rax
call convert_from_ascii_to_dec

mov %rax %rsi			#%rsi -> tutaj znajduje sie drugi int

call adder

call sys_exit

#-----------------------------------------------------
#adding two integers
#number 1 -> %rdi
#number 2 -> %rsi

adder:
	add %rdi,%rsi


#-----------------------------------------------------
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

#-----------------------------------------------------
# exit to console
sys_exit:

	movl	$1, %eax
	movl	$0, %ebx

	int	$0x80

	ret
#-----------------------------------------------------
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
.section .data
info_text: .asciz "Podaj pierwsza liczbe:"
info_text2: .asciz "Podaj druga liczbe:"
bufor: .space 4
bufor2: .space 4
format: .asciz "%d\n"
format2: .asciz "%s\n"
