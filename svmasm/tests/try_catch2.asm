uses <bf.asm>
uses <crt.asm>

proc Main()
  try !Catch, !Finally
    var a = 1
    div $a, 0
  try end
  Catch:
    invoke !PrintLn("The exception 'division by zero' catched!")
    invoke !PrintLn("SVM exception message:")
    invoke !PrintLn
  Finally:
    invoke !PrintLn(":)")
    gc
endp
