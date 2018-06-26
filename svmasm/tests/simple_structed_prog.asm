uses <bf.asm>
uses <crt.asm>

proc Summ($.a, $.b)
   add $.a, $.b
endp

proc Main()
  var .a = 10, .b = 20
  call !Summ($.a, $.b)
  invoke !PrintLn($.a)
  invoke !InputLn
endp
