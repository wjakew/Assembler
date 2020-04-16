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

movl $msg1,%ecx
movl $MSG1_SIZE,%edx
call sys_console_write

#otwieranie pliku ze siezki zawartej w zmiennej filename
#w %rax ilość przeczytanych znaków
call  sys_open_file_and_read

#operacja na danych z pliku
call ascii_to_hexTab 							# w $numbers wartosci z pliku
# w %r8 ilosc liczb po konwersji

push %r9

#wypisywanie "Wynik"
movl $msg4,%ecx
movl $MSG4_SIZE,%edx
call sys_console_write

call sys_console_newline

call sys_console_newline

pop %r9

call bubbleSort

call hex_to_asciiTab

#wypisuje zawartosc buforu ascii_buf
mov $ascii_buf,%rcx
mov %r9,%rdx
call sys_console_write

call save_to_file

#wyjscie z programu
call sys_exit

# -----------------------F U N C T I O N-------------------------------
#--------------------------------------------------------
# $numbers -> tablica liczb do sortowania
# %r9 -> ilosc liczb do sortowania
bubbleSort:

	mov %r9, %rcx					# przepisuje ilosc liczb do %rcx (ilosc obrotow petli)

	dec %rcx						# o jeden obrot mniej trzeba wykonac

	mov $numbers,%rsi		# pobieram adres na $numbers do %rsi

	_loop1:
			push %rcx				# zapisuje wartosci licznika zewnetrznej petli (_loop1)


			_loop2:

				mov (%rsi),%rax		# przesuwam aktualna wartosc z tabeli numbers do %rax
				cmp 4(%rsi),%rax	# porownuje NASTEPNA WARTOSC Z AKTUALNA WARTOSCIA TABELI
				ja _loop3			# skoro kolejna bedzie wieksza od aktualnej nalezy je zamienic miejscami

				xchg 4(%rsi),%rax	# zamieniam miejscami liczby
				mov (%rsi), %rax

				_loop3:

					add $4, %rsi	# przesuwam sie na kolejna wartosc z tabeli numbers
					loop _loop2

			pop %rcx

	loop _loop1
#--------------------------------------------------------
# exit to console
sys_exit:

	movl	$1, %eax
	movl	$0, %ebx

	int	$0x80

	ret
#--------------------------------------------------------
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
#converting from ascii to hex
# zwraca wynik w %rax
# dostaje adres bufora ze stringiem do konwersji w rejestrze %ebx
# w ecx ilosc znakow
# zwraca: %eax -> wartosc liczby po konwersji

convert_from_ascii_to_hex:

	push	%rbx
	push	%rcx
	push	%rdx
	push	%rdi

	mov	%ecx, %eax
	cmp	$0, %eax
	jne	_not_empty
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
#konwersja zawartosci $info na tabele liczb 4 bajt w hex
# $info -> zawartosc do konwersji
# %eax -> ilosc znakow w %info do konwersji
# zwraca:
# %r8  -> ilość liczb po konwersji
# $numbers <- zwraca wypelniona tabele z liczbami

ascii_to_hexTab:

		push %rax
		push %rbx
		push %rcx
		push %rdx
		push %rdi
		push %rsi
		push %r9

		movl %eax,%ecx 							# zapis ile jest bajtów w buforze
		xor %r8, %r8

		mov $info, %esi 						# w %esi adres bufora z liczbami ascii do konwersji
		mov $numbers, %edi					# w %edi adres bufora z liczbami hex po konwersji
		mov $frg, %edx							# w %edx adres bufora na kolejną liczbę w ascii
		xor %r9, %r9

		_ath_loop_Tab:
					cmpb $0x0A, (%esi)     # sprawdzam czy aktualna wartosc to koniec lini
					je _ath_convert

					movb (%esi), %al				# dodaj kolejny zank do stringu do konwersji
					movb %al, (%edx)				# jesli nie jest to koniec linii dodaje kolejny bajt do fragmentu
					inc %esi
					inc %edx								# miejsce na kolejny znak
					inc %r9

					jmp _ath_next_iteration

				_ath_convert:

					push %rcx								# zapamietanie licznika zewnetrznej petli

					mov $frg, %rbx 										# wstawienie do %ebx zeby zamienic na dec
					mov %r9, %rcx

					call convert_from_ascii_to_hex 			# w %rax konwersja na liczbe hex

					pop %rcx

					mov %eax, (%edi)									# zapisuje przekonwertowana liczbe do $numbers
					add $4, %edi											# przejdz do kolejnej liczby zrodlowej
					inc %r8														# kolejna liczba przekonwertowana
					xor %r9, %r9
					mov $frg, %edx										# inicjalizacja bufora na kolejną liczbę
					inc %esi

				_ath_next_iteration:

			loop _ath_loop_Tab

		pop %r9
		pop %rsi
		pop %rdi
		pop %rdx
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
    int $0x80

		pop %rax

		pop %rdx
		pop %rcx
		pop %rbx

