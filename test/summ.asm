import PrintLn "crt.lib" "PRINTLN"
import InputLn "crt.lib" "INPUTLN"
import StrToFloat "bf.lib" "STRTOFLOAT"


str s_0 "Enter two digits:"
str s_1 "Summ:"

var a,b

Main:
  push !s_0
  gpm
  push !PrintLn
  gpm
  invoke
  push !InputLn
  gpm
  invoke
  push !StrToFloat
  gpm
  invoke
  peek $a
  pop
  push !InputLn
  gpm
  invoke
  push !StrToFloat
  gpm
  invoke
  peek $b
  gc
  pop
  push $a
  push $b
  add
  push !s_1
  gpm
  push !PrintLn
  gpm
  invoke
  pushc PrintLn
  gpm
  invoke
  gc