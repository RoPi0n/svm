program svmasm;
{$Apptype console}
{$Mode objfpc}
{$H+}

uses SysUtils, Classes, StrUtils;

{** Methods **}

function CheckName(n:string):boolean;
var
  chars: set of char = ['a'..'z','0'..'9','_','.'];
begin
  result := false;
  if not (n[1] in ['0'..'9']) then
   begin
    delete(n,1,1);
    while Length(n)>0 do
     begin
       if not (n[1] in chars) then
        exit;
       delete(n,1,1);
     end;
    result := true;
   end;
end;

function TrimCodeStr(s:string):string;
var
  ConstStr: boolean;
begin
  s := Trim(s);
  ConstStr := false;
  Result := '';
  while Length(s)>0 do
   begin
     if s[1] = '"' then ConstStr := not ConstStr;
     if ConstStr then
      begin
        Result := Result+s[1];
        Delete(s,1,1);
      end
     else
      begin
        if s[1] = ';' then break;
        Result := Result+LowerCase(s[1]);
        Delete(s,1,1);
      end;
   end;
end;

function Tk(s:string; w:word):string;
begin
  result := '';
  while (length(s)>0)and(w>0) do
   begin
    if s[1] = '"' then
     begin
      delete(s,1,1);
      result := copy(s,1,pos('"',s)-1);
      delete(s,1,pos('"',s));
      s := trim(s);
     end
    else
    if Pos(' ',s)>0 then
     begin
      result := copy(s,1,pos(' ',s)-1);
      delete(s,1,pos(' ',s));
      s := trim(s);
     end
    else
     begin
      result := s;
      s := '';
     end;
    dec(w);
   end;
end;

procedure St_WriteWord(s:TStream; w:word);
begin
  s.WriteByte(PByte(cardinal(@w)+1)^);
  s.WriteByte(PByte(@w)^);
end;

procedure St_WriteCardinal(s:TStream; c:cardinal);
begin
  s.WriteByte(PByte(cardinal(@c)+3)^);
  s.WriteByte(PByte(cardinal(@c)+2)^);
  s.WriteByte(PByte(cardinal(@c)+1)^);
  s.WriteByte(PByte(@c)^);
end;

procedure St_WriteInt64(s:TStream; i:Int64);
begin
  if i<0 then
   begin
     s.WriteByte(1);
     i := -i;
   end
  else
   s.WriteByte(0);
  s.WriteByte(PByte(cardinal(@i)+3)^);
  s.WriteByte(PByte(cardinal(@i)+2)^);
  s.WriteByte(PByte(cardinal(@i)+1)^);
  s.WriteByte(PByte(@i)^);
end;

procedure St_WriteDouble(s:TStream; d:double);
begin
  s.WriteByte(PByte(cardinal(@d)+7)^);
  s.WriteByte(PByte(cardinal(@d)+6)^);
  s.WriteByte(PByte(cardinal(@d)+5)^);
  s.WriteByte(PByte(cardinal(@d)+4)^);
  s.WriteByte(PByte(cardinal(@d)+3)^);
  s.WriteByte(PByte(cardinal(@d)+2)^);
  s.WriteByte(PByte(cardinal(@d)+1)^);
  s.WriteByte(PByte(@d)^);
end;

procedure AsmError(m:string);
begin
  writeln('Error: ',m);
  halt;
end;

procedure AsmWarn(m:string);
begin
  writeln('Warning: ',m);
end;

{** Types **}

type
  TBytes = array of byte;
  PBytes = ^TBytes;

  TImportLibrary = class(TObject)
    public
     LibraryPath: string;
     Imports,Methods:TStringList;
     constructor Create(lpath:string);
     destructor Destroy; override;
  end;

  TImportSection = class(TObject)
    public
     Libs:TList;
     Lines:TStringList;
     constructor Create(sl:TStringList);
     destructor Destroy; override;
     function GetLibIndx(l_path:string):integer;
     procedure AddMethod(l_path,m_name,exm_name:string);
     procedure ParseSection;
     procedure GenerateCode(Stream:TStream);
  end;

  TConstantType = (
   ctUnsigned64,
   ctInt64,
   ctDouble,
   ctString,
   ctStream
  );

  TConstant = class(TObject)
    public
     c_name: string;
     c_type: TConstantType;
     c_value: TMemoryStream;
     c_ismirror: boolean;
     c_originlnk: TConstant;
     constructor Create;
     destructor Destroy; override;
     procedure GenerateCode(Stream:TStream);
  end;

  TConstantManager = class(TObject)
    public
     Constants: TList;
     Lines: TStringList;
     constructor Create(sl:TStringList);
     destructor Destroy; override;
     procedure AddConstCardinal(c_name:string; c:cardinal);
     procedure Add(Cnst:TConstant);
     function GetAddr(c_name:string):cardinal;
     procedure ParseSection;
     procedure CheckForDoubles;
     procedure AppendImports(ImportSection:TImportSection);
     procedure GenerateCode(Stream:TStream);
  end;

  TVarManager = class(TObject)
    public
     DefinedVars: TStringList;
     constructor Create;
     destructor Destroy; override;
     procedure DefVar(name:string);
     function Get(name:string):cardinal;
  end;

  TCodeSection = class(TObject)
    public
     Lines: TStringList;
     Constants: TConstantManager;
     Outp: TMemoryStream;
     constructor Create(sl:TStringList; cnsts:TConstantManager);
     destructor Destroy; override;
     procedure ParseSection;
     procedure GenerateCode(Stream:TStream);
  end;

{** Public variables **}

var
  IncludedFiles: TStringList;

{** Preprocessor **}

var
  LocalVarPref:string = '';
  ProcEnterList:TStringList;
  Constants:TConstantManager;
  RgAPICnt:cardinal = 0;

function IsVar(s:string):boolean;
begin
  Result := false;
  if length(s)>0 then
  if s[1] = '$' then
   begin
     delete(s,1,1);
     if s[1] = '.' then
      begin
        Delete(s,1,1);
        s := LocalVarPref + s;
      end;
     Result := CheckName(s);
   end;
end;

function GetVar(s:string; varmgr:TVarManager):string;
begin
  if s[2] = '.' then
   begin
     Delete(s,1,2);
     s := '$' + LocalVarPref + s;
   end;
  if IsVar(s) then
   begin
    delete(s,1,1);
    Result := IntToStr(varmgr.Get(s));
   end
  else
   AsmError('Invalid variable call "'+s+'".');
end;

function IsWord(var s:string):boolean;
var
  w:word;
begin
  Result := Length(s)>0;
  w := 1;
  if Length(s)>2 then
   begin
     if (s[1] = '0') and (s[2] = 'x') then
      begin
        Delete(s,1,2);
        while w <= Length(s) do
         begin
           Result := Result and (s[w] in ['0'..'9', 'a'..'f']);
           inc(w);
         end;
        s := '$' + s;
      end
     else
     while w <= Length(s) do
      begin
        Result := Result and (s[w] in ['0'..'9']);
        inc(w);
      end;
   end
  else
  while w <= Length(s) do
   begin
     Result := Result and (s[w] in ['0'..'9']);
     inc(w);
   end;
end;

function IsInt(s:string):boolean;
var
  w:word;
  mchk:boolean;
begin
  Result := Length(s)>0;
  w := 1;
  mchk := true;
  while w <= Length(s) do
   begin
     if (s[w] = '-') and (w > 1) then
      mchk := false;
     Result := Result and (mchk) and (s[w] in ['0'..'9','-']);
     inc(w);
   end;
end;

function IsFloat(s:string):boolean;
var
  w,dcnt:word;
  mchk:boolean;
begin
  Result := Length(s)>0;
  w := 1;
  dcnt := 0;
  mchk := true;
  while w <= Length(s) do
   begin
     if (s[w] = '-') and (w > 1) then
      mchk := false;
     if s[w] = '.' then
      inc(dcnt);
     Result := Result and (dcnt <= 1) and (mchk) and (s[w] in ['0'..'9','.','-']);
     inc(w);
   end;
end;

function IsStr(s:string):boolean;
begin
  Result := Length(s)>0;
  Result := Result and (s[1] = '"') and (s[length(s)] = '"');
  Delete(s,1,1);
  Delete(s,length(s),1);
  Result := Result and (pos('"',s) = 0);
end;

var
  CntConstAutoDefs:cardinal = 0;

const
  AutoDefConstPref = '__defc_';
  AutoDefConstSuffx = '_n';

function IsConst(var s:string):boolean;
var
  Cnt:TConstant;
  s1:string;
  c:cardinal;
  i:int64;
  d:double;
begin
  s1 := s;
  Result := false;
  if length(s1)>0 then
   begin
     if s1[1] = '!' then
      begin
        delete(s1,1,1);
        Result := CheckName(s1);
      end
     else
     if IsWord(s) then
      begin
        c := StrToInt(s);
        s := AutoDefConstPref+'word'+AutoDefConstSuffx+IntToStr(CntConstAutoDefs);
        Cnt := TConstant.Create;
        Cnt.c_name := s;
        Cnt.c_type := ctUnsigned64;
        St_WriteCardinal(Cnt.c_value, c);
        Constants.Add(Cnt);
        s := '!' + s;
        Result := True;
        inc(CntConstAutoDefs);
      end
     else
     if IsInt(s) then
      begin
        i := StrToInt(s);
        s := AutoDefConstPref+'int'+AutoDefConstSuffx+IntToStr(CntConstAutoDefs);
        Cnt := TConstant.Create;
        Cnt.c_name := s;
        Cnt.c_type := ctInt64;
        St_WriteInt64(Cnt.c_value, i);
        Constants.Add(Cnt);
        s := '!' + s;
        Result := True;
        inc(CntConstAutoDefs);
      end
     else
     if IsFloat(s) then
      begin
        d := StrToFloat(s);
        s := AutoDefConstPref+'float'+AutoDefConstSuffx+IntToStr(CntConstAutoDefs);
        Cnt := TConstant.Create;
        Cnt.c_name := s;
        Cnt.c_type := ctDouble;
        St_WriteDouble(Cnt.c_value, d);
        Constants.Add(Cnt);
        s := '!' + s;
        Result := True;
        inc(CntConstAutoDefs);
      end
     else
     if IsStr(s) then
      begin
        s1 := s;
        Delete(s1,1,1);
        Delete(s1,Length(s1),1);
        s := AutoDefConstPref+'str'+AutoDefConstSuffx+IntToStr(CntConstAutoDefs);
        Cnt := TConstant.Create;
        Cnt.c_name := s;
        Cnt.c_type := ctString;
        Cnt.c_value.Write(s1[1],length(s1));
        Constants.Add(Cnt);
        s := '!' + s;
        Result := True;
        inc(CntConstAutoDefs);
      end;
   end;
end;

function GetConst(s:string):string;
begin
  if IsConst(s) then
   begin
    delete(s,1,1);
    Result := s;
   end
  else
   AsmError('Invalid constant call "'+s+'".');
end;

function IsArr(s:string):boolean;
var
  cnt:integer;
begin
  Result := false;
  if length(s)>0 then
  if (pos('[',s)>0) and (pos(']',s)>0) then
   begin
     Result := true;
     cnt := 0;
     while length(s)>0 do
      begin
        case s[1] of
         '[': inc(cnt);
         ']': dec(cnt);
        end;
        delete(s,1,1);
      end;
     Result := Result and (cnt = 0);
   end;
end;

function GetArrLvl(s:string):cardinal;
var
  cnt:integer;
