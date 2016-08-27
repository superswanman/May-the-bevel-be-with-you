unit UMTBBWY;

interface

uses
  Winapi.Windows, System.Rtti, Vcl.Controls, Vcl.Forms, Vcl.ExtCtrls;

implementation

var
  AfterConstructionRefAddr: Pointer;
  OrgAfterConstruction: procedure(Self: TObject);

procedure AltAfterConstruction(Self: TObject);

  procedure EnumControls(Control: TWinControl);
  var
    i: Integer;

    function HasChildPanel(Control: TWinControl): Boolean;
    var
      i: Integer;
    begin
      for i := 0 to Control.ControlCount-1 do
        if Control.Controls[i] is TPanel then Exit(True);
      Result := False;
    end;

  begin
    if Control is TPanel then
    begin
      Control.Height := Control.Height + 2;
      if not HasChildPanel(Control) then
        TPanel(Control).BevelOuter := bvLowered;
    end;

    for i := 0 to Control.ControlCount-1 do
    begin
      if Control.Controls[i] is TWinControl then
        EnumControls(TWinControl(Control.Controls[i]));
    end;
  end;

begin
  OrgAfterConstruction(Self);
  EnumControls(TWinControl(Self));
end;

procedure InstallHook;
var
  ctx: TRttiContext;
  typ: TRttiType;
  meth: TRttiMethod;
  oldProtect: DWORD;
begin
  typ := ctx.FindType('ComPrgrs.TProgressForm');
  if typ = nil then Exit;
  meth := typ.GetMethod('AfterConstruction');
  if meth = nil then Exit;

  AfterConstructionRefAddr := PPointer(NativeInt(TRttiInstanceType(typ).MetaclassType) + meth.VirtualIndex * SizeOf(Pointer));
  VirtualProtect(AfterConstructionRefAddr, SizeOf(Pointer), PAGE_READWRITE, oldProtect);
  @OrgAfterConstruction := PPointer(AfterConstructionRefAddr)^;
  PPointer(AfterConstructionRefAddr)^ := @AltAfterConstruction;
  VirtualProtect(AfterConstructionRefAddr, SizeOf(Pointer), oldProtect, oldProtect);
  FlushInstructionCache(GetCurrentProcess, AfterConstructionRefAddr, SizeOf(Pointer));
end;

procedure UninstallHook;
var
  oldProtect: DWORD;
begin
  if AfterConstructionRefAddr = nil then Exit;
  VirtualProtect(AfterConstructionRefAddr, SizeOf(Pointer), PAGE_READWRITE, oldProtect);
  PPointer(AfterConstructionRefAddr)^ := @OrgAfterConstruction;
  VirtualProtect(AfterConstructionRefAddr, SizeOf(Pointer), oldProtect, oldProtect);
  FlushInstructionCache(GetCurrentProcess, AfterConstructionRefAddr, SizeOf(Pointer));
end;

initialization
  InstallHook;
finalization
  UninstallHook;
end.
