unit Horse.ManipulateRequest;

{$IF DEFINED(FPC)}
{$MODE DELPHI}{$H+}
{$ENDIF}

interface

uses
{$IF DEFINED(FPC)}
  SysUtils, Classes,
{$ELSE}
  System.SysUtils, System.Classes,
{$ENDIF}
  Horse;

type
  THorseManipulateRequest = {$IF NOT DEFINED(FPC)} reference to {$ENDIF} procedure(Req: THorseRequest);

function ManipulateRequest(const AManipulateRequest: THorseManipulateRequest): THorseCallback; overload;
procedure Middleware(Req: THorseRequest; Res: THorseResponse; Next: {$IF DEFINED(FPC)} TNextProc {$ELSE} TProc {$ENDIF});

implementation

var
  ManipulateRequestCallBack: THorseManipulateRequest;

function ManipulateRequest(
  const AManipulateRequest: THorseManipulateRequest): THorseCallback;
begin
  ManipulateRequestCallBack := AManipulateRequest;
  Result := Middleware;
end;

procedure Middleware(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
begin
  try
    ManipulateRequestCallBack(Req);
  except
    on E: exception do
    begin
      Res.Send(E.Message).Status(THTTPStatus.InternalServerError);
      raise EHorseCallbackInterrupted.Create;
    end;
  end;

  Next();
end;



end.