begin
  Result := 0;
  if (pos('[',s)>0) and (pos(']',s)>0) then
   begin
     cnt := 0;
     while length(s)>0 do
      begin
        case s[1] of
         '[': inc(cnt);
         ']': dec(cnt);
        end;
        if (s[1] = ']') and (cnt = 0) then
         inc(Result);
        delete(s,1,1);
      end;
   end;
end;

function GetArrLvlVal(s:string; indx:cardinal):string;
var
  cnt:integer;
  i:cardinal;
begin
  Result := '';
  i := 0;
  if indx < 1 then
   exit;
  if (pos('[',s)>0) and (pos(']',s)>0) then
   begin
     Delete(s,1,pos('[',s)-1);
     cnt := 0;
     while length(s)>0 do
      begin
        case s[1] of
         '[': inc(cnt);
         ']': dec(cnt);
        end;
        if (s[1] = ']') and (cnt = 0) then
         inc(i);
        delete(s,1,1);
        if i = indx-1 then
         begin
           while length(s)>0 do
            begin
              case s[1] of
               '[': inc(cnt);
               ']': dec(cnt);
              end;
              if (s[1] = ']') and (cnt = 0) then
               break;
              if not ((s[1] = '[') and (cnt = 1)) then
               Result := Result + s[1];
              delete(s,1,1);
            end;
           break;
         end;
      end;
   end;
end;

function GetArrName(s:string):string;
begin
  Result := copy(s,1,pos('[',s)-1);
end;

function PreprocessVarAction(varexpr, action:string; varmgr:TVarManager):string;
begin
  Result := action + ' ' + GetVar(varexpr, varmgr);
end;

function PreprocessArrAction(arrexpr, action:string; varmgr:TVarManager):string;
var
  c,lvl:cardinal;
  s:string;
begin
  Result := '';
  lvl := GetArrLvl(arrexpr);
  c := 0;
  while c <= lvl do
   begin
     s := GetArrLvlVal(arrexpr, c);
     if IsArr(s) then
      Result := Result + sLineBreak + PreprocessArrAction(s,'pushai',varmgr);
     if IsVar(s) then
      Result := Result + sLineBreak + PreprocessVarAction(s,'push',varmgr);
     if IsConst(s) then
      Result := Result + sLineBreak + 'pushc ' + GetConst(s) + sLineBreak + 'gpm';
     inc(c);
   end;
  for c := 0 to lvl-1 do
   Result := Result + sLineBreak + 'push ' + GetVar(GetArrName(arrexpr),varmgr) + sLineBreak + action;
end;

function CountVarDefs(s:string):cardinal;
begin
  s := Trim(s);
  Result := 0;
  if Length(s)>0 then
   Result := 1
  else
   Exit;
  while Length(s)>0 do
   begin
     if s[1] = ',' then
      inc(Result);
     delete(s,1,1);
   end;
end;

function GetVarDef(s:string; indx:integer):string;
begin
  s := Trim(s);
  Result := '';
  while Length(s)>0 do
   begin
     if (s[1] = ',') and (indx = 0) then
      break;
     if s[1] = ',' then
      begin
        dec(indx);
        delete(s,1,1);
      end;
     if (indx = 0) and (Length(s)>0) then
      Result := Result + s[1];
     if Length(s)>0 then
      delete(s,1,1);
   end;
end;

function PreprocessVarDefine(s:string; varmgr:TVarManager):string;
var
  v:string;
begin
  Result := '';
  s := Trim(s);
  if s[1] = '.' then
   begin
     Delete(s,1,1);
     s := LocalVarPref + s;
   end;
  if s = '' then
   exit;
  if pos('=',s)>0 then
   begin
    v := Trim(copy(s,1,pos('=',s)-1));
    delete(s,1,pos('=',s));
    s := Trim(s);
    if IsVar(s) then
     Result := PreprocessVarAction(s,'push',varmgr);
    if IsConst(s) then
      Result := Result + sLineBreak + 'pushc '+GetConst(s);
    if IsArr(s) then
     Result := PreprocessArrAction(s,'pushai',varmgr);
    varmgr.DefVar(v);
    Result := Result + sLineBreak + 'peek ' + GetVar('$'+v,varmgr) + sLineBreak + 'pop';
   end
  else
   varmgr.DefVar(s);
end;

function PreprocessVarDefines(s:string; varmgr:TVarManager):string;
var
  c,cnt: cardinal;
  df: string;
begin
  Result := '';
  cnt := CountVarDefs(s);
  for c := 0 to cnt-1 do
   begin
     df := GetVarDef(s,c);
     Result := Result + sLineBreak + PreprocessVarDefine(df,varmgr);
   end;
end;

function GetProcName(s:string):string;
begin
  Result := Copy(s,1,Pos('(',s)-1);
end;

function PreprocessProc(s:string; varmgr:TVarManager):string;
var
  bf,pn:string;
begin
  pn := GetProcName(Trim(s));
  Result := pn + ':';
  ProcEnterList.Add(pn);
  LocalVarPref := LocalVarPref + pn + '.';
  Delete(s,1,pos('(',s));
  Delete(s,pos(')',s),length(s));
  while length(s)>0 do
   begin
     if pos(',',s)>0 then
      begin
        s := Trim(s);
        bf := Copy(s,1,pos(',',s)-1);
        Delete(s,1,pos(',',s));
      end
     else
      begin
        bf := Trim(s);
        s := '';
      end;
     if IsVar(bf) then
      begin
        if bf[2] <> '.' then
         AsmWarn('Receiving control of global variable "'+bf+'" in proc "'+pn+'".');
        if varmgr.DefinedVars.IndexOf(bf) = -1 then
         begin
           if bf[2] <> '.' then
            begin
              Delete(bf,1,1);
              varmgr.DefVar(bf);
              bf := '$' + bf;
            end
           else
            begin
              Delete(bf,1,2);
              varmgr.DefVar(LocalVarPref+bf);
              bf := '$' + LocalVarPref + bf;
            end
         end;
        Result := Result + sLineBreak + PreprocessVarAction(bf,'peek',varmgr) + sLineBreak + 'pop';
      end
     else
      AsmError('Invalid proc "'+pn+'" define.');
   end;
end;

function tkpos(tk, s:string):cardinal;
var
  R:Cardinal;
begin
  Result := 0;
  R := 0;
  while Length(s)>0 do
   begin
     if s[1] = '"' then
      begin
        delete(s,1,1);
        inc(R,Pos('"',s)+1);
        delete(s,1,pos('"',s));
      end;
     if pos(tk,s) = 1 then
      begin
       inc(R);
       Result := R;
       break
      end;
     delete(s,1,1);
     inc(R);
   end;
end;

function PreprocessCall(s:string; varmgr:TVarManager):string;
var
  bf,pn:string;
  cnt:word;
begin
  Result := '';
  pn := GetProcName(Trim(s));
  Delete(s,1,pos('(',s));
  Delete(s,tkpos(')',s),length(s));
  cnt := 0;
  while length(s)>0 do
   begin
     bf := '';
     if pos(',',s)>0 then
      begin
        s := Trim(ReverseString(s));
        bf := Trim(ReverseString(Copy(s,1,pos(',',s)-1)));
        Delete(s,1,pos(',',s));
        s := Trim(ReverseString(s));
      end
     else
      begin
        bf := Trim(s);
        s := '';
      end;
     if IsVar(bf) then
      Result := Result + sLineBreak + PreprocessVarAction(bf,'push',varmgr)
     else
     if IsConst(bf) then
      Result := Result + sLineBreak + 'pushc ' + GetConst(bf) + sLineBreak + 'gpm'
     else
     if IsArr(bf) then
      Result := Result + sLineBreak + PreprocessArrAction(bf,'pushai',varmgr)
     else
      AsmError('Invalid call "'+pn+'".');
     inc(cnt);
   end;
end;

function PreprocessStr(s:string; varmgr:TVarManager):string;
var
  sl:TStringList;
  c:cardinal;
  s1:string;
