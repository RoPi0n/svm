unit MainForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, SynCompletion, Forms, Controls, Graphics,
  Dialogs, Menus, ComCtrls, ExtCtrls, StdCtrls, Editor, Global, AboutForm,
  Process, LazUTF8;

type

  { TMainFrm }

  TMainFrm = class(TForm)
    Button1: TButton;
    LogsPanel: TPanel;
    MainMenu1: TMainMenu;
    LogMemo: TMemo;
    MenuItem1: TMenuItem;
    MenuItem10: TMenuItem;
    MenuItem11: TMenuItem;
    MenuItem12: TMenuItem;
    MenuItem13: TMenuItem;
    MenuItem19: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem20: TMenuItem;
    MenuItem21: TMenuItem;
    MenuItem22: TMenuItem;
    MenuItem23: TMenuItem;
    MenuItem24: TMenuItem;
    MenuItem25: TMenuItem;
    MenuItem26: TMenuItem;
    MenuItem27: TMenuItem;
    MenuItem28: TMenuItem;
    MenuItem29: TMenuItem;
    MenuItem3: TMenuItem;
    MenuItem30: TMenuItem;
    MenuItem31: TMenuItem;
    MenuItem32: TMenuItem;
    MenuItem4: TMenuItem;
    MenuItem5: TMenuItem;
    MenuItem6: TMenuItem;
    MenuItem7: TMenuItem;
    MenuItem8: TMenuItem;
    MenuItem9: TMenuItem;
    OpenDialog: TOpenDialog;
    PageControl: TPageControl;
    Panel2: TPanel;
    Panel3: TPanel;
    SaveDialog: TSaveDialog;
    Splitter1: TSplitter;
    StatusBar: TStatusBar;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure MenuItem10Click(Sender: TObject);
    procedure MenuItem12Click(Sender: TObject);
    procedure MenuItem13Click(Sender: TObject);
    procedure MenuItem19Click(Sender: TObject);
    procedure MenuItem22Click(Sender: TObject);
    procedure MenuItem23Click(Sender: TObject);
    procedure MenuItem25Click(Sender: TObject);
    procedure MenuItem26Click(Sender: TObject);
    procedure MenuItem28Click(Sender: TObject);
    procedure MenuItem29Click(Sender: TObject);
    procedure MenuItem2Click(Sender: TObject);
    procedure MenuItem30Click(Sender: TObject);
    procedure MenuItem31Click(Sender: TObject);
    procedure MenuItem32Click(Sender: TObject);
    procedure MenuItem3Click(Sender: TObject);
    procedure MenuItem5Click(Sender: TObject);
    procedure MenuItem6Click(Sender: TObject);
    procedure MenuItem7Click(Sender: TObject);
    procedure MenuItem9Click(Sender: TObject);
    procedure OpenTab(FilePath,TabName:string; Operation:TOpenOp);
    procedure PageControlChange(Sender: TObject);
    procedure PageControlMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure BuildFile(fp,flags:string);
    procedure BuildFileAndRun(fp,flags,svm:string);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  MainFrm: TMainFrm;
  NewTabsCnt: cardinal = 0;
  ActivePageIndex: cardinal;

implementation

{$R *.lfm}

function GetEditor(Tab:TTabSheet):TEditorFrame;
var
  j:cardinal;
begin
  j := 0;
  Result := nil;
  while j<Tab.ControlCount do
   begin
     if (Tab.Controls[j] is TEditorFrame) then
      begin
        Result := TEditorFrame(Tab.Controls[j]);
        break;
      end;
     inc(j);
   end;
end;

procedure TMainFrm.OpenTab(FilePath,TabName:string; Operation:TOpenOp);
var
  Editor:TEditorFrame;
  Tab:TTabSheet;
