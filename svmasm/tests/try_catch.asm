import PrintLn "crt.lib" "PRINTLN"


proc Main()
    push !Finally
	gpm
	push !Catch
	gpm
	tr
	div 10, 0
	trs
  Catch:
    invoke !PrintLn("The exception 'division by zero' catched!")
	invoke !PrintLn("SVM exception message:")
    invoke !PrintLn
  Finally:
	invoke !PrintLn(":)")
    gc
endp