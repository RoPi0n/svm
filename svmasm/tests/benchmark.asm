uses <bf.asm>
uses <crt.asm>

word  Loops 2000000

proc bnch1()
var .i = !Loops, .v = 0
  bnch1.Lp:
   gc
   push $.v
   inc
   push 10
   gpm
   swp
   add
   push 10
   gpm
   swp
   sub
   push 2
   gpm
   swp
   mul
   push 2
   gpm
   swp
   div
   push 2
   gpm
   swp
   mul
   push 2
   gpm
   swp
   idiv
   pop
   push $.i
   dec
  jn !bnch1.Lp
endp

proc bnch2()
var .i = !Loops, .v = 0
  bnch2.Lp:
   gc
   push $.v
   incw
   push 10
   gpm
   swp
   addw
   push 10
   gpm
   swp
   subw
   push 2
   gpm
   swp
   mulw
   push 2
   gpm
   swp
   divw
   push 2
   gpm
   swp
   mulw
   push 2
   gpm
   swp
   idivw
   pop
   push $.i
   decw
  jn !bnch2.Lp
endp

proc Main()

  stkdrop
  gc

  invoke !TickCnt
  call   !bnch1()
  invoke !TickCnt
  sub
  invoke !PrintLn

  stkdrop
  gc

  invoke !TickCnt
  call   !bnch2()
  invoke !TickCnt
  sub
  invoke !PrintLn

  invoke !InputLn
endp