begin
  Tab := TTabSheet.Create(PageControl);
  Tab.Caption := TabName + '  [X]';
  Tab.PageControl := PageControl;
  Editor := TEditorFrame.CreateEditor(Tab, StatusBar, Operation, FilePath);
  Editor.Visible := True;
  Editor.Parent := Tab;
  ActivePageIndex := PageControl.PageCount-1;
  PageControl.ActivePageIndex := ActivePageIndex;
end;

procedure TMainFrm.PageControlChange(Sender: TObject);
begin
  PageControl.ActivePageIndex := ActivePageIndex;
end;

function InRect(R:TRect; P:TPoint):boolean;
begin
  Result := (R.Left <= P.X) and (R.Right >= P.X) and
            (R.Top <= P.Y) and (R.Bottom >= P.Y);
end;

procedure TMainFrm.PageControlMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  TabIndex: Integer;
  TabRect: TRect;
begin
  if Button = mbLeft then
   begin
     TabIndex := PageControl.IndexOfTabAt(X,Y);
     ActivePageIndex := TabIndex;
     TabRect := PageControl.TabRect(TabIndex);
     if InRect(
          Classes.Rect(TabRect.Right-16-2,TabRect.Top+2,
               TabRect.Right-6,TabRect.Bottom-4),
          Classes.Point(X,Y)
        )
     then
      begin
        ActivePageIndex := PageControl.ActivePageIndex;
        PageControl.Pages[TabIndex].Free;
        if PageControl.PageCount > 0 then
         begin
           if ActivePageIndex > TabIndex then
            dec(ActivePageIndex);
           if ActivePageIndex >= 0 then
            PageControl.ActivePageIndex := ActivePageIndex;
         end;
      end;
     PageControl.ActivePageIndex := ActivePageIndex;
   end;
end;

procedure TMainFrm.MenuItem2Click(Sender: TObject);
begin
  inc(NewTabsCnt);
  OpenTab('','New '+IntToStr(NewTabsCnt), opopNew);
end;

procedure TMainFrm.MenuItem30Click(Sender: TObject);
begin
  if PageControl.ActivePageIndex >= 0 then
   GetEditor(PageControl.ActivePage).SynEdit.PasteFromClipboard;
end;

procedure TMainFrm.MenuItem31Click(Sender: TObject);
begin
  if PageControl.ActivePageIndex >= 0 then
   GetEditor(PageControl.ActivePage).SynEdit.SelectAll;
end;

procedure TMainFrm.MenuItem32Click(Sender: TObject);
var
  EdtFrm:TEditorFrame;
begin
  if LogsPanel.Height = 0 then
   LogsPanel.Height := 196;
  Self.Repaint;
  if PageControl.ActivePageIndex >= 0 then
   begin
     EdtFrm := GetEditor(PageControl.ActivePage);
     if FileExists(EdtFrm.DefFile) then
      begin
        EdtFrm.SynEdit.Lines.SaveToFile(EdtFrm.DefFile);
        EdtFrm.Saved := True;
        EdtFrm.UpdateState;
        BuildFileAndRun(EdtFrm.DefFile,'/cns','svmc.exe');
      end
     else
      begin
        if SaveDialog.Execute then
         begin
           EdtFrm.DefFile := SaveDialog.FileName;
           PageControl.ActivePage.Caption := ExtractFilePath(SaveDialog.FileName);
           EdtFrm.SynEdit.Lines.SaveToFile(EdtFrm.DefFile);
           EdtFrm.Saved := True;
           EdtFrm.UpdateState;
           BuildFileAndRun(EdtFrm.DefFile,'/cns','svmc.exe');
         end;
      end;
   end;
end;

procedure TMainFrm.MenuItem3Click(Sender: TObject);
begin
  if OpenDialog.Execute then
   begin
     OpenTab(OpenDialog.FileName,ExtractFileName(OpenDialog.FileName), opopOpen);
   end;
end;

procedure TMainFrm.MenuItem5Click(Sender: TObject);
var
  EdtFrm:TEditorFrame;
