import PrintLn "crt.lib" "PRINTLN"

Main:
  str Hello "Hello world!"
  push !Hello
  push !PrintLn
  invoke