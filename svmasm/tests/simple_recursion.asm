uses <bf.asm>
uses <crt.asm>

proc RecProc($.a, $.b)
  bg $.b, $.a
  invoke !PrintLn($.a)
  jz !RecProc.End
    store $.a
    inc   $.a
    call  !RecProc($.a, $.b)
    load  $.a
  RecProc.End:
endp

proc Main()
  var a = 1, b = 10
  call   !RecProc($a, $b)
  invoke !PrintLn($a)
  invoke !InputLn
endp
