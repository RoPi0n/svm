import PrintLn "crt.lib" "PRINTLN"
import InputLn "crt.lib" "INPUTLN"


proc Main()
  invoke !PrintLn("Hello, what's your name?")
  invoke !InputLn
  push   "You good guy, "
  add 
  invoke !PrintLn
  gc
endp Main