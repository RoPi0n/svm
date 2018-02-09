import
  from "crt.lib"
   PrintLn "PRINTLN"
  end from
end import


const
  str Hello "Hello world!"
end const


code
  EntryPoint:
	pushc Hello
	pushc PrintLn
	invoke
end code