begin
  Result := '';
  {** Include **}
  if Tk(s,1) = 'uses' then
   begin
     delete(s,1,length('uses'));
     s := Trim(s);
     case s[1] of
      '"':begin
            delete(s,1,1);
            if pos('"',s)<>Length(s) then
             AsmError('Invalid construction: "uses "'+s+'".');
            delete(s,length(s),1);
            s := ExtractFilePath(ParamStr(1)) + s;
            if not FileExists(s) then
             AsmError('File "'+s+'" not found.');
            sl := TStringList.Create;
            sl.LoadFromFile(s);
            if sl.Count>0 then
             begin
               for c := 0 to sl.Count-1 do
                sl[c] := TrimCodeStr(sl[c]);
               for c := 0 to sl.Count-1 do
                sl[c] := PreprocessStr(sl[c], varmgr);
               for c:=sl.count-1 downto 0 do
                if trim(sl[c])='' then sl.delete(c);
             end;
            Result := sl.Text + sLineBreak;
            FreeAndNil(sl);
          end;
      '<':begin
            delete(s,1,1);
            if pos('>',s)<>Length(s) then
             AsmError('Invalid construction: "uses <'+s+'".');
            delete(s,length(s),1);
            s := ExtractFilePath(ParamStr(0)) + 'inc\' + s;
            if not FileExists(s) then
             AsmError('File "'+s+'" not found.');
            if IncludedFiles.IndexOf(s) = -1 then
             begin
               IncludedFiles.Add(s);
               sl := TStringList.Create;
               sl.LoadFromFile(s);
               if sl.Count>0 then
                begin
                  for c := 0 to sl.Count-1 do
                   sl[c] := TrimCodeStr(sl[c]);
                  for c := 0 to sl.Count-1 do
                   sl[c] := PreprocessStr(sl[c], varmgr);
                  for c:=sl.count-1 downto 0 do
                   if trim(sl[c])='' then sl.delete(c);
                end;
               Result := sl.Text + sLineBreak;
               FreeAndNil(sl);
             end;
          end;
      else
        AsmError('Invalid construction: "uses '+s+'".');
     end;
   end
  else
  {** RegAPI **}
  if Tk(s,1) = 'regapi' then
   begin
     delete(s,1,length('regapi'));
     s := Trim(s);
     Result := 'word '+s+IntToStr(RgAPICnt);
     Inc(RgAPICnt);
   end
  else
  {** Var **}
  if Tk(s,1) = 'var' then
   begin
     delete(s,1,length('var'));
     s := Trim(s);
     Result := PreprocessVarDefines(s,varmgr);
   end
  else
  {** Proc **}
  if Tk(s,1) = 'proc' then
   begin
     delete(s,1,length('proc'));
     s := Trim(s);
     Result := PreprocessProc(s,varmgr);
   end
  else
  {** Endp **}
  if Tk(s,1) = 'endp' then
   begin
     delete(s,1,length('endp'));
     s := ProcEnterList[ProcEnterList.Count-1]+'.';
     if ProcEnterList.Count > 0 then
      begin
       if Pos(s,LocalVarPref) > 0 then
        Delete(LocalVarPref, Pos(s,LocalVarPref), Length(s));
      end
     else
      AsmError('Invalid endp ...');
     Result := 'jr';
   end
  else
  if Tk(s,1) = 'super' then
   begin
     Result := 'pushc super.'+Tk(s,2)+sLineBreak+'gpm'+sLineBreak+'jc';
   end
  else
  if Tk(s,1) = 'store' then
   begin
     delete(s,1,length('store'));
     s := Trim(s);
     if s = '!null' then
      Result := 'pushn'
     else
     if IsVar(s) then
      Result := PreprocessVarAction(s,'push',varmgr)
     else
     if IsConst(s) then
      Result := 'pushc '+GetConst(s)
     else
     if IsArr(s) then
      Result := PreprocessArrAction(s,'pushai',varmgr)
     else
      AsmError('Invalid store operation with "'+s+'".');
     Result := Result + sLineBreak +
               'pushc store' + sLineBreak +
               'gpm' + sLineBreak +
               'jc';
   end
  else
  if Tk(s,1) = 'load' then
   begin
     delete(s,1,length('load'));
     s := Trim(s);
     if s = '!null' then
      AsmError('Invalid load operation with null.')
     else
     if IsVar(s) then
      Result := Result + sLineBreak + PreprocessVarAction(s,'push',varmgr)
     else
     if IsConst(s) then
      AsmError('Invalid load operation with constant "'+s+'".')
     else
     if IsArr(s) then
      Result := Result + sLineBreak + PreprocessArrAction(s,'pushai',varmgr)
     else
      AsmError('Invalid load operation with "'+s+'".');
     Result := Result + sLineBreak +
               'pushc load' + sLineBreak +
               'gpm' + sLineBreak +
               'jc';
   end
  else
  {** Anything **}
  if (pos('$',s)>0) or (pos('!',s)>0) or (pos(',',s)>0) or (pos('.',s)>0) or (pos(' ',s)>0) then
   begin
     // push $a
     // push $a[expr 1][expr 2]..[expr n]
     if Tk(s,1) = 'push' then
      begin
        delete(s,1,length('push'));
        s := Trim(s);
        if s = '!null' then
         Result := 'pushn'
        else
        if IsVar(s) then
         Result := PreprocessVarAction(s,'push',varmgr)
        else
        if IsConst(s) then
         Result := 'pushc '+GetConst(s)
        else
        if IsArr(s) then
         Result := PreprocessArrAction(s,'pushai',varmgr);
      end
     else
     if Tk(s,1) = 'call' then
      begin
        delete(s,1,length('call'));
        if pos('(',s)>0 then
         begin
           Result := PreprocessCall(s,varmgr);
           s := GetProcName(Trim(s));
         end;
        s := Trim(s);
        if IsVar(s) then
         Result := PreprocessVarAction(s,'push',varmgr)
        else
        if IsConst(s) then
         Result := Result + sLineBreak + 'pushc ' + GetConst(s) + sLineBreak + 'gpm'
        else
        if IsArr(s) then
         Result := PreprocessArrAction(s,'pushai',varmgr)
        else
         AsmError('Invalid call "'+s+'".');
        Result :=Result + sLineBreak + 'jc';
      end
     else
     if Tk(s,1) = 'invoke' then
      begin
        delete(s,1,length('invoke'));
        if pos('(',s)>0 then
         begin
           Result := PreprocessCall(s,varmgr);
           s := GetProcName(Trim(s));
         end;
        s := Trim(s);
        if IsVar(s) then
         Result := PreprocessVarAction(s,'push',varmgr)
        else
        if IsConst(s) then
         Result := Result + sLineBreak + 'pushc ' + GetConst(s) + sLineBreak + 'gpm'
        else
        if IsArr(s) then
         Result := PreprocessArrAction(s,'pushai',varmgr)
        else
         AsmError('Invalid call "'+s+'".');
        Result :=Result + sLineBreak + 'invoke';
      end
     else
     if Tk(s,1) = 'jump' then
      begin
        delete(s,1,length('jump'));
        if pos('(',s)>0 then
         begin
           Result := PreprocessCall(s,varmgr);
           s := GetProcName(Trim(s));
         end;
        s := Trim(s);
        if IsVar(s) then
         Result := PreprocessVarAction(s,'push',varmgr)
        else
        if IsConst(s) then
         Result := Result + sLineBreak + 'pushc ' + GetConst(s) + sLineBreak + 'gpm'
        else
        if IsArr(s) then
         Result := PreprocessArrAction(s,'pushai',varmgr)
        else
         AsmError('Invalid call "'+s+'".');
        Result :=Result + sLineBreak + 'jp';
      end
     else
     if Tk(s,1) = 'try' then
      begin
        delete(s,1,length('try'));
        s := Trim(s);
        if pos(',',s)>0 then
         begin
           s1 := copy(s,1,pos(',',s)-1);
           if IsVar(s1) then
            Result := PreprocessVarAction(s1,'push',varmgr)
           else
           if IsConst(s1) then
            Result := Result + sLineBreak + 'pushc '+GetConst(s1)+sLineBreak+'gpm'
           else
           if IsArr(s1) then
            Result := PreprocessArrAction(s1,'pushai',varmgr)
           else
            AsmError('Try operation -> "'+s1+'".');
           Delete(s,1,pos(',',s));
           s := Trim(s);
           if IsVar(s) then
            Result := Result + sLineBreak + PreprocessVarAction(s,'push',varmgr)
           else
           if IsConst(s) then
            Result := Result + sLineBreak + 'pushc '+GetConst(s)+sLineBreak+'gpm'
           else
           if IsArr(s) then
            Result := Result + sLineBreak + PreprocessArrAction(s,'pushai',varmgr)
           else
            AsmError('Try operation -> "'+s+'".');
           Result := Result + sLineBreak + 'swp';
           Result := Result + sLineBreak + 'tr';
         end
        else
        if s = 'end' then
         Result := 'trs'
        else
         AsmError('Try operation -> "try '+s+'"');
      end
     else
     if Tk(s,1) = 'raise' then
      begin
        delete(s,1,length('push'));
        s := Trim(s);
        if s = '!null' then
         Result := 'pushn'
        else
        if IsVar(s) then
         Result := PreprocessVarAction(s,'push',varmgr)
        else
        if IsConst(s) then
         Result := 'pushc '+GetConst(s)
        else
        if IsArr(s) then
         Result := PreprocessArrAction(s,'pushai',varmgr);
        Result := Result + 'trr';
      end
     else
     if Tk(s,1) = 'jz' then
      begin
        delete(s,1,length('jz'));
        if pos('(',s)>0 then
         begin
           Result := PreprocessCall(s,varmgr);
           s := GetProcName(Trim(s));
         end;
        s := Trim(s);
        if IsVar(s) then
         Result := PreprocessVarAction(s,'push',varmgr)
        else
        if IsConst(s) then
         Result := Result + sLineBreak + 'pushc ' + GetConst(s) + sLineBreak + 'gpm'
        else
        if IsArr(s) then
         Result := PreprocessArrAction(s,'pushai',varmgr)
        else
         AsmError('Invalid call "'+s+'".');
        Result :=Result + sLineBreak + 'swp';
        Result :=Result + sLineBreak + 'jz';
        Result :=Result + sLineBreak + 'pop';
      end
     else
     if Tk(s,1) = 'jn' then
      begin
        delete(s,1,length('jn'));
        if pos('(',s)>0 then
         begin
           Result := PreprocessCall(s,varmgr);
           s := GetProcName(Trim(s));
         end;
        s := Trim(s);
        if IsVar(s) then
         Result := PreprocessVarAction(s,'push',varmgr)
        else
        if IsConst(s) then
         Result := Result + sLineBreak + 'pushc ' + GetConst(s) + sLineBreak + 'gpm'
        else
        if IsArr(s) then
         Result := PreprocessArrAction(s,'pushai',varmgr)
        else
         AsmError('Invalid call "'+s+'".');
        Result :=Result + sLineBreak + 'swp';
        Result :=Result + sLineBreak + 'jn';
        Result :=Result + sLineBreak + 'pop';
      end
     else
     if Tk(s,1) = 'peek' then
      begin
        delete(s,1,length('peek'));
        s := Trim(s);
        if IsVar(s) then
         Result := PreprocessVarAction(s,'peek',varmgr)
        else
        if IsConst(s) then
         AsmError('Peek in constant value "'+s+'".')
        else
        if IsArr(s) then
         Result := PreprocessArrAction(s,'peekai',varmgr)
        else
         AsmError('Peek in "'+s+'"');
      end
     else
     if Tk(s,1) = 'pop' then
      begin
        delete(s,1,length('pop'));
        s := Trim(s);
        if IsVar(s) then
         Result := PreprocessVarAction(s,'peek',varmgr)
        else
        if IsConst(s) then
         AsmError('Pop in constant value "'+s+'".')
        else
        if IsArr(s) then
         Result := PreprocessArrAction(s,'peekai',varmgr)
        else
         AsmError('Pop in "'+s+'"');
        Result := Result + sLineBreak + 'pop';
      end
     else
     if Tk(s,1) = 'new' then
      begin
        delete(s,1,length('new'));
        s := Trim(s);
        Result := 'new';
        if IsVar(s) then
         Result := Result + sLineBreak + PreprocessVarAction(s,'peek',varmgr)
        else
        if IsConst(s) then
         AsmError('Allocate memory and peek it in constant value "'+s+'".')
        else
        if IsArr(s) then
         Result := Result + sLineBreak + PreprocessArrAction(s,'peekai',varmgr)
        else
         AsmError('New "'+s+'"');
        Result := Result + sLineBreak + 'pop';
      end
     else
     if Tk(s,1) = 'gpm' then
      begin
        delete(s,1,length('gpm'));
        s := Trim(s);
        if IsVar(s) then
         Result := PreprocessVarAction(s,'push',varmgr)
        else
        if IsConst(s) then
         AsmError('Trying to mark constant value as waste "'+s+'".')
        else
        if IsArr(s) then
         Result := PreprocessArrAction(s,'pushai',varmgr)
        else
         AsmError('Gpm "'+s+'"');
        Result := Result + sLineBreak + 'gpm';
        Result := Result + sLineBreak + 'pop';
      end
     else
     if Tk(s,1) = 'rem' then
      begin
        delete(s,1,length('rem'));
        s := Trim(s);
        if IsVar(s) then
         Result := PreprocessVarAction(s,'push',varmgr)
        else
        if IsConst(s) then
         AsmError('Trying to free memory from constant value "'+s+'".')
        else
        if IsArr(s) then
         Result := PreprocessArrAction(s,'pushai',varmgr)
        else
         AsmError('Rem "'+s+'"');
        Result := Result + sLineBreak + 'rem';
      end
     else
     if Tk(s,1) = 'neg' then
      begin
        delete(s,1,length('neg'));
        s := Trim(s);
        if IsVar(s) then
         Result := PreprocessVarAction(s,'push',varmgr)
        else
        if IsConst(s) then
         AsmError('Neg constant value "'+s+'".')
        else
        if IsArr(s) then
         Result := PreprocessArrAction(s,'pushai',varmgr)
        else
         AsmError('Neg "'+s+'"');
        Result := Result + sLineBreak + 'neg';
        Result := Result + sLineBreak + 'pop';
      end
     else
     if Tk(s,1) = 'inc' then
      begin
        delete(s,1,length('inc'));
        s := Trim(s);
        if IsVar(s) then
         Result := PreprocessVarAction(s,'push',varmgr)
        else
        if IsConst(s) then
         AsmError('Inc constant value "'+s+'".')
        else
        if IsArr(s) then
         Result := PreprocessArrAction(s,'pushai',varmgr)
        else
         AsmError('Inc "'+s+'"');
        Result := Result + sLineBreak + 'inc';
        Result := Result + sLineBreak + 'pop';
      end
     else
     if Tk(s,1) = 'dec' then
      begin
        delete(s,1,length('dec'));
        s := Trim(s);
        if IsVar(s) then
         Result := PreprocessVarAction(s,'push',varmgr)
        else
        if IsConst(s) then
         AsmError('Dec constant value "'+s+'".')
        else
        if IsArr(s) then
         Result := PreprocessArrAction(s,'pushai',varmgr)
        else
         AsmError('Dec "'+s+'"');
        Result := Result + sLineBreak + 'dec';
        Result := Result + sLineBreak + 'pop';
      end
     else
     if Tk(s,1) = 'add' then
      begin
        delete(s,1,length('add'));
        s := Trim(s);
        if pos(',',s)>0 then
         begin
           s1 := copy(s,1,pos(',',s)-1);
           if IsVar(s1) then
            Result := PreprocessVarAction(s1,'push',varmgr)
           else
           if IsConst(s1) then
            AsmError('Add operation not intended to constants -> "'+s1+'"')
           else
           if IsArr(s1) then
            Result := PreprocessArrAction(s1,'pushai',varmgr)
           else
            AsmError('Add operation -> "'+s1+'".');
           Delete(s,1,pos(',',s));
           s := Trim(s);
           if IsVar(s) then
            Result := Result + sLineBreak + PreprocessVarAction(s,'push',varmgr)
           else
           if IsConst(s) then
            Result := Result + sLineBreak + 'pushc '+GetConst(s)+sLineBreak+'gpm'
           else
           if IsArr(s) then
            Result := Result + sLineBreak + PreprocessArrAction(s,'pushai',varmgr)
           else
            AsmError('Add operation -> "'+s+'".');
           Result := Result + sLineBreak + 'swp';
           Result := Result + sLineBreak + 'add';
           Result := Result + sLineBreak + 'pop';
         end;
      end
     else
     if Tk(s,1) = 'eq' then
      begin
        delete(s,1,length('eq'));
        s := Trim(s);
        if pos(',',s)>0 then
         begin
           s1 := copy(s,1,pos(',',s)-1);
           if IsVar(s1) then
            Result := PreprocessVarAction(s1,'push',varmgr)
           else
           if IsConst(s1) then
            Result := Result + sLineBreak + 'pushc '+GetConst(s1)+sLineBreak+'gpm'
           else
           if IsArr(s1) then
            Result := PreprocessArrAction(s1,'pushai',varmgr)
           else
            AsmError('Eq operation -> "'+s1+'".');
           Delete(s,1,pos(',',s));
           s := Trim(s);
           if IsVar(s) then
            Result := Result + sLineBreak + PreprocessVarAction(s,'push',varmgr)
           else
           if IsConst(s) then
            Result := Result + sLineBreak + 'pushc '+GetConst(s)+sLineBreak+'gpm'
           else
           if IsArr(s) then
            Result := Result + sLineBreak + PreprocessArrAction(s,'pushai',varmgr)
           else
            AsmError('Eq operation -> "'+s+'".');
           Result := Result + sLineBreak + 'swp';
           Result := Result + sLineBreak + 'eq';
           Result := Result + sLineBreak + 'gpm';
         end;
      end
     else
     if Tk(s,1) = 'bg' then
      begin
        delete(s,1,length('bg'));
        s := Trim(s);
        if pos(',',s)>0 then
         begin
           s1 := copy(s,1,pos(',',s)-1);
           if IsVar(s1) then
            Result := PreprocessVarAction(s1,'push',varmgr)
           else
           if IsConst(s1) then
            Result := Result + sLineBreak + 'pushc '+GetConst(s1)+sLineBreak+'gpm'
           else
           if IsArr(s1) then
            Result := PreprocessArrAction(s1,'pushai',varmgr)
           else
            AsmError('Bg operation -> "'+s1+'".');
           Delete(s,1,pos(',',s));
           s := Trim(s);
           if IsVar(s) then
            Result := Result + sLineBreak + PreprocessVarAction(s,'push',varmgr)
           else
           if IsConst(s) then
            Result := Result + sLineBreak + 'pushc '+GetConst(s)+sLineBreak+'gpm'
           else
           if IsArr(s) then
            Result := Result + sLineBreak + PreprocessArrAction(s,'pushai',varmgr)
           else
            AsmError('Eq operation -> "'+s+'".');
           Result := Result + sLineBreak + 'swp';
           Result := Result + sLineBreak + 'bg';
           Result := Result + sLineBreak + 'gpm';
         end;
      end
     else
     if Tk(s,1) = 'be' then
      begin
        delete(s,1,length('be'));
        s := Trim(s);
        if pos(',',s)>0 then
         begin
           s1 := copy(s,1,pos(',',s)-1);
           if IsVar(s1) then
            Result := PreprocessVarAction(s1,'push',varmgr)
           else
           if IsConst(s1) then
            Result := Result + sLineBreak + 'pushc '+GetConst(s1)+sLineBreak+'gpm'
           else
           if IsArr(s1) then
            Result := PreprocessArrAction(s1,'pushai',varmgr)
           else
            AsmError('Be operation -> "'+s1+'".');
           Delete(s,1,pos(',',s));
           s := Trim(s);
           if IsVar(s) then
            Result := Result + sLineBreak + PreprocessVarAction(s,'push',varmgr)
           else
           if IsConst(s) then
            Result := Result + sLineBreak + 'pushc '+GetConst(s)+sLineBreak+'gpm'
           else
           if IsArr(s) then
            Result := Result + sLineBreak + PreprocessArrAction(s,'pushai',varmgr)
           else
            AsmError('Eq operation -> "'+s+'".');
           Result := Result + sLineBreak + 'swp';
           Result := Result + sLineBreak + 'be';
           Result := Result + sLineBreak + 'gpm';
         end;
      end
     else
     if Tk(s,1) = 'sub' then
      begin
        delete(s,1,length('sub'));
        s := Trim(s);
        if pos(',',s)>0 then
         begin
           s1 := copy(s,1,pos(',',s)-1);
           if IsVar(s1) then
            Result := PreprocessVarAction(s1,'push',varmgr)
           else
           if IsConst(s1) then
            AsmError('Sub operation not intended to constants -> "'+s1+'"')
           else
           if IsArr(s1) then
            Result := PreprocessArrAction(s1,'pushai',varmgr)
           else
            AsmError('Sub operation -> "'+s1+'".');
           Delete(s,1,pos(',',s));
           s := Trim(s);
           if IsVar(s) then
            Result := Result + sLineBreak + PreprocessVarAction(s,'push',varmgr)
           else
           if IsConst(s) then
            Result := Result + sLineBreak + 'pushc '+GetConst(s)+sLineBreak+'gpm'
           else
           if IsArr(s) then
            Result := Result + sLineBreak + PreprocessArrAction(s,'pushai',varmgr)
           else
            AsmError('Sub operation -> "'+s+'".');
           Result := Result + sLineBreak + 'swp';
           Result := Result + sLineBreak + 'sub';
           Result := Result + sLineBreak + 'pop';
         end;
      end
     else
     if Tk(s,1) = 'mul' then
      begin
        delete(s,1,length('mul'));
        s := Trim(s);
        if pos(',',s)>0 then
         begin
           s1 := copy(s,1,pos(',',s)-1);
           if IsVar(s1) then
            Result := PreprocessVarAction(s1,'push',varmgr)
           else
           if IsConst(s1) then
            AsmError('Mul operation not intended to constants -> "'+s1+'"')
           else
           if IsArr(s1) then
            Result := PreprocessArrAction(s1,'pushai',varmgr)
           else
            AsmError('Mul operation -> "'+s1+'".');
           Delete(s,1,pos(',',s));
           s := Trim(s);
           if IsVar(s) then
            Result := Result + sLineBreak + PreprocessVarAction(s,'push',varmgr)
           else
           if IsConst(s) then
            Result := Result + sLineBreak + 'pushc '+GetConst(s)+sLineBreak+'gpm'
           else
           if IsArr(s) then
            Result := Result + sLineBreak + PreprocessArrAction(s,'pushai',varmgr)
           else
            AsmError('Mul operation -> "'+s+'".');
           Result := Result + sLineBreak + 'swp';
           Result := Result + sLineBreak + 'mul';
           Result := Result + sLineBreak + 'pop';
         end;
      end
     else
     if Tk(s,1) = 'div' then
      begin
        delete(s,1,length('div'));
        s := Trim(s);
        if pos(',',s)>0 then
         begin
           s1 := copy(s,1,pos(',',s)-1);
           if IsVar(s1) then
            Result := PreprocessVarAction(s1,'push',varmgr)
           else
           if IsConst(s1) then
            AsmError('Div operation not intended to constants -> "'+s1+'"')
           else
           if IsArr(s1) then
            Result := PreprocessArrAction(s1,'pushai',varmgr)
           else
            AsmError('Div operation -> "'+s1+'".');
           Delete(s,1,pos(',',s));
           s := Trim(s);
           if IsVar(s) then
            Result := Result + sLineBreak + PreprocessVarAction(s,'push',varmgr)
           else
           if IsConst(s) then
            Result := Result + sLineBreak + 'pushc '+GetConst(s)+sLineBreak+'gpm'
           else
           if IsArr(s) then
            Result := Result + sLineBreak + PreprocessArrAction(s,'pushai',varmgr)
           else
            AsmError('Div operation -> "'+s+'".');
           Result := Result + sLineBreak + 'swp';
           Result := Result + sLineBreak + 'div';
           Result := Result + sLineBreak + 'pop';
         end;
      end
     else
     if Tk(s,1) = 'mod' then
      begin
        delete(s,1,length('mod'));
        s := Trim(s);
        if pos(',',s)>0 then
         begin
           s1 := copy(s,1,pos(',',s)-1);
           if IsVar(s1) then
            Result := PreprocessVarAction(s1,'push',varmgr)
           else
           if IsConst(s1) then
            AsmError('Mod operation not intended to constants -> "'+s1+'"')
           else
           if IsArr(s1) then
            Result := PreprocessArrAction(s1,'pushai',varmgr)
           else
            AsmError('Mod operation -> "'+s1+'".');
           Delete(s,1,pos(',',s));
           s := Trim(s);
           if IsVar(s) then
            Result := Result + sLineBreak + PreprocessVarAction(s,'push',varmgr)
           else
           if IsConst(s) then
            Result := Result + sLineBreak + 'pushc '+GetConst(s)+sLineBreak+'gpm'
           else
           if IsArr(s) then
            Result := Result + sLineBreak + PreprocessArrAction(s,'pushai',varmgr)
           else
            AsmError('Mod operation -> "'+s+'".');
           Result := Result + sLineBreak + 'swp';
           Result := Result + sLineBreak + 'mod';
           Result := Result + sLineBreak + 'pop';
         end;
      end
     else
     if Tk(s,1) = 'idiv' then
      begin
        delete(s,1,length('idiv'));
        s := Trim(s);
        if pos(',',s)>0 then
         begin
           s1 := copy(s,1,pos(',',s)-1);
           if IsVar(s1) then
            Result := PreprocessVarAction(s1,'push',varmgr)
           else
           if IsConst(s1) then
            AsmError('Idiv operation not intended to constants -> "'+s1+'"')
           else
           if IsArr(s1) then
            Result := PreprocessArrAction(s1,'pushai',varmgr)
           else
            AsmError('Idiv operation -> "'+s1+'".');
           Delete(s,1,pos(',',s));
           s := Trim(s);
           if IsVar(s) then
            Result := Result + sLineBreak + PreprocessVarAction(s,'push',varmgr)
           else
           if IsConst(s) then
            Result := Result + sLineBreak + 'pushc '+GetConst(s)+sLineBreak+'gpm'
           else
           if IsArr(s) then
            Result := Result + sLineBreak + PreprocessArrAction(s,'pushai',varmgr)
           else
            AsmError('Idiv operation -> "'+s+'".');
           Result := Result + sLineBreak + 'swp';
           Result := Result + sLineBreak + 'idiv';
           Result := Result + sLineBreak + 'pop';
         end;
      end
     else
     if Tk(s,1) = 'mov' then
      begin
        delete(s,1,length('mov'));
        s := Trim(s);
        if pos(',',s)>0 then
         begin
           s1 := copy(s,1,pos(',',s)-1);
           if IsVar(s1) then
            Result := PreprocessVarAction(s1,'push',varmgr)
           else
           if IsConst(s1) then
            AsmError('Mov operation not intended to constants -> "'+s1+'"')
           else
           if IsArr(s1) then
            Result := PreprocessArrAction(s1,'pushai',varmgr)
           else
            AsmError('Mov operation -> "'+s1+'".');
           Delete(s,1,pos(',',s));
           s := Trim(s);
           if IsVar(s) then
            Result := Result + sLineBreak + PreprocessVarAction(s,'push',varmgr)
           else
           if IsConst(s) then
            Result := Result + sLineBreak + 'pushc '+GetConst(s)+sLineBreak+'gpm'
           else
           if IsArr(s) then
            Result := Result + sLineBreak + PreprocessArrAction(s,'pushai',varmgr)
           else
            AsmError('Mov operation -> "'+s+'".');
           Result := Result + sLineBreak + 'swp';
           Result := Result + sLineBreak + 'mov';
         end;
      end
     else
     if Tk(s,1) = 'movl' then
      begin
        delete(s,1,length('movl'));
        s := Trim(s);
        if pos(',',s)>0 then
         begin
           s1 := copy(s,1,pos(',',s)-1);
           Delete(s,1,pos(',',s));
           s := Trim(s);
           if IsVar(s) then
            Result := PreprocessVarAction(s,'push',varmgr)
           else
           if IsConst(s) then
            AsmError('Movl operation not intended to constants -> "'+s+'"')
           else
           if IsArr(s) then
            Result := PreprocessArrAction(s,'pushai',varmgr)
           else
            AsmError('Movl operation -> "'+s1+'".');
           if IsVar(s1) then
            Result := Result + sLineBreak + PreprocessVarAction(s1,'peek',varmgr)
           else
           if IsConst(s1) then
            AsmError('Movl operation not intended to constants -> "'+s1+'"')
           else
           if IsArr(s1) then
            Result := Result + sLineBreak + PreprocessArrAction(s1,'peekai',varmgr)
           else
            AsmError('Movl operation -> "'+s1+'".');
           Result := Result + sLineBreak + 'pop';
         end;
      end
     else
     if Tk(s,1) = 'not' then
      begin
        delete(s,1,length('not'));
        s := Trim(s);
        if IsVar(s) then
         Result := PreprocessVarAction(s,'push',varmgr)
        else
        if IsConst(s) then
         AsmError('Not constant value "'+s+'".')
        else
        if IsArr(s) then
         Result := PreprocessArrAction(s,'pushai',varmgr)
        else
         AsmError('Not "'+s+'"');
        Result := Result + sLineBreak + 'not';
        Result := Result + sLineBreak + 'pop';
      end
     else
     if Tk(s,1) = 'and' then
      begin
        delete(s,1,length('and'));
        s := Trim(s);
        if pos(',',s)>0 then
         begin
           s1 := copy(s,1,pos(',',s)-1);
           if IsVar(s1) then
            Result := PreprocessVarAction(s1,'push',varmgr)
           else
           if IsConst(s1) then
            AsmError('And operation not intended to constants -> "'+s1+'"')
           else
           if IsArr(s1) then
            Result := PreprocessArrAction(s1,'pushai',varmgr)
           else
            AsmError('And operation -> "'+s1+'".');
           Delete(s,1,pos(',',s));
           s := Trim(s);
           if IsVar(s) then
            Result := Result + sLineBreak + PreprocessVarAction(s,'push',varmgr)
           else
           if IsConst(s) then
            Result := Result + sLineBreak + 'pushc '+GetConst(s)+sLineBreak+'gpm'
           else
           if IsArr(s) then
            Result := Result + sLineBreak + PreprocessArrAction(s,'pushai',varmgr)
           else
            AsmError('And operation -> "'+s+'".');
           Result := Result + sLineBreak + 'swp';
           Result := Result + sLineBreak + 'and';
         end;
      end
     else
     if Tk(s,1) = 'or' then
      begin
        delete(s,1,length('or'));
        s := Trim(s);
        if pos(',',s)>0 then
         begin
           s1 := copy(s,1,pos(',',s)-1);
           if IsVar(s1) then
            Result := PreprocessVarAction(s1,'push',varmgr)
           else
           if IsConst(s1) then
            AsmError('Or operation not intended to constants -> "'+s1+'"')
           else
           if IsArr(s1) then
            Result := PreprocessArrAction(s1,'pushai',varmgr)
           else
            AsmError('Or operation -> "'+s1+'".');
           Delete(s,1,pos(',',s));
           s := Trim(s);
           if IsVar(s) then
            Result := Result + sLineBreak + PreprocessVarAction(s,'push',varmgr)
           else
           if IsConst(s) then
            Result := Result + sLineBreak + 'pushc '+GetConst(s)+sLineBreak+'gpm'
           else
           if IsArr(s) then
            Result := Result + sLineBreak + PreprocessArrAction(s,'pushai',varmgr)
           else
            AsmError('Or operation -> "'+s+'".');
           Result := Result + sLineBreak + 'swp';
           Result := Result + sLineBreak + 'or';
         end;
      end
     else
     if Tk(s,1) = 'xor' then
      begin
        delete(s,1,length('xor'));
        s := Trim(s);
        if pos(',',s)>0 then
         begin
           s1 := copy(s,1,pos(',',s)-1);
           if IsVar(s1) then
            Result := PreprocessVarAction(s1,'push',varmgr)
           else
           if IsConst(s1) then
            AsmError('Xor operation not intended to constants -> "'+s1+'"')
           else
           if IsArr(s1) then
            Result := PreprocessArrAction(s1,'pushai',varmgr)
           else
            AsmError('Xor operation -> "'+s1+'".');
           Delete(s,1,pos(',',s));
           s := Trim(s);
           if IsVar(s) then
            Result := Result + sLineBreak + PreprocessVarAction(s,'push',varmgr)
           else
           if IsConst(s) then
            Result := Result + sLineBreak + 'pushc '+GetConst(s)+sLineBreak+'gpm'
           else
           if IsArr(s) then
            Result := Result + sLineBreak + PreprocessArrAction(s,'pushai',varmgr)
           else
            AsmError('Xor operation -> "'+s+'".');
           Result := Result + sLineBreak + 'swp';
           Result := Result + sLineBreak + 'xor';
         end;
      end
     else
     if Tk(s,1) = 'shl' then
      begin
        delete(s,1,length('shl'));
        s := Trim(s);
        if pos(',',s)>0 then
         begin
           s1 := copy(s,1,pos(',',s)-1);
           if IsVar(s1) then
            Result := PreprocessVarAction(s1,'push',varmgr)
           else
           if IsConst(s1) then
            AsmError('Shl operation not intended to constants -> "'+s1+'"')
           else
           if IsArr(s1) then
            Result := PreprocessArrAction(s1,'pushai',varmgr)
           else
            AsmError('Shl operation -> "'+s1+'".');
           Delete(s,1,pos(',',s));
           s := Trim(s);
           if IsVar(s) then
            Result := Result + sLineBreak + PreprocessVarAction(s,'push',varmgr)
           else
           if IsConst(s) then
            Result := Result + sLineBreak + 'pushc '+GetConst(s)+sLineBreak+'gpm'
           else
           if IsArr(s) then
            Result := Result + sLineBreak + PreprocessArrAction(s,'pushai',varmgr)
           else
            AsmError('Shl operation -> "'+s+'".');
           Result := Result + sLineBreak + 'swp';
           Result := Result + sLineBreak + 'shl';
         end;
      end
     else
     if Tk(s,1) = 'shr' then
      begin
        delete(s,1,length('shr'));
        s := Trim(s);
        if pos(',',s)>0 then
         begin
           s1 := copy(s,1,pos(',',s)-1);
           if IsVar(s1) then
            Result := PreprocessVarAction(s1,'push',varmgr)
           else
           if IsConst(s1) then
            AsmError('Shr operation not intended to constants -> "'+s1+'"')
           else
           if IsArr(s1) then
            Result := PreprocessArrAction(s1,'pushai',varmgr)
           else
            AsmError('Shr operation -> "'+s1+'".');
           Delete(s,1,pos(',',s));
           s := Trim(s);
           if IsVar(s) then
            Result := Result + sLineBreak + PreprocessVarAction(s,'push',varmgr)
           else
           if IsConst(s) then
            Result := Result + sLineBreak + 'pushc '+GetConst(s)+sLineBreak+'gpm'
           else
           if IsArr(s) then
            Result := Result + sLineBreak + PreprocessArrAction(s,'pushai',varmgr)
           else
            AsmError('Shr operation -> "'+s+'".');
           Result := Result + sLineBreak + 'swp';
           Result := Result + sLineBreak + 'shr';
         end;
      end
     else
     Result := s;
   end
  else
   Result := s;
