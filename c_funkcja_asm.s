#przyklad uzycia scanf do pobrania tekstu

#by Jakub Wawak 2018
#kubawawak@gmail.com

# sys_exit   ( 0x01 -> eax (syscall number), exit code -> ebx),
# sys_read   ( 0x03 -> eax (syscall number), file descriptor -> ebx, buffer address -> ecx, buffer length -> edx )
# sys_write  ( 0x04 -> eax (syscall number), file descriptor -> ebx, buffer address -> ecx,  msg len ->edx )
.global main

.section .text
main:

#czekam na wpisanie
mov $format, %rdi
mov $bufor,%rsi
xor %rax,%rax
call scanf

#wypisuje "echo"
mov $info_text,%rdi
mov $bufor, %rcx
movl (%rcx),%esi
xor %rax,%rax
call printf

call sys_exit

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
info_text: .asciz "Echo: %d \n"
bufor: .quad 0
format: .asciz "%d"
format2: .asciz "%s"
