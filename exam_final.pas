uses IntInp, App,Objects,Menus,Drivers,Views,Dialogs,Strings,MsgBox;

const

{�������}
cmAdd  = 200;  {�������� ������}
cmDel  = 201;  {㤠���� ������}
cmFind = 202;  {���� �����}
cmTick = 203;  {��⠭����� ������⢮ ����⮢}

type

{��ꥪ� - ������ � ⥫�䮭�}
Pwed = ^Twed;
Twed = object(TObject)
  Name,wedef,tkt,Mark:PString; 
  constructor Init(NewName,Newwedef,Newtkt,NewMark:String);
  constructor Load(var S:TStream);
  procedure Store(var S:TStream); virtual;
  destructor Done; virtual;
end;

{��ꥪ� - �������� ����ᥩ}
PwedCol = ^TwedCol;
TwedCol = object(TSortedCollection)
  function KeyOf(Item: Pointer): Pointer; virtual;
  function Compare(Key1, Key2: Pointer): Integer; virtual;
end;

{��ꥪ� - �⮡ࠦ���� ᯨ᮪ ����ᥩ}
PwedListBox = ^TwedListBox;
TwedListBox = object(TListBox)
  function GetText(Item: Integer; MaxLen: Integer): String; virtual;
end;

{��ꥪ� - �ਫ������}
PwedApp = ^TwedApp;
TwedApp = object(TApplication)
  wedCol: PwedCol; {�������� ����ᥩ}
  wedLB: PwedListBox; {�⮡ࠦ���� ᯨ᮪ ����ᥩ}
  TicketsCount: integer;
  PunchetTicketsCouts: integer;
  b: boolean;
  a: set of byte;
  constructor Init;
  procedure Loadwed;
  procedure Storewed;
  procedure Tick;
  procedure Add;
  procedure Del;
  procedure Find;
  procedure HandleEvent(var Event:TEvent); virtual;
  procedure InitMenuBar; virtual;
  procedure InitStatusLine; virtual;
  destructor Done; virtual;
end;

const

{�������� ��� ॣ����樨 ����� Twed (��࠭����/����㧪� �� ��⮪�)}
Rwed: TStreamRec = (
  ObjType: 100;
  VmtLink: Ofs(TypeOf(Twed)^);
  Load: @Twed.Load; {}
  Store: @Twed.Store
);

{�������� ��� ॣ����樨 ����� TwedCol (��࠭����/����㧪� �� ��⮪�)}
RwedCol: TStreamRec = (
  ObjType: 101;
  VmtLink: Ofs(TypeOf(TwedCol)^);
  Load: @TwedCol.Load;
  Store: @TwedCol.Store
);

{****************************************************************}

{���������}
constructor Twed.Init(NewName,Newwedef,Newtkt,NewMark:String);
begin
  Name:= NewStr(NewName);  {���}
  wedef:= NewStr(Newwedef); {����� ����⪨}
  tkt:= NewStr(Newtkt); {�����}
  Mark:= NewStr(NewMark); {�業��}
end;

{��������� ����㧪� �� ��⮪�}
constructor Twed.Load(var S:TStream);
begin
  Name:= S.ReadStr;  {���}
  wedef:= S.ReadStr; {����� ����⪨}
  tkt:= S.ReadStr; {�����}
  Mark:= S.ReadStr; {�業��}
end;

{��࠭���� � ��⮪}
procedure Twed.Store(var S:TStream);
begin
  S.WriteStr(Name);  {���}
  S.WriteStr(wedef); {����� ����⪨}
  S.WriteStr(tkt); {�����}
  S.WriteStr(Mark); {�業��}
end;

{��������}
destructor Twed.Done;
begin
  {�᢮�������� �����}
  if Name<>nil then Dispose(Name);
  if wedef<>nil then Dispose(wedef);
  if tkt<>nil then Dispose(tkt);
  if Mark<>nil then Dispose(Mark);
end;

{****************************************************************}

{���� ����� ������樨}
function TwedCol.KeyOf(Item: Pointer): Pointer;
begin
  KeyOf:= Pwed(Item)^.Name; {���}
end;

{�㭪�� �ࠢ����� ���祩}
function TwedCol.Compare(Key1, Key2: Pointer): Integer;
begin
  if PString(Key1)^ = PString(Key2)^ then {���� ࠢ��}
    Compare:= 0
  else if PString(Key1)^ < PString(Key2)^ then {���� ���� �����}
    Compare:= -1
  else
    Compare:= 1;