end;

procedure InitPreprocessor;
begin
  ProcEnterList := TStringList.Create;
end;

procedure FreePreprocessor;
begin
  FreeAndNil(ProcEnterList);
end;

{** ImportLibrary **}

constructor TImportLibrary.Create(lpath:string);
begin
  LibraryPath := lpath;
  Imports := TStringList.Create;
  Methods := TStringList.Create;
  inherited Create;
end;

destructor TImportLibrary.Destroy;
begin
  Imports.Free;
  Methods.Free;
  inherited Destroy;
end;

{** ImportSection **}

constructor TImportSection.Create(sl:TStringList);
begin
  Self.Lines := sl;
  Libs := TList.Create;
  inherited Create;
end;

destructor TImportSection.Destroy;
var
  w:word;
begin
  if Libs.Count>0 then
   for w := 0 to Libs.Count-1 do
    TImportLibrary(Libs[w]).Free;
  FreeAndNil(Libs);
  inherited Destroy;
end;

function TImportSection.GetLibIndx(l_path:string):integer;
var
  c:cardinal;
begin
  Result := -1;
  c := 0;
  while c<Libs.Count do
   begin
     if TImportLibrary(Libs[c]).LibraryPath = l_path then
      begin
        Result := c;
        break;
      end;
     inc(c);
   end;
