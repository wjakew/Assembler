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