end;

{****************************************************************}

{��ନ஢���� ⥪�� ��� �⮡ࠦ���� ����� ᯨ᪠}
function TwedListBox.GetText(Item: Integer; MaxLen: Integer): String;
var
  p: Pwed;
  s,s1: string;
  par:array [0..3] of Longint;
begin
  p:= PwedCol(List)^.At(Item); {����祭�� �����}
  par[0]:= Longint(p^.Name); {���}
  par[1]:= Longint(p^.wedef); {����� ����⪨}
  par[2]:= Longint(p^.tkt); {�����}
  par[3]:= Longint(p^.Mark); {�業��}
  FormatStr(s,'%-29s�%-19s�%-13s�%-13s',par); {�ନ஢���� ��ப�}
  GetText:= s; {१����}
end;

{****************************************************************}
{��������� �ਫ������}
constructor TwedApp.Init;
var
  R:TRect;
  x1,y1,x2,y2:integer;
  SB:PScrollBar;
  D: PDialog;
begin
  inherited Init; {�맮� ��������� �������� ��ꥪ�}

  {ॣ������ ����ᮢ �����/�⥭�� �� �� ��⮪�}
  RegisterType(Rwed); 
  RegisterType(RwedCol);

  Loadwed;  {����㧪� ������}

  GetExtent(R);
  R.A.Y:= R.A.Y;
  R.B.Y:= R.B.Y-2;
  D:= New(PDialog,Init(R,'���������')); {���� �⮡ࠦ���� ����ᥩ}
  D^.Palette:= wpBlueWindow; {������ ����}
  with D^ do
   begin
    {����饭�� ������ �������, 㢥��祭��, ��६�饭�� � ������ ����}
    Flags:= Flags and not (wfClose + wfGrow + wfMove + wfZoom);

    {ࠧ��� ����}
    GetExtent(R);
    x1:= R.A.X;
    y1:= R.A.Y;
    x2:= R.B.X;
    y2:= R.B.Y;

    {���������� ⥪�� (蠯�� ��� ⠡���� ����ᥩ)}
    R.Assign(x1+1,y1+1,x2-1,y1+3);
    Insert(New(PStaticText, Init(R,
     '          ���                 �   ����� ����⪨   �   ����� �   �   �⬥⪠   ' +
     '������������������������������������������������������������������������������'
    )));

    {���������� ������ �ப��⪨} 
    R.Assign(x2-1,y1+1,x2,y2-1);
    New(SB,Init(R));
    Insert(SB);

    {���������� �⮡ࠦ������ ᯨ᪠}
    R.Assign(x1+1,y1+3,x2-1,y2-1);
    wedLB:= New(PwedListBox, Init(R,1,SB));
    wedLB^.NewList(wedCol);
    Insert(wedLB);
   end;
  
  DeskTop^.Insert(D); {��⠢�� ������� � DeskTop}
end;

{����㧪� ������ �� ��⮪�}
procedure TwedApp.Loadwed;
var
  wedFile: TBufStream;
begin
  wedFile.Init('wed.dat',stOpen,1024); {ᮧ����� ��⮪�}
  wedCol:= PwedCol(wedFile.Get); {����㧪� ������樨}
  wedFile.Done; {㭨�⮦���� ��⮪�}
  if wedCol=nil then {�������� �� ����㦥��?}
   begin 
    wedCol:= New(PwedCol, Init(100,10)); {ᮧ����� ���⮩ ������樨}
    wedCol^.Duplicates:= true; {ࠧ�襭�� �㡫���⮢}
   end;
end;

{��࠭���� ������ � ��⮪}
procedure TwedApp.Storewed;
var
  wedFile: TBufStream;
begin
  wedFile.Init('wed.dat',stCreate,1024); {ᮧ����� ��⮪�}
  wedFile.Put(wedCol); {��࠭���� ������樨 � ��⮪}
  wedFile.Done; {㭨�⮦���� ��⮪�}
end;

{���������� ����⮢}
procedure TwedApp.Tick;
var
  Zero: integer;
  d:PDialog;
  R:TRect;
  res:Word;
  IL:PIntInputLine;
  Data: record
    Name: String[100];
    wedef: String[20];
    tkt: String[100];
    Mark: String[100]
  end;
