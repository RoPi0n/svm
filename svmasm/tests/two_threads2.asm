include <bf.asm>
import PrintLn "crt.lib" "PRINTLN"

proc  AsyncRun($.prc, $.argc)
   inc    $.argc
   push   $.argc
   gpm
   push   1
   gpm
   newa
   var    .args
   peek   $.args
   gpa
   pop
   AsyncRun.Lp:
     dec   $.argc
     peek  $.args[$.argc]
     push  $.argc
   bg $.argc, 0
   jn !AsyncRun.Lp
   push $.prc
   peek $.args[0]
   push $.args
   push !AsyncRun.RunThrLbl
   AsyncRun.RunThrLbl:
     super thread
	 peek  $.args
	 alen
	 pop   $.argc
	 AsyncRun.Lp2:
       dec   $.argc
       push  $.args[$.argc]
       push  $.argc
     bg $.argc, 0
     jn !AsyncRun.Lp2
	 call $.args[0]
   AsyncRun.EndProc:
     gc
endp

var ThrMsg

proc Thread2Method()
    push "I'm thread #2!"
    pop  $ThrMsg
    call !OutputLoop
endp


proc Main()
    push "I'm thread #1!"
    pop  $ThrMsg
    call !AsyncRun(!Thread2Method, 0)
    call !OutputLoop
endp


proc OutputLoop()
    invoke !PrintLn($ThrMsg)
    gc
    jump !OutputLoop
endp
