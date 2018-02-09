import
  from "crt.lib"
   PrintLn "PRINTLN"
   InputLn "INPUTLN"
  end from
end import


const
  str Hello "Hello, what's your name?"
  str Hello_Guy "You good guy, "
end const


code
  EntryPoint:
	pushc Hello
	gpm
	pushc PrintLn
    gpm
	invoke
	pushc InputLn
	gpm
	invoke
    gpm
	pushc Hello_Guy
	gpm
	add
	pushc PrintLn
	gpm
	invoke
	gc
end code