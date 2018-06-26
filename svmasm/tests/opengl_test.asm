uses <bf.asm>
uses <opengl.asm>

word  AppWidth   500
word  AppHeight  500
word  AppLeft    200
word  AppTop     200
str   AppCaption "I'm SVM OpenGL app!"

proc Main()
    invoke !glutInit()
    push   !GLUT_DOUBLE
    push   !GLUT_RGB
    push   !GLUT_DEPTH
    orw
    orw
    invoke !glutInitDisplayMode
    invoke !glutInitWindowSize(!AppWidth, !AppHeight)
    invoke !glutInitWindowPosition(!AppLeft, !AppTop)
    invoke !glutCreateWindow(!AppCaption)
    invoke !Sleep(10000)
endp
