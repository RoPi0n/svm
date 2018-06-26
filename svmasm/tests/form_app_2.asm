uses <bf.asm>
uses "forms.asm"

var Form, Canvas

;stream _Icon "form_icon.ico"

str   _Caption  "Draw on me :)"

var MouseDowned, LastMouseX, LastMouseY


proc FormThread_Init()
  push !false
  pop  $MouseDowned
  push !null
  pop  $LastMouseX
  push !null
  pop  $LastMouseY
endp


proc FormThread_HandleEvent($.Event)
  eq  $.Event, !EVT_FormClose
  jn !Form_HandleEvent.FormClose

  eq  $.Event, !EVT_FormMouseMove
  jn !Form_HandleEvent.MouseMove

  eq  $.Event, !EVT_FormMouseDown
  jn !Form_HandleEvent.MouseDown

  eq  $.Event, !EVT_FormMouseUp
  jn !Form_HandleEvent.MouseUp

  jump !Form_HandleEvent.End

  Form_HandleEvent.FormClose:
    invoke !_Application_Terminate
    ;invoke !Halt
    jump   !__haltpoint
  jump !Form_HandleEvent.End

  Form_HandleEvent.MouseMove:
    eq   $MouseDowned, !true
    jn   !Form_HandleEvent.MouseMove.Draw
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
    mov $MouseDowned, !true
  jump !Form_HandleEvent.End

  Form_HandleEvent.MouseUp:
    mov $MouseDowned, !false
  jump !Form_HandleEvent.End

  Form_HandleEvent.End:
    gc
endp


proc FormThread()
  super thread
  pop   $Form
  call   !FormThread_Init
  invoke !_Form_SetLeft($Form, 100)
  invoke !_Form_SetTop($Form, 100)
  invoke !_Form_SetWidth($Form, 500)
  invoke !_Form_SetHeight($Form, 500)
  invoke !_Form_SetCaption($Form, !_Caption)
  ;invoke !_Form_LoadIconFromStream($Form, !_Icon)
  invoke !_Form_GetCanvas($Form)
  pop    $Canvas
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
