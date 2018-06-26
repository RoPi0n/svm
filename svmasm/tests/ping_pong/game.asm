uses <bf.asm>
uses <vector.asm>
uses <crt.asm>
uses "global.asm"
uses "borders.asm"
uses "control.asm"
uses "racket.asm"
uses "ball.asm"
uses "aicontrol.asm"

proc GameOver()
var .s = "Score: "
  call   !FreeGame
  invoke !PrintLn("-= You lose! =-")
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

proc CheckForGameOver()
  be $ball[!y], 20
  jn !GameOver
endp

proc GameWin()
var .s = "Score: "
  call   !FreeGame
  invoke !PrintLn("-= You win! =-")
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

proc CheckForGameWin()
  be 0, $ball[!y]
  jn !GameWin
endp

proc DrawBorder($.b)
  call !FillXY($.b[!x], $.b[!y], !chr_border)
endp

proc DrawBorders()
  call !vector.foreach($vborders, !DrawBorder)
endp

proc DrawScoreboard()
var .s = "Score: "
  call !FillXY(63, 2, "First ping-pong for SVM!")
  push $score
  invoke !IntToStr
  gpm
  push $.s
  add
  add  $.s, "."
  call !FillXY(63, 4, $.s)
  rem  $.s
endp

proc RedrawPlayerRacket()
  call !FillXY(2,19, "                                                           ")
  call !racket.drawself($player_racket)
endp

proc GameTick()
  call !ball.moveself($ball)
  call !RedrawPlayerRacket()
  call !DrawScoreboard()
  call !CheckForGameOver()
  call !CheckForGameWin()
endp

proc Main()
  call   !InitGame
  call   !FillMap_1
  call   !DrawBorders

  call   !RunControlThread()

  lp:
    gc
    call !AITick()
    call !GameTick()
    call !AITick()
    push $TickDelay
    jz !lp
    invoke !Sleep($TickDelay)
  jump !lp
endp
