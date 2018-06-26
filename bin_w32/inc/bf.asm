; Base functions & SVMEXE Initialization.

import IntToStr     "bf.lib" "INTTOSTR"
import FloatToStr   "bf.lib" "FLOATTOSTR"
import StrToInt     "bf.lib" "STRTOINT"
import StrToFloat   "bf.lib" "STRTOFLOAT"
import Halt         "bf.lib" "HALT"
import Sleep        "bf.lib" "SLEEP"
import StrUpper     "bf.lib" "STRUPPER"
import StrLower     "bf.lib" "STRLOWER"
import ChrUpper     "bf.lib" "CHRUPPER"
import ChrLower     "bf.lib" "CHRLOWER"
import Now          "bf.lib" "CURRENTDATETIME"
import Randomize    "bf.lib" "RANDOMIZE"
import Random       "bf.lib" "RANDOM"
import RandomB      "bf.lib" "RANDOMB"
import TickCnt      "bf.lib" "TICKCNT"

; Global values
int  true  -1
int  false  0

uses <dropstack.asm>

proc Exit()
proc super.Exit()
  ; for jump to it from jn/jz
endp

proc super.thread()
  super QuickThread
  call !__InitDropStack
endp

proc super.QuickThread()
  push !__addrtsz
  gpm
  msz
  pop
endp

proc super.ExitThread()
  call !__FreeDropStack
  jump !__haltpoint
endp

__EntryPoint:
  call !__InitDropStack
  call !Main
  call !__FreeDropStack
jr
