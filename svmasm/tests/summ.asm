uses <bf.asm>
uses <crt.asm>

var a,b

proc Main()
  invoke !PrintLn("Enter two digits:")
  invoke !InputLn
  invoke !StrToFloat
  pop    $a
  invoke !InputLn
  invoke !StrToFloat
  pop    $b
  add    $a, $b
  invoke !PrintLn("Summ:")
  invoke !PrintLn($a)
  invoke !InputLn
endp
