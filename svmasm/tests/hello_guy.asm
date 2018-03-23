import PrintLn "crt.lib" "PRINTLN"
import InputLn "crt.lib" "INPUTLN"


str Hello "Hello, what's your name?"
str Hello_Guy "You good guy, "


proc Main()
  invoke !PrintLn(!Hello)
  invoke !InputLn
  push   !Hello_Guy
  add 
  invoke !PrintLn
  gc
endp Main