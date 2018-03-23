include "forms.asm"
import Halt "bf.lib" "EXITPROCESS"

var Form, Canvas

;stream _Icon "form_icon.ico"

str   _Caption  "Draw on me :)"

word  _False    0
word  _True     1

var MouseDowned, LastMouseX, LastMouseY


proc FormThread_Init()
  push !_False
  peek $MouseDowned
  pop
  push !null
  peek $LastMouseX
  pop
  push !null
  peek $LastMouseY
  pop
endp


proc FormThread_HandleEvent($.Event)
  push !Form_HandleEvent.FormClose
  gpm
  push $.Event
  push !EVT_FormClose
  gpm
  eq
  gpm
  jn
  pop
  
  push !Form_HandleEvent.MouseMove
  gpm
  push $.Event
  push !EVT_FormMouseMove
  gpm
  eq
  gpm
  jn
  pop
  
  push !Form_HandleEvent.MouseDown
  gpm
  push $.Event
  push !EVT_FormMouseDown
  gpm
  eq
  gpm
  jn
  pop
  
  push !Form_HandleEvent.MouseUp
  gpm
  push $.Event
  push !EVT_FormMouseUp
  gpm
  eq
  gpm
  jn
  pop
  
  jump !Form_HandleEvent.End
  
  Form_HandleEvent.FormClose:
    ;invoke !_Application_Terminate
    invoke !Halt
	jump !Form_HandleEvent.End
	
  Form_HandleEvent.MouseMove:
    push !Form_HandleEvent.MouseMove.Draw
	gpm
	push $MouseDowned
	push !_True
	gpm
	eq
	gpm
	jn
	pop
	Form_HandleEvent.MouseMove.Move:
	  invoke !_Form_LastEventArgAt($Form, 0)
	  gpm
	  invoke !_Form_LastEventArgAt($Form, 1)
	  gpm
	  invoke !_Canvas_MoveTo($Canvas)
  jump !Form_HandleEvent.End
	Form_HandleEvent.MouseMove.Draw:
	  invoke !_Form_LastEventArgAt($Form, 0)
	  gpm
	  invoke !_Form_LastEventArgAt($Form, 1)
	  gpm
	  invoke !_Canvas_LineTo($Canvas)
  jump !Form_HandleEvent.End
	
  Form_HandleEvent.MouseDown:
    push !_True
	gpm
	push $MouseDowned
	mov
  jump !Form_HandleEvent.End

  Form_HandleEvent.MouseUp:
    push !_False
	gpm
	push $MouseDowned
	mov
  jump !Form_HandleEvent.End
  
  Form_HandleEvent.End:
    gc
endp


proc FormThread()
  super thread
  peek $Form
  pop
  call   !FormThread_Init
  invoke !_Form_SetLeft($Form, 100)
  invoke !_Form_SetTop($Form, 100)
  invoke !_Form_SetWidth($Form, 500)
  invoke !_Form_SetHeight($Form, 500)
  invoke !_Form_SetCaption($Form, !_Caption)
  ;invoke !_Form_LoadIconFromStream($Form, !_Icon)
  invoke !_Form_GetCanvas($Form)
  peek $Canvas
  pop
  invoke !_Form_Show($Form)
  invoke !_Canvas_SetPenColor($Canvas, 0)
  
  FormThread.EventHandler:
    invoke !_Form_WaitForEvent($Form)
	gpm
	call   !FormThread_HandleEvent
	gc
	stkdrop
  jump !FormThread.EventHandler
endp


proc Main()
  invoke !_Application_Initialize
  ;invoke !_Application_LoadIconFromStream(!_Icon)
  invoke !_Application_CreateForm
  call   !FormThread
  push   !FormThread
  cthr                         
  rthr
  invoke !_Application_Run
endp