end;

procedure TImportSection.AddMethod(l_path,m_name,exm_name:string);
var
  lb_indx: integer;
begin
  lb_indx := GetLibIndx(l_path);
  if lb_indx<>-1 then
   begin
     with TImportLibrary(Libs[lb_indx]) do
      begin
        if Methods.IndexOf(m_name)<>-1 then
         AsmError('Dublicate import "'+m_name+'", from "'+l_path+'":"'+exm_name+'"');
        Methods.Add(m_name);
        Imports.Add(exm_name);
      end;
   end
  else
   begin
     Libs.Add(TImportLibrary.Create(l_path));
     with TImportLibrary(Libs[Libs.Count-1]) do
      begin
        Methods.Add(m_name);
        Imports.Add(exm_name);
      end;
   end;
end;

procedure TImportSection.ParseSection;
var
  c:cardinal;
begin
  c := 0;
  while c<Lines.Count do
   begin
     if Tk(Lines[c],1) = 'import' then
      begin
        AddMethod(Tk(Lines[c],3),Tk(Lines[c],2),Tk(Lines[c],4));
        Lines[c] := '';
      end;
     inc(c);
   end;
end;

procedure TImportSection.GenerateCode(Stream:TStream);
var
  w,w1:word;
  b:byte;
  c:cardinal;