begin
  if PageControl.ActivePageIndex >= 0 then
   begin
     EdtFrm := GetEditor(PageControl.ActivePage);
     if FileExists(EdtFrm.DefFile) then
      begin
        EdtFrm.SynEdit.Lines.SaveToFile(EdtFrm.DefFile);
        EdtFrm.Saved := True;
        EdtFrm.UpdateState;
      end
     else
      begin
        if SaveDialog.Execute then
         begin
           EdtFrm.DefFile := SaveDialog.FileName;
           PageControl.ActivePage.Caption := ExtractFileName(SaveDialog.FileName)+'  [X]';
           EdtFrm.SynEdit.Lines.SaveToFile(EdtFrm.DefFile);
           EdtFrm.Saved := True;
           EdtFrm.UpdateState;
         end;
      end;
   end;
end;

procedure TMainFrm.MenuItem6Click(Sender: TObject);
var
  EdtFrm:TEditorFrame;
begin
  if PageControl.ActivePageIndex >= 0 then
   begin
     EdtFrm := GetEditor(PageControl.ActivePage);
     if SaveDialog.Execute then
      begin
        EdtFrm.DefFile := SaveDialog.FileName;
        PageControl.ActivePage.Caption := ExtractFileName(SaveDialog.FileName)+'  [X]';
        EdtFrm.SynEdit.Lines.SaveToFile(EdtFrm.DefFile);
        EdtFrm.Saved := True;
        EdtFrm.UpdateState;
      end;
   end;
end;

procedure TMainFrm.MenuItem7Click(Sender: TObject);
var
  j:cardinal;
begin
  j := 0;
  while j<PageControl.PageCount do
   begin
     PageControl.ActivePageIndex := j;
     MenuItem5Click(Sender);
     Inc(j);
   end;
  PageControl.ActivePageIndex := ActivePageIndex;
end;

procedure TMainFrm.MenuItem9Click(Sender: TObject);
begin
  Close;
end;

procedure TMainFrm.FormCreate(Sender: TObject);
begin
  LogsPanel.Height := 0;
end;

procedure TMainFrm.BuildFile(fp,flags:string);
var
  fp_vmc:string;
  AProcess: TProcess;
  sl: TStringList;
begin
  LogMemo.Lines.Clear;
  LogMemo.Lines.Add('Start building file: "'+fp+'"');
  AProcess := TProcess.Create(Self);
  sl := TStringList.Create;
  AProcess.Executable := 'svmasm.exe';
  AProcess.Parameters.Add(UTF8ToWinCP(fp));
  AProcess.Parameters.Add(flags);
  AProcess.Options := AProcess.Options + [poWaitOnExit, poUsePipes, poNoConsole];
  AProcess.Execute;
  sl.LoadFromStream(AProcess.Output);
  LogMemo.Lines.AddStrings(sl);
  FreeAndNil(AProcess);
  FreeAndNil(sl);
end;

procedure TMainFrm.BuildFileAndRun(fp,flags,svm:string);
var
  fp_vmc:string;
  AProcess: TProcess;
begin
  fp_vmc := ExtractFilePath(fp)+ChangeFileExt(ExtractFileName(fp),'.vmc');
  if FileExists(fp_vmc) then
   SysUtils.DeleteFile(fp_vmc);
  BuildFile(fp,flags);
  if FileExists(fp_vmc) then
   begin
     AProcess := TProcess.Create(Self);
     AProcess.Executable := svm;
     AProcess.Parameters.Add(UTF8ToWinCP(fp_vmc));
     AProcess.Execute;
     FreeAndNil(AProcess);
   end
  else
   LogMemo.Lines.Add('Failed to launch .vmc file.');
end;

procedure TMainFrm.MenuItem10Click(Sender: TObject);
var
  EdtFrm:TEditorFrame;
