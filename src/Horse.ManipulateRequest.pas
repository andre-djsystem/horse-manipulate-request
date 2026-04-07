unit Horse.ManipulateRequest;

{$IF DEFINED(FPC)}
{$MODE DELPHI}{$H+}
{$ELSEIF CompilerVersion >= 36.0}
{$DEFINE EXTRACT_PARAM}
{$ENDIF}

interface

uses
{$IF DEFINED(FPC)}
  SysUtils, Classes,
{$ELSE}
  System.SysUtils, System.Classes,
{$IF CompilerVersion >= 36.0}
  Horse.Core,
  Horse.Core.RouterTree,
  DataSet.Serialize,
  System.RegularExpressions,
  System.Generics.Collections,
{$ENDIF}
{$ENDIF}
  Horse;

type
  THorseManipulateRequest = {$IF NOT DEFINED(FPC)} reference to {$ENDIF} procedure(Req: THorseRequest);

{$IFDEF EXTRACT_PARAM}
// Delphi-specific implementation for CompilerVersion >= 36.0 (Delphi 12+)
// No equivalent implementation for FPC at this time.
// Contributions to support FPC or earlier Delphi versions are welcome.

// Important to note that, this changes need Horse PR #450 (commit 0bc17019602655979f803faa33f0a8d16fa657be)
// other wise it will raise "Duplicated is not allowed) Horse.Core.RouterTree.NextCaller.TNextCaller.Init

type
  TRouteMatch = record
    Node: THorseRouterTree;
    Params: TDictionary<string, string>;
  end;

function ExtractParamFromHorseRoute(const APath: string): TRouteMatch;
{$ENDIF}
function ManipulateRequest(const AManipulateRequest: THorseManipulateRequest): THorseCallback; overload;
procedure Middleware(Req: THorseRequest; Res: THorseResponse; Next: {$IF DEFINED(FPC)} TNextProc {$ELSE} TProc {$ENDIF});

implementation

var
  ManipulateRequestCallBack: THorseManipulateRequest;

{$IFDEF EXTRACT_PARAM}
function ExtractParamFromHorseRoute(const APath: string): TRouteMatch;

  function WalkTree(
    ANode: THorseRouterTree;
    const AParts: TArray<string>;
    AIndex: Integer;
    AParams: TDictionary<string, string>
  ): THorseRouterTree;
  var
    LKey: string;
    LNext: THorseRouterTree;
    LParamName: string;
  begin
    Result := nil;

    // Found,
    if AIndex >= Length(AParts) then
      Exit(ANode);

    if AParts[AIndex].IsEmpty then
      Exit(WalkTree(ANode, AParts, AIndex + 1, AParams));

    // 100% match
    if ANode.Route.TryGetValue(AParts[AIndex], LNext) then
      Exit(WalkTree(LNext, AParts, AIndex + 1, AParams));

    // Find params
    for LKey in ANode.Route.Keys do
    begin
      if LKey.StartsWith(':') then
      begin
        LNext := ANode.Route.Items[LKey];

        // Get param name
        LParamName := LKey.Substring(1);

        // Save param value
        AParams.AddOrSetValue(LParamName, AParts[AIndex]);

        Result := WalkTree(LNext, AParts, AIndex + 1, AParams);

        if Assigned(Result) then
          Exit;

        // rollback (needed in case of multiple routes)
        AParams.Remove(LParamName);
      end;
    end;

    // Regex
    for LKey in ANode.Route.Keys do
    begin
      if LKey.StartsWith('(') and LKey.EndsWith(')') then
      begin
        {$IFNDEF FPC}
        if TRegEx.IsMatch(AParts[AIndex], '^' + LKey + '$') then
        {$ENDIF}
        begin
          LNext := ANode.Route.Items[LKey];
          Exit(WalkTree(LNext, AParts, AIndex + 1, AParams));
        end;
      end;
    end;
  end;

  function Normalize(const APath: string): string;
  begin
    Result := '/' + APath.Trim(['/']);
  end;

begin
  Result.Params := TDictionary<string, string>.Create;
  Result.Node := WalkTree(
    THorseCore.Routes,
    Normalize(APath).Split(['/']),
    0,
    Result.Params
  );

  // Free memory if didn't find any
  if not Assigned(Result.Node) then
  begin
    Result.Params.Free;
    Result.Params := nil;
  end;
end;
{$ENDIF}

function ManipulateRequest(
  const AManipulateRequest: THorseManipulateRequest): THorseCallback;
begin
  ManipulateRequestCallBack := AManipulateRequest;
  Result := Middleware;
end;

procedure Middleware(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
{$IFDEF EXTRACT_PARAM}
var
  LKeySource: string;
  LRouteMatch: TRouteMatch;
{$ENDIF}
begin
  try
{$IFDEF EXTRACT_PARAM}
    (*
    This process is needed to load the URL params, since this middleware runs
    after the process that de-serialize this info
    *)
    LRouteMatch := ExtractParamFromHorseRoute(Req.PathInfo);
    try
      if (LRouteMatch.Params.Count > 0) then
      begin
        for LKeySource in LRouteMatch.Params.Keys do
        begin
          if LKeySource.Trim.IsEmpty then
            Continue;
          Req.Params.Dictionary.AddOrSetValue(LKeySource, LRouteMatch.Params.Items[LKeySource]);
        end;
      end;
    finally
      LRouteMatch.Params.Free;
    end;
{$ENDIF}
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


