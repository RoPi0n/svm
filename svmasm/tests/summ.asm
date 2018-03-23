import PrintLn "crt.lib" "PRINTLN"
import InputLn "crt.lib" "INPUTLN"
import StrToFloat "bf.lib" "STRTOFLOAT"

str s1 "Enter two digits:"
str s2 "Summ:"

var a,b

proc Main()
  invoke !PrintLn(!s1)
  invoke !InputLn
  invoke !StrToFloat
  pop    $a
  invoke !InputLn
  invoke !StrToFloat
  pop    $b
  add    $a, $b
  invoke !PrintLn(!s2)
  invoke !PrintLn($a)
  invoke !InputLn
endp