#by Jakub Wawak 2018
#kubawawak@gmail.com

# sys_exit   ( 0x01 -> eax (syscall number), exit code -> ebx),
# sys_read   ( 0x03 -> eax (syscall number), file descriptor -> ebx, buffer address -> ecx, buffer length -> edx )
# sys_write  ( 0x04 -> eax (syscall number), file descriptor -> ebx, buffer address -> ecx,  msg len ->edx )
.global _start

.section .text
_start:

mov $3,%rax
call func

add $48,%r9       #zamieniamy na ascii

mov %r9, %rcx
mov $1,%rdx
call sys_console_write

call sys_exit



#---------------------------------------FUNCKJE
#-------------------------------------
# %rax -> n
# %rcx -> i
# %rbx -> bufor
# %rdi -> fragment
# %rsi -> licznik
# %r9 -> index
func:

  push %rbx
  push %rcx
  push %rdi
  push %rsi
  push %r8

  mov $bufor, %rbx                # w %rbx adres na poczatek buforu
  mov $0,%rsi                     # licznik = 0
  mov $-1,%r9                     # index = -1
  xor %rcx,%rcx
  main_loop:

  movb (%rcx,%rbx),%dl            # (%rcx,%rbx) -> *(buf+i)

  #if(*(buf+i)=='1')
  cmpb $49,%dl                    # *(buf+i)=='1'
  je _first_if

  # else
  mov $0,%rsi                     # licznik = 0
  mov $-1,%r9                     # index = -1

  #if (licznik==n)

  cmp %rsi,%rax                    #if (licznik==n)
  je _exit_main_loop

  #if(licznik==0)
  _first_if:
      cmp $0,%rsi
      jne _licznik0
      mov %rcx,%r9            # index = i

      _licznik0:
          inc %rsi            # licznik++

  inc %rcx                    # i++
  jmp main_loop

  _exit_main_loop:

    pop %r8
    pop %rsi
    pop %rdi
    pop %rcx
    pop %rbx

    ret

#-------------------------------------
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
#-------------------------------------
# exit to console
sys_exit:

	movl	$1, %eax
	movl	$0, %ebx

	int	$0x80

	ret
#-------------------------------------SEKCJA DANYCH
  .section .data
  bufor: .asciz "23411123"
