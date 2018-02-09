import
  from "crt.lib"
   PrintLn "PRINTLN"
  end from
end import


const
  str Hello "Hello world!"
  int MemSize 3
end const


code
  EntryPoint:
    pushc MemSize
	gpm
	memsz
	gc
	pushc Hello
	peek 0
	pop
	pushc PrintLoop
	peek 1
	pop
	pushc PrintLn
	peek 2
	pop
  PrintLoop:
    push 0
	push 2
	invoke
	push 1
	jp
end code