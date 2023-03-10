uses IntInp, App,Objects,Menus,Drivers,Views,Dialogs,Strings,MsgBox;

const

{команды}
cmAdd  = 200;  {добавить запись}
cmDel  = 201;  {удалить запись}
cmFind = 202;  {поиск записи}
cmTick = 203;  {установить количество билетов}

type

{объект - запись о телефоне}
Pwed = ^Twed;
Twed = object(TObject)
  Name,wedef,tkt,Mark:PString; 
  constructor Init(NewName,Newwedef,Newtkt,NewMark:String);
  constructor Load(var S:TStream);
  procedure Store(var S:TStream); virtual;
  destructor Done; virtual;
end;

{объект - коллекция записей}
PwedCol = ^TwedCol;
TwedCol = object(TSortedCollection)
  function KeyOf(Item: Pointer): Pointer; virtual;
  function Compare(Key1, Key2: Pointer): Integer; virtual;
end;

{объект - отображаемый список записей}
PwedListBox = ^TwedListBox;
TwedListBox = object(TListBox)
  function GetText(Item: Integer; MaxLen: Integer): String; virtual;
end;

{объект - приложение}
PwedApp = ^TwedApp;
TwedApp = object(TApplication)
  wedCol: PwedCol; {коллекция записей}
  wedLB: PwedListBox; {отображаемый список записей}
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

{структуры для регистрации класса Twed (сохранение/загрузка из протока)}
Rwed: TStreamRec = (
  ObjType: 100;
  VmtLink: Ofs(TypeOf(Twed)^);
  Load: @Twed.Load; {}
  Store: @Twed.Store
);

{структуры для регистрации класса TwedCol (сохранение/загрузка из протока)}
RwedCol: TStreamRec = (
  ObjType: 101;
  VmtLink: Ofs(TypeOf(TwedCol)^);
  Load: @TwedCol.Load;
  Store: @TwedCol.Store
);

{****************************************************************}

{конструктор}
constructor Twed.Init(NewName,Newwedef,Newtkt,NewMark:String);
begin
  Name:= NewStr(NewName);  {ФИО}
  wedef:= NewStr(Newwedef); {Номер зачётки}
  tkt:= NewStr(Newtkt); {Билет}
  Mark:= NewStr(NewMark); {Оценка}
end;

{конструктор загрузки из потока}
constructor Twed.Load(var S:TStream);
begin
  Name:= S.ReadStr;  {ФИО}
  wedef:= S.ReadStr; {Номер зачётки}
  tkt:= S.ReadStr; {Билет}
  Mark:= S.ReadStr; {Оценка}
end;

{сохранение в поток}
procedure Twed.Store(var S:TStream);
begin
  S.WriteStr(Name);  {ФИО}
  S.WriteStr(wedef); {Номер зачётки}
  S.WriteStr(tkt); {Билет}
  S.WriteStr(Mark); {Оценка}
end;

{деструктор}
destructor Twed.Done;
begin
  {освобождение памяти}
  if Name<>nil then Dispose(Name);
  if wedef<>nil then Dispose(wedef);
  if tkt<>nil then Dispose(tkt);
  if Mark<>nil then Dispose(Mark);
end;

{****************************************************************}

{ключ элемента коллекции}
function TwedCol.KeyOf(Item: Pointer): Pointer;
begin
  KeyOf:= Pwed(Item)^.Name; {ФИО}
end;

{Функция сравнения ключей}
function TwedCol.Compare(Key1, Key2: Pointer): Integer;
begin
  if PString(Key1)^ = PString(Key2)^ then {ключи равны}
    Compare:= 0
  else if PString(Key1)^ < PString(Key2)^ then {первый ключ больше}
    Compare:= -1
  else
    Compare:= 1;
end;

{****************************************************************}

{Формирование текста для отображение элемента списка}
function TwedListBox.GetText(Item: Integer; MaxLen: Integer): String;
var
  p: Pwed;
  s,s1: string;
  par:array [0..3] of Longint;
begin
  p:= PwedCol(List)^.At(Item); {Получение элемента}
  par[0]:= Longint(p^.Name); {ФИО}
  par[1]:= Longint(p^.wedef); {Номер зачётки}
  par[2]:= Longint(p^.tkt); {Билет}
  par[3]:= Longint(p^.Mark); {Оценка}
  FormatStr(s,'%-29s│%-19s│%-13s│%-13s',par); {формирование строки}
  GetText:= s; {результат}
end;

{****************************************************************}
{конструктор приложения}
constructor TwedApp.Init;
var
  R:TRect;
  x1,y1,x2,y2:integer;
  SB:PScrollBar;
  D: PDialog;
