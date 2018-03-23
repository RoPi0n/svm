import PrintLn "crt.lib" "PRINTLN"
import InputLn "crt.lib" "INPUTLN"
import StrToFloat "bf.lib" "STRTOFLOAT"

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