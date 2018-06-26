uses <bf.asm>

proc Main()
  var a = 10
  lp:
    store $a
    load  $a
    gc
  jump !lp
endp
