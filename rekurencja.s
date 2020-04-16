# %eax - > poczatkowa wartosc n

recurrent: #stack version
  push %ebp
  movl %esp,%ebp

  



_exit:
  movl %ebp,%esp
  pop %ebp
  ret
