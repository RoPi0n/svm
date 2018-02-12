import PrintLn "crt.lib" "PRINTLN"
import InputLn "crt.lib" "INPUTLN"


str Hello "Hello, what's your name?"
str Hello_Guy "You good guy, "


Main:
  push !Hello
  push !PrintLn
  invoke
  push !InputLn
  invoke
  push !Hello_Guy
  add
  push !PrintLn
  invoke
  gc