ret
#--------------------------------------------------------
#converting hex tab to ascii tab
# tabela z liczbami hex do zamiany jest w zmiennej $numbers
# tabela z reprezentacja tych liczb w ascii jest w zmiennej ascii_buf
# %r8 - > ilosc liczb zapisana w zmiennej $numbers
# zwraca:
# %r9 <- ilosc znakow w ascii_buf po konwersji

hex_to_asciiTab:

	push %rax
	push %rbx
	push %rcx
	push %rdx
	push %rdi
	push %rsi


	mov $ascii_buf,%rbx					# zapisujemy adres BUFORA NA ZDEKODOWANE LICZBY do bufora w %rbx
	mov $numbers, %rsi					# zapisujemy adres BUFORA ZAWIERAJACEGO LICZBY DO KONWERSJI w %rsi

	mov %r8,%rcx								# zapisujemy w %rcx ilosc liczb = ilosc obrotow petli

	xor %r9, %r9

	_loop_dta:

						movl (%rsi),%eax	# czytam kolejna liczbe do konersji

						mov   $frg, %rdi	# tymczasowy bufor na string

						push 	%rcx				# zapamietaj licznik zewnetrznej petli

						xor		%ecx, %ecx

				_loop_hta_cnv:

						xor 	%edx, %edx
						divl	dec_val			# dzielenie przez 10

						add 	$48, %dl		# zamiana cyfry na kod ascii
						movb	%dl, (%rdi)
						inc		%rdi
						inc		%ecx				# licznik cyfr
						cmp		$0, %eax
						jne		_loop_hta_cnv

						mov		$frg, %rdi

				_loop_hta_store:

						movb	-1(%rdi,%rcx), %al
						movb	%al,(%rbx)
						inc		%rbx
						inc 	%r9

						loop	_loop_hta_store

						movb	$0x0A, (%rbx)
						inc	%r9

						add $4, %rsi					# przesuwam wskaznik pamieci na kolejne miejsce do pobrania liczby z bufora
						inc %rbx							# przesuwam wskaznik pamieci na kolejne miejsce w buforze ascii do pobrania

						pop	%rcx

						loop _loop_dta

	pop %rsi
	pop %rdi
	pop %rdx
	pop %rcx
	pop %rbx
	pop %rax

	ret
	# -----------------------------------------------------
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
# -----------------------------------------------------
# Save result to a file
save_to_file:

	push	%rax
	push	%rbx
	push	%rcx
	push	%rdx

	movl	$answer, %ebx
	call	sys_open_file_for_write

	# now %eax contains file handle (if positive), save it on stack
	push	%rax			# better safe than sorry

	movl	%eax, %ebx
	movl	$ascii_buf, %ecx
	mov	%r9, %rdx
	call	write_to_file

	pop	%rax			# file handle saved previously
	movl	%eax, %ebx
	call	sys_close_file

	pop	%rdx
	pop	%rcx
	pop	%rbx
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
# ------------------------------------------------------
# Close file
#	%ebx -> handle for a file to be closed

sys_close_file:

		push	%rax

		movl	$0x06, %eax
		int	$0x80

		pop	%rax

		ret
#--------------------------------------------------------
.section .data

filename: .asciz "./test.txt"
answer:		.asciz "./ans.txt"

msg1: .ascii "Laduje liczby z pliku "
.equ MSG1_SIZE, .-msg1

msg4: .ascii "Wynik sortowania: "
.equ MSG4_SIZE, .-msg4

.equ BUF_LEN, 256

frg: .space 16

info:	.space 40000
.equ INFO_COUNT, .-info

numbers: .space 40000
.equ NUMBERS_COUNT, . - numbers

ascii_buf: .space 40000

new_line: .byte 0x0A

dec_val: .int 10

fd_out: .long 0
fd_in: .long 0
#--------------------------------------------------------
.section .bss
