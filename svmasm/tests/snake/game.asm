uses <bf.asm>
uses <vector.asm>
uses <crt.asm>
uses "global.asm"
uses "borders.asm"
uses "snake.asm"
uses "control.asm"

proc GameOver()
  ;FreeGame
  invoke !Crt.ClrScr
  invoke !PrintLn("-= Game over =-")
  var .s = "Score: "
  push $score
  invoke !IntToStr
  gpm
  push $.s
  add
  add  $.s, "."
  invoke !PrintLn($.s)
  invoke !InputLn
  jump   !__haltpoint
endp

proc DrawBorder($.b)
  call !FillXY($.b[!x], $.b[!y], !chr_border)
endp

proc DrawBorders()
  call !vector.foreach($vborders, !DrawBorder)
endp

var snakehead

proc CheckForBorder($.b)
  eq   $snakehead[!x], $.b[!x]
  eq   $snakehead[!y], $.b[!y]
  and
  jn   !GameOver
endp

proc CheckForGameOver($.head)
var .sz
  movl $snakehead, $.head
  call !vector.foreach($vborders, !CheckForBorder)
  call !vector.count($vsnake)
  pop  $.sz
  bg   $.sz, 3
  jz   !CheckForGameOver.End
    call !vector.foreach_withoutlast($vsnake, !CheckForBorder)
  CheckForGameOver.End:
endp

proc CheckForFood($.head)
  eq $.head[!x], $food_x
  eq $.head[!y], $food_y
  and
endp

proc MoveFood()
  invoke !RandomB(38)
  pop    $food_x
  add    $food_x, 2
  invoke !RandomB(18)
  pop    $food_y
  add    $food_y, 2
endp

proc MoveSnake()
var .sLast, .sHead, .sNew, .nx, .ny
  call !vector.at($vsnake, 0)
  pop  $.sLast
  call !vector.peekback($vsnake)
  pop  $.sHead
  ;;;
  eq $snake_vect, !svUp
  jn !MoveSnake.MoveUp
  eq $snake_vect, !svDown
  jn !MoveSnake.MoveDown
  eq $snake_vect, !svLeft
  jn !MoveSnake.MoveLeft
  eq $snake_vect, !svRight
  jn !MoveSnake.MoveRight
  ;;;
  MoveSnake.MoveUp:
    call !FillXY($.sLast[!x],$.sLast[!y]," ")
    new  $.nx
    new  $.ny
    mov  $.nx, $.sHead[!x]
    mov  $.ny, $.sHead[!y]
    ;;;
    dec  $.ny
    ;;;
    call !snake.blockcreate($.nx, $.ny)
    pop  $.sNew
    call !vector.pushback($vsnake, $.sNew)
    call !FillXY($.nx, $.ny, !chr_snake)
    call !CheckForGameOver($.sNew)
    call !CheckForFood($.sNew)
    jn   !MoveSnake.FoundFood
    call !vector.popfirst($vsnake)
  jump !MoveSnake.End
  ;;;
  MoveSnake.MoveDown:
    call !FillXY($.sLast[!x],$.sLast[!y]," ")
    new  $.nx
    new  $.ny
    mov  $.nx, $.sHead[!x]
    mov  $.ny, $.sHead[!y]
    ;;;
    inc  $.ny
    ;;;
    call !snake.blockcreate($.nx, $.ny)
    pop  $.sNew
    call !vector.pushback($vsnake, $.sNew)
    call !FillXY($.nx, $.ny, !chr_snake)
    call !CheckForGameOver($.sNew)
    call !CheckForFood($.sNew)
    jn   !MoveSnake.FoundFood
    call !vector.popfirst($vsnake)
  jump !MoveSnake.End
  ;;;
  MoveSnake.MoveLeft:
    call !FillXY($.sLast[!x],$.sLast[!y]," ")
    new  $.nx
    new  $.ny
    mov  $.nx, $.sHead[!x]
    mov  $.ny, $.sHead[!y]
    ;;;
    dec  $.nx
    ;;;
    call !snake.blockcreate($.nx, $.ny)
    pop  $.sNew
    call !vector.pushback($vsnake, $.sNew)
    call !FillXY($.nx, $.ny, !chr_snake)
    call !CheckForGameOver($.sNew)
    call !CheckForFood($.sNew)
    jn   !MoveSnake.FoundFood
    call !vector.popfirst($vsnake)
  jump !MoveSnake.End
  ;;;
  MoveSnake.MoveRight:
    call !FillXY($.sLast[!x],$.sLast[!y]," ")
    new  $.nx
    new  $.ny
    mov  $.nx, $.sHead[!x]
    mov  $.ny, $.sHead[!y]
    ;;;
    inc  $.nx
    ;;;
    call !snake.blockcreate($.nx, $.ny)
    pop  $.sNew
    call !vector.pushback($vsnake, $.sNew)
    call !FillXY($.nx, $.ny, !chr_snake)
    call !CheckForGameOver($.sNew) 
    call !CheckForFood($.sNew)
    jn   !MoveSnake.FoundFood
    call !vector.popfirst($vsnake)
  jump !MoveSnake.End
  ;;;
  MoveSnake.FoundFood:
  call !MoveFood()
  inc  $score
  dec  $TickDelay
  ;;;
  MoveSnake.End:
endp

proc DrawFood()
  call !FillXY($food_x, $food_y, !chr_food)
endp

proc DrawScoreboard()
var .s = "Score: "
  push $score
  invoke !IntToStr
  gpm
  push $.s
  add
  add  $.s, "."
  call !FillXY(1, 21, $.s)
  mov  $.s, "Snake length: "
  call   !vector.count($vsnake)
  invoke !IntToStr
  gpm
  push $.s
  add
  add  $.s, "."
  call !FillXY(1, 22, $.s)
  rem  $.s
endp

proc GameTick()
  call !DrawFood()
  call !MoveSnake()
  call !DrawScoreboard()
endp

proc Main()
  call !InitGame()
  call !FillMap_1()
  call !DrawBorders()

  call !snake.create(5,5,!svRight)
  call !RunControlThread()

  lp:
    gc
    call !GameTick()
    push $TickDelay
    jz !lp
    invoke !Sleep($TickDelay)
  jump !lp
endp
