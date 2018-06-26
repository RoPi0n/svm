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

proc border.checkat($.x, $.y)
var .b, .r = !false
  call !vector.foreach($vborders, !border.checkat.callback)
  push $.r
  jump !exit
  border.checkat.callback:
    pop $.b
    call !points_eq($.b[!x], $.b[!y], $.x, $.y)
    jz  !exit
    mov $.r, !true
endp

; Создаём комнату - "коробку" для змейки.
proc FillMap_1()
var .i = 0, .t = 0

  mov $.i, $mapsz_h
  mov $.t, $mapsz_w
  FillMap_1.Lp1:
    dec  $.i
    call !addborder_b(1, $.i)
    call !addborder_b($.t, $.i)
    push $.i
    bg   $.i, 1
  jn !FillMap_1.Lp1

  call !addborder_b(10,4)
  call !addborder_b(10,5)
  call !addborder_b(10,15)
  call !addborder_b(10,16)

  call !addborder_b(51,4)
  call !addborder_b(51,5)
  call !addborder_b(51,15)
  call !addborder_b(51,16)

  call !addborder_b(25,8)
  call !addborder_b(25,9)
  call !addborder_b(25,10)
  call !addborder_b(25,11)
  call !addborder_b(25,12)

  call !addborder_b(36,8)
  call !addborder_b(36,9)
  call !addborder_b(36,10)
  call !addborder_b(36,11)
  call !addborder_b(36,12)
  rem $.i
  rem $.t
endp