begin
  {ᮧ����� �������}
  R.Assign(10,5,70,19);
  d:= New(PDialog, Init(R,'��⠭����� ������⢮ ����⮢'));
  with d^ do
   begin
    {ᮧ����� ��ப ����� � ��⪠��}
    R.Assign(21,2,58,3);
    IL:= New(PIntInputLine,Init(R,100));
    Insert(IL);
    R.Assign(1,2,19,3);
    Insert(New(PLabel, Init(R,'���-�� ����⮢',IL)));

    {ᮧ����� ������}
    R.Assign(14,11,26,13);
    Insert(New(PButton,Init(R,'OK',cmOK,bfDefault)));
    R.Assign(30,11,42,13);
    Insert(New(PButton,Init(R,'�⬥��',cmCancel,bfNormal)));
   end;

  res:= DeskTop^.ExecView(d); {����� �������}
  if res=cmOK then {����� ������ OK}
   begin
	IL^.IsInt;
	if (IL^.int = true)
	then begin
		val(IL^.Data^, TicketsCount, Zero);
		Add;
	end else
		;
   end;
end;

{���������� �����}
procedure TwedApp.Add;
var
  d:PDialog;
  R:TRect;
  res:Word;
  IL:PInputLine;
  TicketNum: string[100];
  TicketNumInt: integer;
  Data: record
    Name: String[100];
    wed: String[20];
    Mark: String[100];
  end;
begin
  {ᮧ����� �������}
  R.Assign(10,5,70,19);
  d:= New(PDialog, Init(R,'���������� �����'));
  with d^ do
   begin
    {ᮧ����� ��ப ����� � ��⪠��}
    R.Assign(20,2,58,3);
    IL:= New(PInputLine,Init(R,100));
    Insert(IL);
    R.Assign(1,2,19,3);
    Insert(New(PLabel, Init(R,'���',IL)));

    R.Assign(20,4,40,5);
    IL:= New(PInputLine,Init(R,20));
    Insert(IL);
    R.Assign(1,4,19,5);
    Insert(New(PLabel, Init(R,'����⪠',IL)));
	
	randomize; b:=true; 
	if PunchetTicketsCouts < TicketsCount
		then
			begin repeat
				TicketNumInt := random(TicketsCount) + 1;
				str(TicketNumInt, TicketNum);
				if not (TicketNumInt in a)
					then begin
						inc(PunchetTicketsCouts);
						include(a, TicketNumInt);
						b:=false;
						end
					else b:=true;
				until(b = false)
			end
		else begin
			TicketsCount:=0;
			PunchetTicketsCouts:=0;
			end;
	
	if TicketsCount > 0 then
	begin
    R.Assign(20,6,58,7);
    Insert(New(PStaticText,Init(R,TicketNum)));
    R.Assign(2,6,19,7);
	Insert(New(PStaticText,Init(R,'����� �')));
	end else
	begin
	R.Assign(16,6,55,7);
	Insert(New(PStaticText,Init(R,'������ ������⢮ ����⮢')));
	end;
    R.Assign(20,8,40,9);
	IL:= New(PInputLine,Init(R,100));
    Insert(IL);
    R.Assign(1,8,19,9);
    Insert(New(PLabel, Init(R,'�業��',IL)));

    {ᮧ����� ������}
	if TicketsCount > 0 then
	begin
    R.Assign(14,11,26,13);
    Insert(New(PButton,Init(R,'OK',cmOK,bfDefault)));
	end;
    R.Assign(30,11,42,13);
    Insert(New(PButton,Init(R,'�⬥��',cmCancel,bfNormal)));
   end;

  res:= DeskTop^.ExecView(d); {����� �������}
  if res = cmOK then {����� ������ OK}
   begin
     d^.GetData(Data); {����祭�� ������ �������}
     {���������� � �������� ����� �����}
     wedCol^.Insert(New(Pwed, 
       Init(Data.Name,Data.wed,TicketNum,Data.Mark)));
     wedLB^.SetRange(wedCol^.Count); {��������� ������⢠ ����ᥩ � ᯨ᪥}
     wedLB^.DrawView; {����������}
   end;
   if (res = cmCancel) and (TicketsCount > 0) then
    begin
	dec(PunchetTicketsCouts);
	exclude(a, TicketNumInt);
	end;
end;

{㤠����� �����}
procedure TwedApp.Del;
var
  k:integer;
begin
  if wedCol^.Count=0 then exit; {�᫨ ��� ����ᥩ - ��室 �� ��楤���}
  if MessageBox('������� ������?',nil,mfOKCancel)=cmOK then {���⢥ত���� 㤠�����}
   begin
     k:= wedLB^.Focused; {�뤥����� �����}
     if k>=0 then
      begin
       wedCol^.AtDelete(k); {㤠����� ����� �� ������樨}
       wedLB^.SetRange(wedCol^.Count); {��������� ������⢠ ����ᥩ � ᯨ᪥}
       wedLB^.DrawView; {����������}
      end;
   end;
