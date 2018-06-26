uses <bf.asm>
uses <crt.asm>


proc Main()
  push   "Hello, what's your name?"
  invoke !PrintLn
  invoke !InputLn
  push   "You good guy, "
  add 
  invoke !PrintLn
  invoke !InputLn
  gc
endp Main
