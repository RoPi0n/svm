; borders.asm
; *****
; Game room borders.

; Border[2] :
;            [0] - x
;            [1] - y

proc border.create($.x, $.y)
var .b
  push 2
  gpm
  push 1
  gpm
  newa
  pop  $.b
  push $.x
  peek $.b[!x]
  push $.y
  peek $.b[!y]
  push $.b
endp

proc border.free($.b)
  gpm $.b[!x]
  gpm $.b[!y]
  push $.b
  gpa
  pop
endp

proc addborder($.x, $.y)
var .b
  call !border.create($.x, $.y)
  pop  $.b
  call !vector.pushback($vborders, $.b)
endp

proc addborder_b($.x, $.y)
var .tx = 0, .ty = 0
  mov $.tx, $.x
  mov $.ty, $.y
  call !addborder($.tx, $.ty)
endp


; Создаём комнату - "коробку" для змейки.
proc FillMap_1()
var .i = 0, .t = 0
  mov $.i, $mapsz_w
  FillMap_1.Lp1:
    dec  $.i
    call !addborder_b($.i, 1)
    push $.i
    bg   $.i, 1
  jn !FillMap_1.Lp1

  mov $.i, $mapsz_h
  mov $.t, $mapsz_w
  FillMap_1.Lp2:
    dec  $.i
    call !addborder_b(1, $.i)
    call !addborder_b($.t, $.i)
    push $.i
    bg   $.i, 1
  jn !FillMap_1.Lp2

  mov $.t, $mapsz_h
  mov $.i, $mapsz_w
  inc $.i
  FillMap_1.Lp3:
    dec  $.i
    call !addborder_b($.i, $.t)
    push $.i
  jn !FillMap_1.Lp3

  rem $.i
  rem $.t
endp
