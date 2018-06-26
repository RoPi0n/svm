; snake.asm
; *****
; Snake.

; Snake[2] :
;            [0] - x
;            [1] - y

proc snake.blockcreate($.x, $.y)
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

var snake_vect

word  svUp    0
word  svDown  1
word  svLeft  2
word  svRight 3

proc snake.create($.startx, $.starty, $.startvect)
var .b, .x, .y
  new  $snake_vect
  mov  $snake_vect, $.startvect
  new  $.x
  new  $.y
  mov  $.x, $.startx
  mov  $.y, $.starty
  call !snake.blockcreate($.x, $.y)
  pop  $.b
  call !vector.pushback($vsnake, $.b)
endp