begin
  w := Libs.Count;
  St_WriteWord(Stream,w);
  if w>0 then
   begin
     for w := 0 to Libs.Count-1 do
      with TImportLibrary(Libs[w]) do
       begin
         w1 := Length(LibraryPath);
         St_WriteWord(Stream,w1);
         Stream.WriteBuffer(LibraryPath[1],w1);
       end;
     c := 0;
     for w := 0 to Libs.Count-1 do
      with TImportLibrary(Libs[w]) do
       begin
         c := c+Imports.Count;
       end;
     St_WriteCardinal(Stream,c);
     for w := 0 to Libs.Count-1 do
      with TImportLibrary(Libs[w]) do
       begin
         if Imports.Count>0 then
          for w1 := 0 to Imports.Count-1 do
           begin
             b := Length(Imports[w1]);
             St_WriteWord(Stream,w);
             Stream.WriteByte(b);
             if b>0 then
              Stream.WriteBuffer(Imports[w1][1],b);
           end;
       end;
   end;
end;

{** Constant **}

constructor TConstant.Create;
begin
 c_value := TMemoryStream.Create;
 c_ismirror := false;
 inherited Create;
end;

destructor TConstant.Destroy;
begin
 c_value.Free;
 inherited Destroy;
end;

procedure TConstant.GenerateCode(Stream:TStream);
begin
  if not c_ismirror then
   case c_type of
    ctUnsigned64:
      begin
        Stream.WriteByte(byte(ctUnsigned64));
        Stream.WriteBuffer(c_value.Memory^,c_value.size);
      end;
    ctInt64:
      begin
        Stream.WriteByte(byte(ctInt64));
        Stream.WriteBuffer(c_value.Memory^,c_value.size);
      end;
    ctDouble:
      begin
        Stream.WriteByte(byte(ctDouble));
        Stream.WriteBuffer(c_value.Memory^,c_value.size);
      end;
    ctString:
      begin
        Stream.WriteByte(byte(ctString));
        St_WriteWord(Stream,c_value.Size);
        Stream.WriteBuffer(c_value.Memory^,c_value.size);
      end;
    ctStream:
      begin
        Stream.WriteByte(byte(ctStream));
        St_WriteCardinal(Stream,c_value.Size);
        Stream.WriteBuffer(c_value.Memory^,c_value.Size);
      end;
   end;
end;

{** ConstantManager **}

constructor TConstantManager.Create(sl:TStringList);
begin
  Lines := sl;
  Constants := TList.Create;
  inherited Create;
end;

destructor TConstantManager.Destroy;
var
  c:cardinal;
begin
  if Constants.Count>0 then
   for c := 0 to Constants.Count-1 do
    TConstant(Constants[c]).Free;
  Constants.Free;
  inherited Destroy;
end;

{function CompareStreams(s1,s2:TMemoryStream):boolean;
var
  c:cardinal;
begin
  Result := False;
  if (s1 <> nil) and (s2 <> nil) then
   if s1.Size = s2.Size then
    if CompareMem(s1.Memory, s2.Memory, s1.Size) then
     Result := True;
end;}

procedure TConstantManager.Add(Cnst:TConstant);
{var
  c:Cardinal;
  Cnst2:TConstant;}
begin
  {c := 0;
  while c<Constants.Count do
   begin
     Cnst2 := TConstant(Constants[c]);
     if Cnst.c_type = Cnst2.c_type then
      if CompareStreams(Cnst.c_value, Cnst2.c_value) then
       begin
         Cnst.c_ismirror := True;
         Cnst.c_originlnk := Cnst2;
         FreeAndNil(Cnst.c_value);
       end;
     inc(c);
   end; }
  Constants.Add(Cnst);
end;

procedure TConstantManager.AddConstCardinal(c_name:string; c:cardinal);
var
  Constant:TConstant;
begin
  Constant := TConstant.Create;
  Constant.c_name := c_name;
  Constant.c_type := ctUnsigned64;
  St_WriteCardinal(Constant.c_value,c);
  Constants.Add(Constant);
end;

function TConstantManager.GetAddr(c_name:string):cardinal;
var
  c:cardinal;
  Cnst:TConstant;
begin
  if pos(sLineBreak,c_name)>0 then
   c_name := copy(c_name,1,pos(slinebreak,c_name)-1);
  if Constants.Count = 0 then
   AsmError('Invalid constant call "'+c_name+'".');
  for c := 0 to Constants.Count-1 do
   begin
     Cnst := TConstant(Constants[c]);
     if Cnst.c_name = c_name then
      begin
        if Cnst.c_ismirror then
         Result := Self.GetAddr(Cnst.c_originlnk.c_name)
        else
         Result := c;
        break;
      end
     else
      if c = Constants.Count-1 then
       AsmError('Invalid constant call "'+c_name+'"');
   end;
end;

procedure TConstantManager.ParseSection;
var
  c:cardinal;
  Constant:TConstant;
begin
  c := 0;
  while c<Lines.Count do
   begin
     if Tk(Lines[c],1) = 'word' then
      begin
        Constant := TConstant.Create;
        Constant.c_name := Tk(Lines[c],2);
        Constant.c_type := ctUnsigned64;
        St_WriteCardinal(Constant.c_value, StrToQWord(Tk(Lines[c],3)));
        Self.Add(Constant);
        Lines[c] := '';
      end
     else
     if Tk(Lines[c],1) = 'int' then
      begin
        Constant := TConstant.Create;
        Constant.c_name := Tk(Lines[c],2);
        Constant.c_type := ctInt64;
        St_WriteInt64(Constant.c_value, StrToInt(Tk(Lines[c],3)));
        Self.Add(Constant);
        Lines[c] := '';
      end
     else
     if Tk(Lines[c],1) = 'real' then
      begin
        Constant := TConstant.Create;
        Constant.c_name := Tk(Lines[c],2);
        Constant.c_type := ctDouble;
        St_WriteDouble(Constant.c_value, Double(StrToFloat(Tk(Lines[c],3))));
        Self.Add(Constant);
        Lines[c] := '';
      end
     else
     if Tk(Lines[c],1) = 'str' then
      begin
        Constant := TConstant.Create;
        Constant.c_name := Tk(Lines[c],2);
        Constant.c_type := ctString;
        Constant.c_value.WriteBuffer(Tk(Lines[c],3)[1],Length(Tk(Lines[c],3)));
        Self.Add(Constant);
        Lines[c] := '';
      end;
     if Tk(Lines[c],1) = 'stream' then
      begin
        Constant := TConstant.Create;
        Constant.c_name := Tk(Lines[c],2);
        Constant.c_type := ctStream;
        Constant.c_value.LoadFromFile(ExtractFilePath(ParamStr(1))+Tk(Lines[c],3));
        Self.Add(Constant);
        Lines[c] := '';
      end;
     inc(c);
   end;
end;

procedure TConstantManager.CheckForDoubles;
var
  s:string;
  c,c2:cardinal;
begin
 if Constants.Count>0 then
   begin
    for c := 0 to Constants.Count-1 do
     begin
      s := TConstant(Constants[c]).c_name;
      if not CheckName(s) then
       AsmError('Invalid name of "'+s+'"');
      c2 := c+1;
      while c2<Constants.Count do
       begin
        if TConstant(Constants[c2]).c_name = s then
         AsmError('Dublicate declaration of "'+s+'"');
        inc(c2);
       end;
     end
   end;
end;

procedure TConstantManager.AppendImports(ImportSection:TImportSection);
var
  w:word;
  c,c2:cardinal;
  Constant:TConstant;
begin
  if ImportSection.Libs.Count>0 then
   begin
     c := 0;
     for w := 0 to ImportSection.Libs.Count-1 do
      begin
        with TImportLibrary(ImportSection.Libs[w]) do
         begin
           if Methods.Count>0 then
             begin
               for c2 := 0 to Methods.Count-1 do
                begin
                  Constant := TConstant.Create;
                  Constant.c_name := Methods[c2];
                  Constant.c_type := ctUnsigned64;
                  St_WriteCardinal(Constant.c_value,c+RgAPICnt);
                  Constants.Add(Constant);
                  inc(c);
                end;
             end;
         end;
      end;
   end;
end;

procedure TConstantManager.GenerateCode(Stream:TStream);
var
  c:cardinal;
begin
 St_WriteCardinal(Stream,Constants.Count);
 if Constants.Count>0 then
  for c := 0 to Constants.Count-1 do
   TConstant(Constants[c]).GenerateCode(Stream);
end;

{** Variables **}

constructor TVarManager.Create;
begin
 DefinedVars := TStringList.Create;
 inherited Create;
end;

destructor TVarManager.Destroy;
begin
 FreeAndNil(DefinedVars);
 inherited Destroy;
end;

procedure TVarManager.DefVar(name:string);
begin
 if not CheckName(name) then
  AsmError('Invalid variable name "'+name+'".');
 if DefinedVars.IndexOf(name) = -1 then
  DefinedVars.Add(name)
 {else
  AsmError('Trying to redefine variable "'+name+'".');}
end;

function TVarManager.Get(name:string):cardinal;
begin
 Result := DefinedVars.IndexOf(name);
 if Result = -1 then
  AsmError('Invalid variable call "'+name+'".');
end;

{** Code section **}

constructor TCodeSection.Create(sl:TStringList; cnsts:TConstantManager);
begin
  Outp := TMemoryStream.Create;
  Lines := sl;
  Constants := cnsts;
  inherited Create;
end;

destructor TCodeSection.Destroy;
begin
  Outp.Free;
  inherited Destroy;
end;

