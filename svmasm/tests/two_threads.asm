import PrintLn "crt.lib" "PRINTLN"

var ThrMsg

proc Thread2Method()
    super thread
	push "I'm thread #2!"
	pop  $ThrMsg
	call !OutputLoop
endp

	
proc Main()
	push "I'm thread #1!"
	pop  $ThrMsg
	push !null
	push !Thread2Method         
	cthr
	rthr
	call !OutputLoop
endp
	
	
proc OutputLoop()
	invoke !PrintLn($ThrMsg)
	gc
	jump !OutputLoop
endp