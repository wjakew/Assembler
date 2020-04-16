#by Jakub Wawak 2018
#kubawawak@gmail.com

# sys_exit   ( 0x01 -> eax (syscall number), exit code -> ebx),
# sys_read   ( 0x03 -> eax (syscall number), file descriptor -> ebx, buffer address -> ecx, buffer length -> edx )
# sys_write  ( 0x04 -> eax (syscall number), file descriptor -> ebx, buffer address -> ecx,  msg len ->edx )
.global _start

.section .text
_start:

call sys_console_newline

#wyswietlanie msg1

mvl $msg1,%ecx
movl $MSG_SIZE,%edx
call sys_console_write

#otwieranie pliku ze siezki zawartej w zmiennej filename
#w %rax ilość przeczytanych znaków
call  sys_open_file_and_read

#operacja na danych z pliku
call ascii_to_hexTab 							# w $numbers wartosci z pliku

#wyjscie z programu


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
#--------------------------------------------------------
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
#--------------------------------------------------------
# read message from console
sys_console_read:

	push	%rbx

	movl	$0x03, %eax
	movl	$0, %ebx

	int	$0x80

	pop	%rbx

	ret
#--------------------------------------------------------
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
#--------------------------------------------------------
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
#--------------------------------------------------------
#BubbleSort
# count -> ilosc liczb w tabeli
# pArray -> wskaznik na pierwsza wartosc w tabeli

bubbleSort:
    mov $count,%ecx             # zapisuje wartosc ilosci w %ecx
    dec %ecx                    # zmniejszam wartosc licznika ilosci

_loop1:

      push %ecx                 # klade %ecx na stosie
      mov %pArray, %esi         # zapisuje w %esi wskaznik na pierwszy element

      _loop2:
            mov (%esi),%eax     # przenosze adres na esi do wartosci rejestru eax
						add $4,(%esi)
            cmp (%esi),%eax    # porownuje nastepna wartosc z tabeli z aktualna
            jg _loop3           # jesli jest mniejsza ide dalej
            xchg 4(%esi),%eax   # jesli jest wieksza zamieniam je miejscami
            mov (%esi),%eax     # przenosze adres na rejestr %esi do %eax

            _loop3:
                  add $4, (%esi)
                  jmp _loop2
                  pop %ecx
                  jmp _loop1
ret
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
#--------------------------------------------------------
#konwersja zawartosci $info na tabele liczb 4 bajt w hex
# $info -> zawartosc do konwersji
# %ecx -> ilosc obrotow petli
# %esi -> na tym rejestrze bedziemy pracowac
# zwraca:
# %r8  -> ilość liczb po konwersji
#
# $numbers <- zwraca zamieniony bufor

ascii_to_hexTab:

		push %rax
		push %rbx
		push %rcx
		push %rsi

		movl %eax,%ecx 							# zapis ile jest bajtów w buforze
		xor %r8, %r8

		mov $info, %esi 						# w %esi adres bufora z liczbami ascii do konwersji
		mov $numbers, %edi					# w %edi adres bufora z liczbami hex po konwersji
		mov $frg, %edx							# w %edx adres bufora na kolejną liczbę w ascii
		xor %r9, %r9

		_ath_loop_Tab:
					cmp (%esi), new_line   # sprawdzam czy aktualna wartosc to koniec lini
					je _ath_blank

					movb (%esi), %al				# dodaj kolejny zank do stringu do konwersji
					movb %al, (%edx)				# jesli nie jest to koniec linii dodaje kolejny bajt do fragmentu
					inc %esi
					inc %edx								# miejsce na kolejny znak
					inc %r9

					jmp _ath_next_iteration

				_ath_blank:
					push %ecx

					movl $frg, %ebx 										# wstawienie do %ebx zeby zamienic na dec
					movl %r9,	 %ecx       							# wielkosc bufora %esi = 1

					call convert_from_ascii_to_dec 			# w %rax konwersja na liczbe hex

					pop %ecx

					movl %rax, (%edi)									# zapisuje przekonwertowana liczbe do $numbers
					add $4, %edi											# przejdz do kolejnej liczby zrodlowej
					inc %r8														# kolejna liczba przekonwertowana
					xor %r9, %r9
					mov $frg, %edx										# inicjalizacja bufora na kolejną liczbę
					inc %esi

				_next_iteration:

			loop _loop_Tab

		pop %rsi
		pop %rcx
		pop %rbx
		pop %rax

		ret
#--------------------------------------------------------
#opening file and read
# %ebx -> adres na nazwe pliku
# $file_name -> sciezka do pliku
# $info -> zawartosc pliku

# zwraca w %eax <- zwraca ilość przeczytanych znaków
sys_open_file_and_read:

		push %rbx
    push %rcx
    push %rdx

    # otwieranie pliku
    movl $0x05, %eax        # ustawiono kod otwarcia do czytania pliku
    movl $filename, %ebx
    movl $0, %ecx           # read only access
    movl $0777,%edx         # read, write and execute by all

    int $0x80

    # czytanie z pliku
    movl %eax, fd_in

    movl $0x03, %eax
    movl fd_in, %ebx
    movl $info, %ecx
    movl $INFO_COUNT, %edx
    int $0x80

		push %rax
    # zamykanie pliku
    movl $6, %eax
    movl fd_in, %ebx
    int 0x80

		pop %rax

		pop %rdx
		pop %rcx
		pop %rbx

ret
#--------------------------------------------------------
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

# Close file
#	%ebx -> handle for a file to be closed

sys_close_file:

	push	%rax

	movl	$0x06, %eax
	int	$0x80

	pop	%rax

	ret

#--------------------------------------------------------
#converting dec to ascii
# %rax - > wartosc do zmiany
# %rbx - > ilosc liczb

dec_to_ascii:
	movl %ebx,%ecx

	_loop_dec:
			movl (%ebx), %ax







#--------------------------------------------------------
.section .data

filename: .asciz "./test.txt"

msg1: .ascii "Laduje liczby z pliku "
.equ MSG1_SIZE, .-msg1

msg4: .ascii "Wynik sortowania: "
.equ MSG4_SIZE, .-msg4

.equ BUF_LEN, 256

frg: .space 16

info:	.space 40000
.equ INFO_COUNT . - info
numbers: .long 10000
.equ NUMBERS_COUNT 10000

new_line: .byte 0x0A

dec_val: .int 10
hex_buffer: .space 16, 0x0A
.equ HEX_BUF_SIZE, . - hex_buffer
hex_lkp_tbl: .ascii "0123456789ABCDEF"
hex_exm: .8byte 0x1234567890ABCDEF
#--------------------------------------------------------
section .bss

fd_out: resb 1
fd_in: resb 1
info: resb 10000
