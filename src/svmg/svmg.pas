program svmg;
{$AppType GUI}

procedure StartVM; stdcall; {$IfDef Windows}external 'svm_l.dll'{$EndIf}
  {$IfDef UNIX}external 'svm_l.so'{$EndIf} name '_SVML_RUN';

begin
  StartVM;
end.