begin
  inherited Init; {вызов конструктора базового объекта}

  {регистрация классов записи/чтения их из потока}
  RegisterType(Rwed); 
  RegisterType(RwedCol);

  Loadwed;  {загрузка данных}

  GetExtent(R);
  R.A.Y:= R.A.Y;
  R.B.Y:= R.B.Y-2;
  D:= New(PDialog,Init(R,'Ведомость')); {окно отображения записей}
  D^.Palette:= wpBlueWindow; {палитра окна}
  with D^ do
   begin
    {запрещение кнопок закрытия, увеличения, перемещения и раскрытия окна}
    Flags:= Flags and not (wfClose + wfGrow + wfMove + wfZoom);

    {размер окна}
    GetExtent(R);
    x1:= R.A.X;
    y1:= R.A.Y;
    x2:= R.B.X;
    y2:= R.B.Y;

    {добавление текста (шапки для таблицы записей)}
    R.Assign(x1+1,y1+1,x2-1,y1+3);
    Insert(New(PStaticText, Init(R,
     '          ФИО                 │   Номер зачётки   │   Билет №   │   Отметка   ' +
     '──────────────────────────────┼───────────────────┼─────────────┼─────────────'
    )));

    {добавление полосы прокрутки} 
    R.Assign(x2-1,y1+1,x2,y2-1);
    New(SB,Init(R));
    Insert(SB);

    {добавление отображаемого списка}
    R.Assign(x1+1,y1+3,x2-1,y2-1);
    wedLB:= New(PwedListBox, Init(R,1,SB));
    wedLB^.NewList(wedCol);
    Insert(wedLB);
   end;
  
  DeskTop^.Insert(D); {вставка диалога в DeskTop}
end;

{загрузка данных из потока}
procedure TwedApp.Loadwed;
var
  wedFile: TBufStream;
begin
  wedFile.Init('wed.dat',stOpen,1024); {создание потока}
  wedCol:= PwedCol(wedFile.Get); {загрузка коллекции}
  wedFile.Done; {уничтожение потока}
  if wedCol=nil then {коллекция не загружена?}
   begin 
    wedCol:= New(PwedCol, Init(100,10)); {создание пустой коллекции}
    wedCol^.Duplicates:= true; {разрешение дубликатов}
   end;
end;

{сохранение данных в поток}
procedure TwedApp.Storewed;
var
  wedFile: TBufStream;
begin
  wedFile.Init('wed.dat',stCreate,1024); {создание потока}
  wedFile.Put(wedCol); {сохранение коллекции в поток}
  wedFile.Done; {уничтожение потока}
end;

{добавление билетов}
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
  {создание диалога}
  R.Assign(10,5,70,19);
  d:= New(PDialog, Init(R,'Установить количество билетов'));
  with d^ do
   begin
    {создание строк ввода с метками}
    R.Assign(21,2,58,3);
    IL:= New(PIntInputLine,Init(R,100));
    Insert(IL);
    R.Assign(1,2,19,3);
    Insert(New(PLabel, Init(R,'Кол-во билетов',IL)));

    {создание кнопок}
    R.Assign(14,11,26,13);
    Insert(New(PButton,Init(R,'OK',cmOK,bfDefault)));
    R.Assign(30,11,42,13);
    Insert(New(PButton,Init(R,'Отмена',cmCancel,bfNormal)));
   end;

  res:= DeskTop^.ExecView(d); {запуск диалога}
  if res=cmOK then {нажата кнопка OK}
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

{добавление записи}
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
  {создание диалога}
  R.Assign(10,5,70,19);
  d:= New(PDialog, Init(R,'Добавление записи'));
  with d^ do
   begin
    {создание строк ввода с метками}
    R.Assign(20,2,58,3);
    IL:= New(PInputLine,Init(R,100));
    Insert(IL);
    R.Assign(1,2,19,3);
    Insert(New(PLabel, Init(R,'ФИО',IL)));

    R.Assign(20,4,40,5);
    IL:= New(PInputLine,Init(R,20));
    Insert(IL);
    R.Assign(1,4,19,5);
    Insert(New(PLabel, Init(R,'Зачётка',IL)));
	
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
	Insert(New(PStaticText,Init(R,'Билет №')));
	end else
	begin
	R.Assign(16,6,55,7);
	Insert(New(PStaticText,Init(R,'Введите количество билетов')));
	end;
    R.Assign(20,8,40,9);
	IL:= New(PInputLine,Init(R,100));
    Insert(IL);
    R.Assign(1,8,19,9);
    Insert(New(PLabel, Init(R,'Оценка',IL)));

    {создание кнопок}
	if TicketsCount > 0 then
	begin
    R.Assign(14,11,26,13);
    Insert(New(PButton,Init(R,'OK',cmOK,bfDefault)));
	end;
    R.Assign(30,11,42,13);
    Insert(New(PButton,Init(R,'Отмена',cmCancel,bfNormal)));
   end;

  res:= DeskTop^.ExecView(d); {запуск диалога}
  if res = cmOK then {нажата кнопка OK}
   begin
     d^.GetData(Data); {получение данных диалога}
     {добавление в коллекцию новой записи}
     wedCol^.Insert(New(Pwed, 
       Init(Data.Name,Data.wed,TicketNum,Data.Mark)));
     wedLB^.SetRange(wedCol^.Count); {изменение количества записей в списке}
     wedLB^.DrawView; {обновление}
   end;
   if (res = cmCancel) and (TicketsCount > 0) then
    begin
	dec(PunchetTicketsCouts);
	exclude(a, TicketNumInt);
	end;