type TComand = (
    bcPH,     // [top] = [var]
    bcPK,     // [var] = [top]
    bcPP,     // pop
    bcSDP,    // stkdrop
    bcSWP,    // [top] <-> [top-1]
    bcJP,     // jump [top]
    bcJZ,     // [top] == 0 ? jp [top-1]
    bcJN,     // [top] <> 0 ? jp [top-1]
    bcJC,     // jp [top] & push callback point as ip+1
    bcJR,     // jp to last callback point & rem last callback point

    bcEQ,     // [top] == [top-1] ? [top] = 1 : [top] = 0
    bcBG,     // [top] >  [top-1] ? [top] = 1 : [top] = 0
    bcBE,     // [top] >= [top-1] ? [top] = 1 : [top] = 0

    bcNOT,    // [top] = ![top]
    bcAND,    // [top] = [top] and [top-1]
    bcOR,     // [top] = [top] or  [top-1]
    bcXOR,    // [top] = [top] xor [top-1]
    bcSHR,    // [top] = [top] shr [top-1]
    bcSHL,    // [top] = [top] shl [top-1]

    bcNEG,    // [top] = -[top]
    bcINC,    // [top]++
    bcDEC,    // [top]--
    bcADD,    // [top] = [top] + [top-1]
    bcSUB,    // [top] = [top] - [top-1]
    bcMUL,    // [top] = [top] * [top-1]
    bcDIV,    // [top] = [top] / [top-1]
    bcMOD,    // [top] = [top] % [top-1]
    bcIDIV,   // [top] = [top] \ [top-1]

    bcMV,     // [top]^ = [top-1]^
    bcMVBP,   // [top]^^ = [top-1]^
    bcMVP,    // [top]^ = [top-1]

    bcMS,     // memory map size = [top]
    bcNW,     // [top] = @new
    bcMC,     // copy [top]
    bcMD,     // double [top]
    bcRM,     // rem @[top]
    bcNA,     // [top] = @new array[  [top]  ] of pointer
    bcSF,     // sizeof( [top] as object )
    bcAL,     // length( [top] as array )
    bcSL,     // setlength( [top] as array, {stack} )

    bcPA,     // push ([top] as array)[top-1]
    bcSA,     // peek [top-2] -> ([top] as array)[top-1]

    bcGPM,    // add pointer to TMem to grabber task-list
    bcGPA,    // add pointer to TMemArr to grabber task-list
    bcGC,     // run grabber

    bcPHC,    // push const

    bcPHEXMP, // push pointer to external method
    bcINV,    // call external method
    bcINVBP,  // call external method by pointer [top]

    bcPHN,    // push null
    bcCTHR,   // [top] = thread(method = [top], arg = [top+1]):id
    bcSTHR,   // suspendthread(id = [top])
    bcRTHR,   // resumethread(id = [top])
    bcTTHR,   // terminatethread(id = [top])

    bcTR,     // try @block_catch = [top], @block_end = [top+1]
    bcTRS,    // success exit from try/catch block
    bcTRR,    // raise exception, message = [top]

    {** for word's **}
    bcEQ_W,     // [top] == [top-1] ? [top] = 1 : [top] = 0
    bcBG_W,     // [top] >  [top-1] ? [top] = 1 : [top] = 0
    bcBE_W,     // [top] >= [top-1] ? [top] = 1 : [top] = 0

    bcNOT_W,    // [top] = ![top]
    bcAND_W,    // [top] = [top] and [top-1]
    bcOR_W,     // [top] = [top] or  [top-1]
    bcXOR_W,    // [top] = [top] xor [top-1]
    bcSHR_W,    // [top] = [top] shr [top-1]
    bcSHL_W,    // [top] = [top] shl [top-1]

    bcINC_W,    // [top]++
    bcDEC_W,    // [top]--
    bcADD_W,    // [top] = [top] + [top-1]
    bcSUB_W,    // [top] = [top] - [top-1]
    bcMUL_W,    // [top] = [top] * [top-1]
    bcDIV_W,    // [top] = [top] / [top-1]
    bcMOD_W,    // [top] = [top] % [top-1]
    bcIDIV_W,   // [top] = [top] \ [top-1]

    bcMV_W,     // [top]^ = [top-1]^
    bcMVBP_W,   // [top]^^ = [top-1]^

    {** for integer's **}
    bcEQ_I,     // [top] == [top-1] ? [top] = 1 : [top] = 0
    bcBG_I,     // [top] >  [top-1] ? [top] = 1 : [top] = 0
    bcBE_I,     // [top] >= [top-1] ? [top] = 1 : [top] = 0

    bcNOT_I,    // [top] = ![top]
    bcAND_I,    // [top] = [top] and [top-1]
    bcOR_I,     // [top] = [top] or  [top-1]
    bcXOR_I,    // [top] = [top] xor [top-1]
    bcSHR_I,    // [top] = [top] shr [top-1]
    bcSHL_I,    // [top] = [top] shl [top-1]

    bcNEG_I,    // [top] = -[top]
    bcINC_I,    // [top]++
    bcDEC_I,    // [top]--
    bcADD_I,    // [top] = [top] + [top-1]
    bcSUB_I,    // [top] = [top] - [top-1]
    bcMUL_I,    // [top] = [top] * [top-1]
    bcDIV_I,    // [top] = [top] / [top-1]
    bcMOD_I,    // [top] = [top] % [top-1]
    bcIDIV_I,   // [top] = [top] \ [top-1]

    bcMV_I,     // [top]^ = [top-1]^
    bcMVBP_I,   // [top]^^ = [top-1]^

    {** for digit's with floating point **}
    bcEQ_D,     // [top] == [top-1] ? [top] = 1 : [top] = 0
    bcBG_D,     // [top] >  [top-1] ? [top] = 1 : [top] = 0
    bcBE_D,     // [top] >= [top-1] ? [top] = 1 : [top] = 0

    bcNEG_D,    // [top] = -[top]
    bcINC_D,    // [top]++
    bcDEC_D,    // [top]--
    bcADD_D,    // [top] = [top] + [top-1]
    bcSUB_D,    // [top] = [top] - [top-1]
    bcMUL_D,    // [top] = [top] * [top-1]
    bcDIV_D,    // [top] = [top] / [top-1]
    bcMOD_D,    // [top] = [top] % [top-1]
    bcIDIV_D,   // [top] = [top] \ [top-1]

    bcMV_D,     // [top]^ = [top-1]^
    bcMVBP_D,   // [top]^^ = [top-1]^

    {** for string's **}
    bcEQ_S,
    bcADD_S,
    bcMV_S,
    bcMVBP_S,
    bcSTRL,     // strlen
    bcSTRD,     // strdel
    bcSTCHATP,  // push str[x]
    bcSTCHATK,  // peek str[x]
    bcCHORD,
    bcORDCH
    );

procedure TCodeSection.ParseSection;
var
  p1,p2:cardinal;
  s:string;
begin
  p1 := 0;
  p2 := 0;
  while p2<Lines.Count do
   begin
     s := Lines[p2];
     if (s[length(s)] = ':') then
      begin
        Constants.AddConstCardinal(copy(s,1,length(s)-1),p1);
        Lines.Delete(p2);
        dec(p2);
        dec(p1);
      end;
     if (Tk(s,1) = 'push') or (Tk(s,1) = 'peek') or (Tk(s,1) = 'pushc') or (Tk(s,1) = 'pushm') then
      inc(p1,5)
     else
      if Length(s)>0 then
       inc(p1);
     inc(p2);
   end;
  while Lines.Count>0 do
   begin
    s := Lines[0];
    Lines.Delete(0);
    if Tk(s,1) = 'push' then
     begin
       Outp.WriteByte(byte(bcPH));
       St_WriteCardinal(Outp,StrToQWord(Tk(s,2)));
       s := '';
     end;
    if Tk(s,1) = 'peek' then
     begin
       Outp.WriteByte(byte(bcPK));
       St_WriteCardinal(Outp,StrToQWord(Tk(s,2)));
       s := '';
     end;
    if Tk(s,1) = 'pushc' then
     begin
       Outp.WriteByte(byte(bcPHC));
       St_WriteCardinal(Outp,Constants.GetAddr(Tk(s,2)));
       s := '';
     end;
    if Tk(s,1) = 'pushm' then
     begin
       Outp.WriteByte(byte(bcPHEXMP));
       St_WriteCardinal(Outp,Constants.GetAddr(Tk(s,2)));
       s := '';
     end;
    if Tk(s,1) = 'pop' then
     Outp.WriteByte(byte(bcPP))
    else
    if Tk(s,1) = 'stkdrop' then
     Outp.WriteByte(byte(bcSDP))
    else
    if Tk(s,1) = 'swp' then
     Outp.WriteByte(byte(bcSWP))
    else
    if Tk(s,1) = 'jp' then
     Outp.WriteByte(byte(bcJP))
    else
    if Tk(s,1) = 'jz' then
     Outp.WriteByte(byte(bcJZ))
    else
    if Tk(s,1) = 'jn' then
     Outp.WriteByte(byte(bcJN))
    else
    if Tk(s,1) = 'jc' then
     Outp.WriteByte(byte(bcJC))
    else
    if Tk(s,1) = 'jr' then
     Outp.WriteByte(byte(bcJR))
    else
    if Tk(s,1) = 'eq' then
     Outp.WriteByte(byte(bcEQ))
    else
    if Tk(s,1) = 'bg' then
     Outp.WriteByte(byte(bcBG))
    else
    if Tk(s,1) = 'be' then
     Outp.WriteByte(byte(bcBE))
    else
    if Tk(s,1) = 'not' then
     Outp.WriteByte(byte(bcNOT))
    else
    if Tk(s,1) = 'and' then
     Outp.WriteByte(byte(bcAND))
    else
    if Tk(s,1) = 'or' then
     Outp.WriteByte(byte(bcOR))
    else
    if Tk(s,1) = 'xor' then
     Outp.WriteByte(byte(bcXOR))
    else
    if Tk(s,1) = 'shr' then
     Outp.WriteByte(byte(bcSHR))
    else
    if Tk(s,1) = 'shl' then
     Outp.WriteByte(byte(bcSHL))
    else
    if Tk(s,1) = 'neg' then
     Outp.WriteByte(byte(bcNEG))
    else
    if Tk(s,1) = 'inc' then
     Outp.WriteByte(byte(bcINC))
    else
    if Tk(s,1) = 'dec' then
     Outp.WriteByte(byte(bcDEC))
    else
    if Tk(s,1) = 'add' then
     Outp.WriteByte(byte(bcADD))
    else
    if Tk(s,1) = 'sub' then
     Outp.WriteByte(byte(bcSUB))
    else
    if Tk(s,1) = 'mul' then
     Outp.WriteByte(byte(bcMUL))
    else
    if Tk(s,1) = 'div' then
     Outp.WriteByte(byte(bcDIV))
    else
    if Tk(s,1) = 'mod' then
     Outp.WriteByte(byte(bcMOD))
    else
    if Tk(s,1) = 'idiv' then
     Outp.WriteByte(byte(bcIDIV))
    else
    if Tk(s,1) = 'mov' then
     Outp.WriteByte(byte(bcMV))
    else
    if Tk(s,1) = 'movbp' then
     Outp.WriteByte(byte(bcMVBP))
    else
    if Tk(s,1) = 'movp' then
     Outp.WriteByte(byte(bcMVP))
    else
    if Tk(s,1) = 'msz' then
     Outp.WriteByte(byte(bcMS))
    else
    if Tk(s,1) = 'new' then
     Outp.WriteByte(byte(bcNW))
    else
    if Tk(s,1) = 'copy' then
     Outp.WriteByte(byte(bcMC))
    else
    if Tk(s,1) = 'pcopy' then
     Outp.WriteByte(byte(bcMD))
    else
    if Tk(s,1) = 'rem' then
     Outp.WriteByte(byte(bcRM))
    else
    if Tk(s,1) = 'newa' then
     Outp.WriteByte(byte(bcNA))
    else
    if Tk(s,1) = 'sizeof' then
     Outp.WriteByte(byte(bcSF))
    else
    if Tk(s,1) = 'alen' then
     Outp.WriteByte(byte(bcAL))
    else
    if Tk(s,1) = 'salen' then
     Outp.WriteByte(byte(bcSL))
    else
    if Tk(s,1) = 'pushai' then
     Outp.WriteByte(byte(bcPA))
    else
    if Tk(s,1) = 'peekai' then
     Outp.WriteByte(byte(bcSA))
    else
    if Tk(s,1) = 'gpm' then
     Outp.WriteByte(byte(bcGPM))
    else
    if Tk(s,1) = 'gpa' then
     Outp.WriteByte(byte(bcGPA))
    else
    if Tk(s,1) = 'gc' then
     Outp.WriteByte(byte(bcGC))
    else
    if Tk(s,1) = 'invoke' then
     Outp.WriteByte(byte(bcINV))
    else
    if Tk(s,1) = 'invokebp' then
     Outp.WriteByte(byte(bcINVBP))
    else
    if Tk(s,1) = 'pushn' then
     Outp.WriteByte(byte(bcPHN))
    else
    if Tk(s,1) = 'cthr' then
     Outp.WriteByte(byte(bcCTHR))
    else
    if Tk(s,1) = 'sthr' then
     Outp.WriteByte(byte(bcSTHR))
    else
    if Tk(s,1) = 'rthr' then
     Outp.WriteByte(byte(bcRTHR))
    else
    if Tk(s,1) = 'tthr' then
     Outp.WriteByte(byte(bcTTHR))
    else
    if Tk(s,1) = 'tr' then
     Outp.WriteByte(byte(bcTR))
    else
    if Tk(s,1) = 'trs' then
     Outp.WriteByte(byte(bcTRS))
    else
    if Tk(s,1) = 'trr' then
     Outp.WriteByte(byte(bcTRR))
    else
    if Tk(s,1) = 'eqw' then
     Outp.WriteByte(byte(bcEQ_W))
    else
    if Tk(s,1) = 'bgw' then
     Outp.WriteByte(byte(bcBG_W))
    else
    if Tk(s,1) = 'bew' then
     Outp.WriteByte(byte(bcBE_W))
    else
    if Tk(s,1) = 'notw' then
     Outp.WriteByte(byte(bcNOT_W))
    else
    if Tk(s,1) = 'andw' then
     Outp.WriteByte(byte(bcAND_W))
    else
    if Tk(s,1) = 'orw' then
     Outp.WriteByte(byte(bcOR_W))
    else
    if Tk(s,1) = 'xorw' then
     Outp.WriteByte(byte(bcXOR_W))
    else
    if Tk(s,1) = 'shrw' then
     Outp.WriteByte(byte(bcSHR_W))
    else
    if Tk(s,1) = 'shlw' then
     Outp.WriteByte(byte(bcSHL_W))
     else
    if Tk(s,1) = 'eqi' then
     Outp.WriteByte(byte(bcEQ_I))
    else
    if Tk(s,1) = 'bgi' then
     Outp.WriteByte(byte(bcBG_I))
    else
    if Tk(s,1) = 'bei' then
     Outp.WriteByte(byte(bcBE_I))
    else
    if Tk(s,1) = 'noti' then
     Outp.WriteByte(byte(bcNOT_I))
    else
    if Tk(s,1) = 'andi' then
     Outp.WriteByte(byte(bcAND_I))
    else
    if Tk(s,1) = 'ori' then
     Outp.WriteByte(byte(bcOR_I))
    else
    if Tk(s,1) = 'xori' then
     Outp.WriteByte(byte(bcXOR_I))
    else
    if Tk(s,1) = 'shri' then
     Outp.WriteByte(byte(bcSHR_I))
    else
    if Tk(s,1) = 'shli' then
     Outp.WriteByte(byte(bcSHL_I))
    else
    if Tk(s,1) = 'eqd' then
     Outp.WriteByte(byte(bcEQ_D))
    else
    if Tk(s,1) = 'bgd' then
     Outp.WriteByte(byte(bcBG_D))
    else
    if Tk(s,1) = 'bed' then
     Outp.WriteByte(byte(bcBE_D))
    else
    if Tk(s,1) = 'incw' then
     Outp.WriteByte(byte(bcINC_W))
    else
    if Tk(s,1) = 'decw' then
     Outp.WriteByte(byte(bcDEC_W))
    else
    if Tk(s,1) = 'addw' then
     Outp.WriteByte(byte(bcADD_W))
    else
    if Tk(s,1) = 'subw' then
     Outp.WriteByte(byte(bcSUB_W))
    else
    if Tk(s,1) = 'mulw' then
     Outp.WriteByte(byte(bcMUL_W))
    else
    if Tk(s,1) = 'divw' then
     Outp.WriteByte(byte(bcDIV_W))
    else
    if Tk(s,1) = 'modw' then
     Outp.WriteByte(byte(bcMOD_W))
    else
    if Tk(s,1) = 'idivw' then
     Outp.WriteByte(byte(bcIDIV_W))
    else
    if Tk(s,1) = 'mvw' then
     Outp.WriteByte(byte(bcMV_W))
    else
    if Tk(s,1) = 'mvbpw' then
     Outp.WriteByte(byte(bcMVBP_W))
    else
    if Tk(s,1) = 'negi' then
     Outp.WriteByte(byte(bcNEG_I))
    else
    if Tk(s,1) = 'inci' then
     Outp.WriteByte(byte(bcINC_I))
    else
    if Tk(s,1) = 'deci' then
     Outp.WriteByte(byte(bcDEC_I))
    else
    if Tk(s,1) = 'addi' then
     Outp.WriteByte(byte(bcADD_I))
    else
    if Tk(s,1) = 'subi' then
     Outp.WriteByte(byte(bcSUB_I))
    else
    if Tk(s,1) = 'muli' then
     Outp.WriteByte(byte(bcMUL_I))
    else
    if Tk(s,1) = 'divi' then
     Outp.WriteByte(byte(bcDIV_I))
    else
    if Tk(s,1) = 'modi' then
     Outp.WriteByte(byte(bcMOD_I))
    else
    if Tk(s,1) = 'idivi' then
     Outp.WriteByte(byte(bcIDIV_I))
    else
    if Tk(s,1) = 'mvi' then
     Outp.WriteByte(byte(bcMV_I))
    else
    if Tk(s,1) = 'mvbpi' then
     Outp.WriteByte(byte(bcMVBP_I))
    else
    if Tk(s,1) = 'negd' then
     Outp.WriteByte(byte(bcNEG_D))
    else
    if Tk(s,1) = 'incd' then
     Outp.WriteByte(byte(bcINC_D))
    else
    if Tk(s,1) = 'decd' then
     Outp.WriteByte(byte(bcDEC_D))
    else
    if Tk(s,1) = 'addd' then
     Outp.WriteByte(byte(bcADD_D))
    else
    if Tk(s,1) = 'subd' then
     Outp.WriteByte(byte(bcSUB_D))
    else
    if Tk(s,1) = 'muld' then
     Outp.WriteByte(byte(bcMUL_D))
    else
    if Tk(s,1) = 'divd' then
     Outp.WriteByte(byte(bcDIV_D))
    else
    if Tk(s,1) = 'modd' then
     Outp.WriteByte(byte(bcMOD_D))
    else
    if Tk(s,1) = 'idivd' then
     Outp.WriteByte(byte(bcIDIV_D))
    else
    if Tk(s,1) = 'mvd' then
     Outp.WriteByte(byte(bcMV_D))
    else
    if Tk(s,1) = 'mvbpd' then
     Outp.WriteByte(byte(bcMVBP_D))
    else
    if Tk(s,1) = 'eqs' then
     Outp.WriteByte(byte(bcEQ_S))
    else
    if Tk(s,1) = 'adds' then
     Outp.WriteByte(byte(bcADD_S))
    else
    if Tk(s,1) = 'mvs' then
     Outp.WriteByte(byte(bcMV_S))
    else
    if Tk(s,1) = 'mvbps' then
     Outp.WriteByte(byte(bcMVBP_S))
    else
    if Tk(s,1) = 'strl' then
     Outp.WriteByte(byte(bcSTRL))
    else
    if Tk(s,1) = 'strd' then
     Outp.WriteByte(byte(bcSTRD))
    else
    if Tk(s,1) = 'stchatp' then
     Outp.WriteByte(byte(bcSTCHATP))
    else
    if Tk(s,1) = 'stchatk' then
     Outp.WriteByte(byte(bcSTCHATK))
    else
    if Tk(s,1) = 'chord' then
     Outp.WriteByte(byte(bcCHORD))
    else
    if Tk(s,1) = 'ordch' then
     Outp.WriteByte(byte(bcORDCH))
    else
     if Length(s)>0 then
      AsmError('Invalid token in line: "'+s+'"');
   end;
end;

procedure TCodeSection.GenerateCode(Stream:TStream);
begin
  Stream.WriteBuffer(Outp.Memory^,Outp.Size);
end;

{** Main **}

var
  Code: TStringList;
  c:cardinal;
  Output:TMemoryStream;
  varmgr:TVarManager;
  Imports:TImportSection;
  CodeSection:TCodeSection;
  AppMode:string = '/cns';
  Tm,Tm2:TDateTime;
begin
 if ParamCount=0 then
  begin
    writeln('Assembler for SVM.');
    writeln('Use: ',ExtractFileName(ParamStr(0)),' <file> [mode]');
    writeln('Mode''s:');
    writeln(' /cns  - make console program (default).');
    writeln(' /gui  - make GUI program.');
    writeln(' /bin  - make program without SVMEXE header.');
    halt;
  end;
 Tm := Now;
 writeln('Building started.');
 DecimalSeparator := '.';
 IncludedFiles := TStringList.Create;
 Code := TStringList.Create;
 Code.LoadFromFile(ParamStr(1));
 if Code.Count>0 then
   for c := 0 to Code.Count-1 do
    Code[c] := TrimCodeStr(Code[c]);
 {for c:=code.count-1 downto 0 do
  if trim(code[c
  ])='' then code.delete(c);}
 c := 0;
 varmgr := TVarManager.Create;
 Constants := TConstantManager.Create(Code);
 InitPreprocessor;
 while c<Code.Count do
  begin
    if Trim(Code[c]) <> '' then
     Code[c] := Trim(PreprocessStr(Code[c],varmgr));
    inc(c);
  end;
 FreePreprocessor;
 code.text := 'word __addrtsz '+inttostr(varmgr.DefinedVars.Count)+sLineBreak+
              'pushc __addrtsz'+sLineBreak+
              'gpm'+sLineBreak+
              'msz'+sLineBreak+
              'gc'+sLineBreak+
              'pushc __entrypoint'+slinebreak+
              'gpm'+slinebreak+
              'jc'+sLineBreak+
              'pushc __haltpoint'+sLineBreak+
              'gpm'+sLineBreak+
              'jp'+sLineBreak+
              code.text+sLineBreak+
              '__haltpoint:'+sLineBreak+
              'gc';
 code.SaveToFile('buf.tmp');      // Хз почему, но без этого не работает...
 code.LoadFromFile('buf.tmp');    //
 DeleteFile('buf.tmp');           //
 if Code.Count>0 then
  begin
    Output := TMemoryStream.Create;

    if ParamCount >= 2 then
     AppMode := LowerCase(ParamStr(2));

    if AppMode <> '/bin' then
     begin
       Output.WriteByte(ord('S'));
       Output.WriteByte(ord('V'));
       Output.WriteByte(ord('M'));
       Output.WriteByte(ord('E'));
       Output.WriteByte(ord('X'));
       Output.WriteByte(ord('E'));
       Output.WriteByte(ord('_'));
       if AppMode = '/gui' then
        begin
          Output.WriteByte(ord('G'));
          Output.WriteByte(ord('U'));
          Output.WriteByte(ord('I'));
          writeln('Header: SVMEXE / GUI program.');
        end
       else
        begin
          Output.WriteByte(ord('C'));
          Output.WriteByte(ord('N'));
          Output.WriteByte(ord('S'));
          writeln('Header: SVMEXE / Console program.');
        end;
     end
    else
     writeln('Header: SVM / Object file.');
    Imports := TImportSection.Create(Code);
    Imports.ParseSection;
    Imports.GenerateCode(Output);
    Constants.ParseSection;
    Constants.AppendImports(Imports);
    for c:=code.count-1 downto 0 do
     if trim(code[c])='' then code.delete(c);
    CodeSection := TCodeSection.Create(Code, Constants);
    CodeSection.ParseSection;
    Constants.CheckForDoubles;
    Constants.GenerateCode(Output);
    writeln('Constants defined: ',Constants.Constants.Count,'.');
    CodeSection.GenerateCode(Output);
    writeln('Success.');
    Tm2 := Now;
    writeln('Build time: ',trunc((Tm2-Tm)/60),',',Copy(FloatToStr(frac((Tm2-Tm)/60)),3,6),' sec.');
    writeln('Executable file size: ',Output.Size,' bytes.');
    FreeAndNil(Imports);
    FreeAndNil(Constants);
    FreeAndNil(CodeSection);
    Output.SaveToFile(ChangeFileExt(ParamStr(1),'.vmc'));
    FreeAndNil(Output);
  end;
 FreeAndNil(Code);
 FreeAndNil(IncludedFiles);
end.

