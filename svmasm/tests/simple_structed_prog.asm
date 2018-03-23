import PrintLn "crt.lib" "PRINTLN"

proc Summ($.a, $.b)
   push $.a
   push $.b
   add
endp

proc Main()
  int _a 10
  int _b 20
  var a = !_a, b = !_b
  call !Summ($a, $b)
  invoke !PrintLn 
endp