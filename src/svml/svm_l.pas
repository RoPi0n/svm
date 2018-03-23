library svm_l;

uses
  {$IfDef UNIX} Cthreads, {$EndIF}
  SysUtils;

type
  TByteArr = array of byte;
  PByteArr = ^TByteArr;

function SVM_Create:Pointer; stdcall;
  external {$IfDef Windows}'svm_core.dll'{$EndIf}{$IfDef UNIX}'svm_core.so'{$EndIf}
  name '_SVM_CREATE';

procedure SVM_Free(SVM:Pointer); stdcall;
  external {$IfDef Windows}'svm_core.dll'{$EndIf}{$IfDef UNIX}'svm_core.so'{$EndIf}
  name '_SVM_FREE';

procedure SVM_RegAPI(SVM:Pointer; ExtFunc:Pointer); stdcall;
  external {$IfDef Windows}'svm_core.dll'{$EndIf}{$IfDef UNIX}'svm_core.so'{$EndIf}
  name '_SVM_REGAPI';

procedure SVM_Run(SVM:Pointer; MainClassPath:PChar; pb:PByteArr); stdcall;
  external {$IfDef Windows}'svm_core.dll'{$EndIf}{$IfDef UNIX}'svm_core.so'{$EndIf}
  name '_SVM_RUN';

procedure CutLeftBytes(pb: PByteArr; cnt: cardinal);
var
  i: cardinal;
begin
  for i := 0 to cardinal(length(pb^)) - cnt do
    pb^[i] := pb^[i + cnt];
  setlength(pb^, cardinal(length(pb^)) - cnt);
end;

procedure CheckHeader(pb:PByteArr);
begin
  if Length(pb^) >= 10 then
   begin
     if (chr(pb^[0]) = 'S') and (chr(pb^[1]) = 'V') and (chr(pb^[2]) = 'M') and
        (chr(pb^[3]) = 'E') and (chr(pb^[4]) = 'X') and (chr(pb^[5]) = 'E') and
        (chr(pb^[6]) = '_') and (chr(pb^[7]) = 'C') and (chr(pb^[8]) = 'N') and
        (chr(pb^[9]) = 'S') then Exit;
     if (chr(pb^[0]) = 'S') and (chr(pb^[1]) = 'V') and (chr(pb^[2]) = 'M') and
        (chr(pb^[3]) = 'E') and (chr(pb^[4]) = 'X') and (chr(pb^[5]) = 'E') and
        (chr(pb^[6]) = '_') and (chr(pb^[7]) = 'G') and (chr(pb^[8]) = 'U') and
        (chr(pb^[9]) = 'I') then Exit;
   end;
  raise Exception.Create('Error: Invalid SVMEXE-file header!');
  halt;
end;

procedure SVML_RUN; stdcall;
var
  f: file of byte;
  fn:string;
  bytes:TByteArr;
  svm:pointer;
begin
  fn := ParamStr(1);
  AssignFile(f, fn);
  Reset(f);
  SetLength(bytes, 0);
  while not EOF(f) do
   begin
     SetLength(bytes, Length(bytes) + 1);
     Read(f, bytes[Length(bytes) - 1]);
   end;
  CloseFile(f);
  CheckHeader(@bytes);
  CutLeftBytes(@bytes,10);
  svm := SVM_Create;
  SVM_Run(svm, PChar(fn),@bytes);
  SVM_Free(svm);
end;

exports SVML_RUN name '_SVML_RUN';

begin
end.
