SYSCALL =	0x80
EXIT =		1
IN = 		0
READ = 		3
OUT = 		1
WRITE =		4
BUF_SIZE = 	254
DISTANCE =	"z"-"a"-1
COMPL =		"z"+"a"

.data
TEXT_SIZE: .long 0
BUFOR: .space BUF_SIZE
ERR_MSG: .ascii "Niepoprawny znak\n"
ER_LEN = .-ERR_MSG

.text
.global start

start:
movl $READ, %eax
movl $IN, %ebx
movl $BUFOR, %ecx
movl $BUF_SIZE, %edx
int $SYSCALL
movl %eax, TEXT_SIZE #przechowujemy ilosc znakow
call ZASZYFRUJ



movl $WRITE, %eax #zawartosc buforu na wyjscie

movl $OUT, %ebx
movl $BUFOR, %ecx
movl TEXT_SIZE, %edx
int $SYSCALL

movl $EXIT, %eax
movl $TEXT_SIZE, %ebx
int $SYSCALL

ZASZYFRUJ:
movl $0, %edi
movb BUFOR(,%edi,1), %bl
or $0x40, %bl
cmpb $'Z', %bl
jbe SZYFRUJ

subb $'a', %bl
jmp $1, %bl
jmp DESZYFRUJ
subb $COMPL, %bl
negb %bl

SZYFRUJ:
incl %edi
cmpl %edi, TEXT_SIZE
je KONIEC

movb BUFOR(,%edi,1), %al

cmpb $'Z', %al
ja error
subb $'A', %al
jb error

addb %bl, %al
cmpb $'Z', %al
jb SAVE

subb $'Z', %al
add $'A', %al

SAVE:
movb %al, BUFOR(,%edi,1)

cmpl TEXT,SIZE, %edi
jbe SZYFRUJ

KONIEC:
ret

DESZYFRUJ:
incl %edi
cmpl %edi, TEXT_SIZE
je KONIEC

movb BUFOR(,%edi,1),%al
cmpb $'z', %al
ja error
subb $'a', %al
jb error

addb $'a', %al

subb %bl, %al
cmpb $'a',%al
jea SAVE

subb $'a', %al
addb $'z',%al
addb $1, %al

SAVE:
movb %al, BUFOR(,%edi,1)

cmpl TEXT_SIZE, %edi
jbe DESZYFRUJ

ERROR:
movl $WRITE, %eax
movl $OUT, %ebx
movl $ERR_MSG, %ecx
movl $ER_LEN, %edx
int $SYSCALL
ret