end;

{удаление записи}
procedure TwedApp.Del;
var
  k:integer;
begin
  if wedCol^.Count=0 then exit; {если нет записей - выход из процедуры}
  if MessageBox('Удалить запись?',nil,mfOKCancel)=cmOK then {подтверждение удаления}
   begin
     k:= wedLB^.Focused; {выделенный элемент}
     if k>=0 then
      begin
       wedCol^.AtDelete(k); {удаление элемента из коллекции}
       wedLB^.SetRange(wedCol^.Count); {изменение количества записей в списке}
       wedLB^.DrawView; {обновление}
      end;
   end;
end;

{Поиск записи}
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
  {создание диалога}
  R.Assign(12,5,68,13);
  d:= New(PDialog, Init(R,'Поиск записи'));
  with d^ do
   begin
    {создание строки ввода с меткой}
    R.Assign(20,2,54,3);
    IL:= New(PInputLine,Init(R,100));
    Insert(IL);
    R.Assign(1,2,19,3);
    Insert(New(PLabel, Init(R,'ФИО',IL)));

    {создание кнопок}
    R.Assign(14,5,26,7);
    Insert(New(PButton,Init(R,'OK',cmOK,bfDefault)));
    R.Assign(30,5,42,7);
    Insert(New(PButton,Init(R,'Отмена',cmCancel,bfNormal)));
   end;

  res:= DeskTop^.ExecView(d); {запуск диалога}
  if res=cmOK then  {нажата кнопка OK}
   begin
     d^.GetData(Data); {получение данных диалога}
     if wedCol^.Search(Pointer(@Data.Name),k) then {поиск записи}
       wedLB^.FocusItem(k)  {выделение найденной записи}
     else
       MessageBox('Запись не найдена',nil,mfOKButton); {сообщение, что запись не найдена}

   end;
end;

{обработчик событий}
procedure TwedApp.HandleEvent(var Event:TEvent);
begin
  inherited HandleEvent(Event); {вызов обработчика бозового объекта}
  if Event.What=evCommand then {комана}
   begin
    case Event.Command of 
	  cmTick: Tick;
      cmAdd: Add; {добавление записи}
      cmDel: Del; {удаление записи}
      cmFind: Find; {поиск записи}
    else
      Exit;
    end;
    ClearEvent(Event); {сброс события}
   end;
end;

{инициализация меню}
procedure TwedApp.InitMenuBar;
var
  R:TRect;
begin
  GetExtent(R);
  R.B.Y:= R.A.Y + 1;
  MenuBar:= New(PMenuBar, Init(R, NewMenu(
    NewSubMenu('Записи',hcNoContext,NewMenu(
	  NewItem('Задать кол-во билетов','F2',kbF2,cmTick,hcNoContext,
      NewItem('Добавить','F3',kbF3,cmAdd,hcNoContext,
      NewItem('Удалить','F4',kbF4,cmDel,hcNoContext,
      NewItem('Найти','F7',kbF7,cmFind,hcNoContext,
      nil))))),
    NewItem('Выход','Alt-X',kbAltX,cmQuit,hcNoContext,nil)
  ))));
end;

{инициализация строки статуса}
procedure TwedApp.InitStatusLine;
var
  R:TRect;
begin
  GetExtent(R);
  R.A.Y:= R.B.Y - 1;
  StatusLine:= New(PStatusLine,
    Init(R,
      NewStatusDef(0,$FFFF,
		NewStatusKey('~F2~ Задать кол-во билетов',kbF2,cmTick,
        NewStatusKey('~F3~ Добавить',kbF3,cmAdd,
        NewStatusKey('~F4~ Удалить',kbF4,cmDel,
        NewStatusKey('~F7~ Найти',kbF7,cmFind,
        NewStatusKey('~F10~ Меню',kbF10,cmMenu,
        NewStatusKey('~Alt-X~ Выход',kbAltX,cmQuit,
        nil)))))),
      nil)
  ));
end;

{деструктор приложения}
destructor TwedApp.Done;
begin
  Storewed; {сохранение данных в поток}
  Dispose(wedCol,Done); {уничтожение коллекции}
  inherited Done; {вызов деструктора базового класса}
end;

{****************************************************************}

var
  wedapp: TwedApp; {приложение}

begin
  wedapp.Init; {инициализация приложения}
  wedapp.Run;  {выполнение приложения}
  wedapp.Done; {закрытие приложения}
end.