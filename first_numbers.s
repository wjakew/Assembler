#by Jakub Wawak 2018
#kubawawak@gmail.com

# sys_exit   ( 0x01 -> eax (syscall number), exit code -> ebx),
# sys_read   ( 0x03 -> eax (syscall number), file descriptor -> ebx, buffer address -> ecx, buffer length -> edx )
# sys_write  ( 0x04 -> eax (syscall number), file descriptor -> ebx, buffer address -> ecx,  msg len ->edx )
.global _start

.section .text


_start:

call sys_console_newline

# prompt for first number
movl $msg, %ecx
movl $MSG_SIZE, %edx
call sys_console_write

# reading first number
movl $buffer1, %ecx
movl $BUF_LEN, %edx
call sys_console_read

# converting first number
dec %eax							# usuwam znak nowej linii
movl %eax, %ecx
movl $buffer1, %ebx
call convert_from_ascii_to_dec		# wynik w %rax

movl $num1,%ebx # zapisuje adres na zmienna num1 w rejestrze %ebx
movl %rax,(%ebx) # zapisuje wartosc %rax w komorke pamieci 

#prompt for second number
movl $msg2, %ecx
movl $MSG2_SIZE, %edx
call sys_console_write

# reading second number

movl $buffer2, %ecx
movl $BUF_LEN, %edx
call sys_console_read

# converting second number

dec %eax
movl %eax, %ecx
movl $buffer2, %ebx
call convert_from_ascii_to_dec		# wynik w %rax

movl $num2, %ebx
movl %rax,(%ebx)

# wyznaczanie wspolnych dzielnikow podanych liczb
call first # w %ebx ilosc dzielnikow podanych dwoch liczb

movl %ebx,%eax #hex2string spodziewa sie liczby w %eax
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
# dostaje adres bufora ze stringiem do konwersji w rejestrze %ebx 
# w ecx ilosc znakow
# zwraca: %eax -> wartosc liczby po konwersji
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

	movb	(%ebx), %dl			# first digit as ascii code
	sub	$48, %dl			# convert ascii code to numeric value
	add	%rdx, %rax
	inc	%ebx				# next digit
	dec	%ecx

	jz	_exit_from_convert

	_loop_addr:

		movb	(%ebx), %dl
		sub	$48, %dl		# convert from ascii code to digit value
		push %rdx
		mull	dec_val
		pop %rdx
		add	%rdx, %rax
		inc	%ebx

	loop	_loop_addr

	_exit_from_convert:

	pop	%rdi
	pop	%rdx
	pop	%rcx
	pop	%rbx

	ret


		
#first_numbers
# s252 in Blum book 
first:

	push %rax
	push %rbx
	push %rcx
	push %rdx
	push %rsi
	push %rdi
	push %r8
	push %r9

	movl $primes, %esi # wstawiamy adres tabeli z dzielnikami

	movl $primes_buf, %edi # wstawiamy do edi adres bufora na dzielniki

	movl $num1, %edx # w edx pierwsza liczba

	movl (%edx),%r8d # %r8d pierwsza liczba do sprawdzenia 

	movl $num2, %edx # w %edx zapisuje adres na miejsce pamieci ze zmienna buffer2

	movl (%edx),%r9d # %r9d druga liczba do sprawdzenia

	movl $0, %ebx # licznik dzielnikow 

	movl $PRIMES_NUM, %ecx # inicjalizacja ilosci obrotow petli

	_loop_first:

		cmp		%r8d, (%rsi)		# porownanie czy dzielnik nie jest wiekszy od dzielnej (dzielnik - > rsi)
		jae		_exit_first			# porownanie czy dzielnik zawarty w pamieci o adresie przechowywanym w rsi nie jest wiekszy lub rowny od pierwszej liczby
		cmp		%r9d, (%rsi)		# porownanie czy dzielnik nie jest wiekszy od dzielnej (dzielnik - > rsi)
		jae		_exit_first

		movl	%r8d, %eax			# w %eax pierwsza liczba
		movl	$0, %edx			# wyzerownanie rejestru
		
		div (%rsi) #oznacza edx:eax podzielone przez liczbe piewsza zawarta pod adresem przechowywanym w rsi

		cmp $0, %edx # sprawdzamy czy reszta jest 0 co oznacza ze pierwsza liczba jest podzielna przez aktualna liczbe pierwsza
		jne _next_iter

		movl %r9d, %eax
		movl $0, %edx

		div (%rsi)

		cmp $0,%edx
		jne _next_iter

		movl (%esi),%eax # liczba pierwsza przechowywana w pamieci o adresie w %esi jest dzielnikiem obu liczb
		movl %eax, (%edi)

		inc %ebx # znaleziono kolejny dzielnik
		add $4, %edi # przejscie do kolejnego miejsca w buforze na dzielniki liczb

		_next_iter:
			add $4, %esi # przejscie do sprawdzenia kolejnej liczby pierwszej

	loop _loop_first


_exit_first:	
	pop %r9
	pop %r8
	pop %rdi
	pop %rsi
	pop %rdx
	pop %rcx
	pop %rbx
	pop %rax
	ret
		
# exit to console
sys_exit:

	movl	$1, %eax
	movl	$0, %ebx

	int	$0x80

	ret
# ---------------D A T A -------------S E C T I O N-------------------
.section .data
msg: .ascii "Podaj pierwsza liczbe: "
.equ MSG_SIZE, .-msg
msg2: .ascii "Podaj druga liczbe:"
.equ MSG2_SIZE, .-msg2

msg_res: .ascii "Dzielniki: "
.equ MSG_RES_SIZE, .-msg_res

.equ BUF_LEN, 256

num1: .long 0
num2: .long 0

buffer1: .space BUF_LEN
buf_rev: .space BUF_LEN
buffer2: .space BUF_LEN

new_line: .byte 0x0A

dec_val: .int 10

hex_buffer: .space 16, 0x0A
.equ HEX_BUF_SIZE, . - hex_buffer

hex_lkp_tbl: .ascii "0123456789ABCDEF"
hex_exm: .8byte 0x1234567890ABCDEF

jump: .equ $0

primes: .long  2,3,5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 
primes1: .long 73, 79, 83, 89, 97, 101, 103, 107, 109, 113, 127, 131, 137, 139, 149, 
primes2: .long 151, 157, 163, 167, 173, 179, 181, 191, 193, 197, 199, 211, 223, 227, 
primes3: .long 229, 233, 239, 241, 251, 257, 263, 269, 271, 277, 281, 283, 293, 307, 
primes4: .long 311, 313, 317, 331, 337, 347, 349, 353, 359, 367, 373, 379, 383, 389, 
primes5: .long 397, 401, 409, 419, 421, 431, 433, 439, 443, 449, 457, 461, 463, 467, 
primes6: .long 479, 487, 491, 499, 503, 509, 521, 523, 541, 547, 557,
.equ PRIMES_NUM, (. - primes)/4

primes_buf: .space PRIMES_NUM*4
# -------------------------------------------------------
.section .bss
