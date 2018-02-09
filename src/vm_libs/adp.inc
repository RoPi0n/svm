{*
 * D6VM library adapter.
 *}
 
  type TStack = object
   public
    items : array of pointer;
    procedure push(p:pointer);
    function  peek:pointer;
    procedure pop;
    function  popv:pointer;
    procedure swp;
  end;

  type PStack = ^TStack;

  procedure TStack.push(p:pointer);
  begin
   setlength(self.items, length(self.items)+1);
   self.items[length(self.items)-1]:=p;
  end;

  function  TStack.peek:pointer;
  begin
   result:=self.items[length(self.items)-1];
  end;

  procedure TStack.pop;
  begin
   setlength(self.items, length(self.items)-1);
  end;

  function  TStack.popv:pointer;
  begin
   result:=self.items[length(self.items)-1];
   setlength(self.items, length(self.items)-1);
  end;

  procedure TStack.swp;
  var p:pointer;
  begin
   p:=self.items[length(self.items)-2];
   self.items[length(self.items)-2]:=self.items[length(self.items)-1];
   self.items[length(self.items)-1]:=p;
  end;

  type
   TMem = variant;
   PMem = ^TMem;
  
  function new_d6v(v:variant):PMem;
  begin
   new(Result);
   Result^ := v;
  end;