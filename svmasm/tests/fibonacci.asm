import PrintLn "crt.lib" "PRINTLN"


proc Main()
  var a = 3, b = 40, c = 0, d = 1, e = 0
  invoke !PrintLn(0)
  invoke !PrintLn(1)
  Lp1:
    mov  $e, $d
	add  $d, $c
	mov  $c, $e
	invoke !PrintLn($d)
	inc  $a
	bg   $a, $b
	jz   !Lp1
endp