end;

{���� �����}
procedure TwedApp.Find;
var
  d:PDialog;
  R:TRect;
  res:Word;
  IL:PInputLine;
  k:integer;
  Data: record
    Name: String[100];
  end;
begin
  {ᮧ����� �������}
  R.Assign(12,5,68,13);
  d:= New(PDialog, Init(R,'���� �����'));
  with d^ do
   begin
    {ᮧ����� ��ப� ����� � ��⪮�}
    R.Assign(20,2,54,3);
    IL:= New(PInputLine,Init(R,100));
    Insert(IL);
    R.Assign(1,2,19,3);
    Insert(New(PLabel, Init(R,'���',IL)));

    {ᮧ����� ������}
    R.Assign(14,5,26,7);
    Insert(New(PButton,Init(R,'OK',cmOK,bfDefault)));
    R.Assign(30,5,42,7);
    Insert(New(PButton,Init(R,'�⬥��',cmCancel,bfNormal)));
   end;

  res:= DeskTop^.ExecView(d); {����� �������}
  if res=cmOK then  {����� ������ OK}
   begin
     d^.GetData(Data); {����祭�� ������ �������}
     if wedCol^.Search(Pointer(@Data.Name),k) then {���� �����}
       wedLB^.FocusItem(k)  {�뤥����� ��������� �����}
     else
       MessageBox('������ �� �������',nil,mfOKButton); {ᮮ�饭��, �� ������ �� �������}

   end;
end;

{��ࠡ��稪 ᮡ�⨩}
procedure TwedApp.HandleEvent(var Event:TEvent);
begin
  inherited HandleEvent(Event); {�맮� ��ࠡ��稪� �������� ��ꥪ�}
  if Event.What=evCommand then {������}
   begin
    case Event.Command of 
	  cmTick: Tick;
      cmAdd: Add; {���������� �����}
      cmDel: Del; {㤠����� �����}
      cmFind: Find; {���� �����}
    else
      Exit;
    end;
    ClearEvent(Event); {��� ᮡ���}
   end;
end;

{���樠������ ����}
procedure TwedApp.InitMenuBar;
var
  R:TRect;
begin
  GetExtent(R);
  R.B.Y:= R.A.Y + 1;
  MenuBar:= New(PMenuBar, Init(R, NewMenu(
    NewSubMenu('�����',hcNoContext,NewMenu(
	  NewItem('������ ���-�� ����⮢','F2',kbF2,cmTick,hcNoContext,
      NewItem('��������','F3',kbF3,cmAdd,hcNoContext,
      NewItem('�������','F4',kbF4,cmDel,hcNoContext,
      NewItem('����','F7',kbF7,cmFind,hcNoContext,
      nil))))),
    NewItem('��室','Alt-X',kbAltX,cmQuit,hcNoContext,nil)
  ))));
end;

{���樠������ ��ப� �����}
procedure TwedApp.InitStatusLine;
var
  R:TRect;
begin
  GetExtent(R);
  R.A.Y:= R.B.Y - 1;
  StatusLine:= New(PStatusLine,
    Init(R,
      NewStatusDef(0,$FFFF,
		NewStatusKey('~F2~ ������ ���-�� ����⮢',kbF2,cmTick,
        NewStatusKey('~F3~ ��������',kbF3,cmAdd,
        NewStatusKey('~F4~ �������',kbF4,cmDel,
        NewStatusKey('~F7~ ����',kbF7,cmFind,
        NewStatusKey('~F10~ ����',kbF10,cmMenu,
        NewStatusKey('~Alt-X~ ��室',kbAltX,cmQuit,
        nil)))))),
      nil)
  ));
end;

{�������� �ਫ������}
destructor TwedApp.Done;
begin
  Storewed; {��࠭���� ������ � ��⮪}
  Dispose(wedCol,Done); {㭨�⮦���� ������樨}
  inherited Done; {�맮� �������� �������� �����}
end;

{****************************************************************}

var
  wedapp: TwedApp; {�ਫ������}

begin
  wedapp.Init; {���樠������ �ਫ������}
  wedapp.Run;  {�믮������ �ਫ������}
  wedapp.Done; {�����⨥ �ਫ������}
end.