import PrintLn "crt.lib" "PRINTLN"


str Msg  "The exception 'division by zero' catched!"
str Msg2 "SVM exception message:"
str Msg3 ":)"
int a 10
int b 0

  
Main:
    push !Finally
	gpm
	push !Catch
	gpm
	tr
	push !b
	gpm
	push !a
	gpm
	div
	trs
  Catch:
    push !Msg
    gpm
	push !PrintLn
    gpm
	invoke
	push !Msg2
    gpm
	push !PrintLn
    gpm
	invoke
	push !PrintLn
	gpm
    invoke
  Finally:
    push !Msg3
	gpm
    push !PrintLn
    gpm
	invoke
    gc