begin
  if LogsPanel.Height = 0 then
   LogsPanel.Height := 196;
  Self.Repaint;
  if PageControl.ActivePageIndex >= 0 then
   begin
     EdtFrm := GetEditor(PageControl.ActivePage);
     if FileExists(EdtFrm.DefFile) then
      begin
        EdtFrm.SynEdit.Lines.SaveToFile(EdtFrm.DefFile);
        EdtFrm.Saved := True;
        EdtFrm.UpdateState;
        BuildFile(EdtFrm.DefFile,'/cns');
      end
     else
      begin
        if SaveDialog.Execute then
         begin
           EdtFrm.DefFile := SaveDialog.FileName;
           PageControl.ActivePage.Caption := ExtractFilePath(SaveDialog.FileName);
           EdtFrm.SynEdit.Lines.SaveToFile(EdtFrm.DefFile);
           EdtFrm.Saved := True;
           EdtFrm.UpdateState;
           BuildFile(EdtFrm.DefFile,'/cns');
         end;
      end;
   end;
end;

procedure TMainFrm.Button1Click(Sender: TObject);
begin
  LogsPanel.Height := 0;
end;

procedure TMainFrm.MenuItem12Click(Sender: TObject);
begin
  LogsPanel.Height := 196;
end;

procedure TMainFrm.MenuItem13Click(Sender: TObject);
var
  EdtFrm:TEditorFrame;
begin
  if LogsPanel.Height = 0 then
   LogsPanel.Height := 196;
  Self.Repaint;
  if PageControl.ActivePageIndex >= 0 then
   begin
     EdtFrm := GetEditor(PageControl.ActivePage);
     if FileExists(EdtFrm.DefFile) then
      begin
        EdtFrm.SynEdit.Lines.SaveToFile(EdtFrm.DefFile);
        EdtFrm.Saved := True;
        EdtFrm.UpdateState;
        BuildFileAndRun(EdtFrm.DefFile,'/gui','svmg.exe');
      end
     else
      begin
        if SaveDialog.Execute then
         begin
           EdtFrm.DefFile := SaveDialog.FileName;
           PageControl.ActivePage.Caption := ExtractFilePath(SaveDialog.FileName);
           EdtFrm.SynEdit.Lines.SaveToFile(EdtFrm.DefFile);
           EdtFrm.Saved := True;
           EdtFrm.UpdateState;
           BuildFileAndRun(EdtFrm.DefFile,'/gui','svmg.exe');
         end;
      end;
   end;
end;

procedure TMainFrm.MenuItem19Click(Sender: TObject);
begin
  AboutFrm.ShowModal;
end;

procedure TMainFrm.MenuItem22Click(Sender: TObject);
begin
  if PageControl.ActivePageIndex >= 0 then
   GetEditor(PageControl.ActivePage).SynEdit.Undo;
end;

procedure TMainFrm.MenuItem23Click(Sender: TObject);
begin
  if PageControl.ActivePageIndex >= 0 then
   GetEditor(PageControl.ActivePage).SynEdit.Redo;
end;

procedure TMainFrm.MenuItem25Click(Sender: TObject);
begin
  if PageControl.ActivePageIndex >= 0 then
   GetEditor(PageControl.ActivePage).FindDlg;
end;

procedure TMainFrm.MenuItem26Click(Sender: TObject);
begin
  if PageControl.ActivePageIndex >= 0 then
   GetEditor(PageControl.ActivePage).ReplaceDlg;
end;

procedure TMainFrm.MenuItem28Click(Sender: TObject);
begin
  if PageControl.ActivePageIndex >= 0 then
   GetEditor(PageControl.ActivePage).SynEdit.CutToClipboard;
end;

procedure TMainFrm.MenuItem29Click(Sender: TObject);
begin
  if PageControl.ActivePageIndex >= 0 then
   GetEditor(PageControl.ActivePage).SynEdit.CopyToClipboard;
end;

end.

