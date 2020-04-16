
$buffer -> wskaznik na pierwszy element danych z pliku
%rbx -> ilosc elemetow w buffer
$frg -> tymczasowy fragment

$binary_buf <- bufor z zapisanym ciagiem
procedure:

  push %rax
  push %rcx
  push %rsi
  push %r9
  push %r8

  mov $binary_buf,%r9
  mov $buffer, %rcx   # w %rcx mam adres na element pliku
  mov $frg, %rsi

  mov %rbx, %rcx      # ilosc obrotow petli

  _loop_procedue:

    cmp (%rcx), $0x0A
    je _convert

    mov(%rcx),(%rsi)  #zapisujemy do frg
    add $4, %rsi      #przesuwamy na kolejne miejsce w pamieci

    _convert:       #frg jest pelne

        mov frg(,1,4),%eax
        cmp $48,%eax        #%eax,$48
        jae _high
        jmp _exit_loop

        _high:
            cmp $57,%eax
            jbe _next
            jmp _exit_loop

        _next:
        xor %rax,%rax
        mov frg(,2,4),%eax
        cmp $65,%eax
        jae _high_2
        jmp _exit_loop

        _high_2:
            cmp $70,%eax
            jbe _itsok
            jmp _exit_loop

        _itsok:       #w frg jest cyfra, duza litera i spacja

            push %rcx
            mov $1, %rcx
            _loop_cnv:
                mov frg(,%rcx,4),%r8
                inc %rcx

                xor %rax,%rax

                mov %r8,%rax
                _loop_div:
                    div div_two
                    cmp $1, %rdx
                    je _save1
                    jmp _save0

                    _save1:
                          mov $49, (%r9)

                    _save0:
                          mov $48,(%r9)

                    add $4,%r9
                    cmp $0,%rax
                    jne _loop_div

                cmp $3,%rcx
                jna _loop_cnv


_exit_loop:
  loop _loop_procedue

  pop %r8
  pop %r9
  pop %rsi
  pop %rcx
  pop %rax
ret
#------------------------------------------------
.section .data

div_two: .int 2
