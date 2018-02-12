import PrintLn "crt.lib" "PRINTLN"


str Thr1Message "I'm thread #1!"
str Thr2Message "I'm thread #2!"

var ThrMsg, OutpFnc, PrintLn

Thread2Method:
    push !__addrtsz
	gpm
	msz
	gc
	push !Thr2Message
	peek $ThrMsg
	pop
	push !PrintLn
	peek $PrintLn
	pop
	push !OutputFunction
	peek $OutpFnc
	pop
	push $OutpFnc
	jp
	
Main:
	push !Thr1Message
	peek $ThrMsg
	pop
	push !PrintLn
	peek $PrintLn
	pop
	push !OutputFunction
	peek $OutpFnc
	pop
	push !null
	push !Thread2Method         
	cthr
	rthr
	
OutputFunction:
    push $ThrMsg
	push $PrintLn
	invoke
	push $OutpFnc
	jp
