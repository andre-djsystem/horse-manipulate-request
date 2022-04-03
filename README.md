# horse-manipulate-request
<b>horse-manipulate-request</b> is a middleware to manipulate request in APIs developed with the <a href="https://github.com/HashLoad/horse">Horse</a> framework.

## ⚙️ Installation
Installation is done using the [`boss install`](https://github.com/HashLoad/boss) command:
``` sh
boss install https://github.com/andre-djsystem/horse-manipulate-request
```
If you choose to install manually, simply add the following folders to your project, in *Project > Options > Resource Compiler > Directories and Conditionals > Include file search path*
```
../horse-manipulate-request/src
```

## ✔️ Compatibility
This middleware is compatible with projects developed in:
- [X] Delphi
- [X] Lazarus

## ⚡️ Quickstart Delphi
```delphi
uses 
  Horse, 
  Horse.ManipulateRequest, // It's necessary to use the unit
  System.SysUtils;

begin
  // It's necessary to add the middleware in the Horse:
  THorse.Use(ManipulateRequest(
    procedure(Req: THorseRequest);
	var
	  Version: String = '';
	begin
	  Req.Headers.TryGetValue('x-appversion', Version);
	  WriteLn(Format('Version: %s',[Version])); 
	end;));
    
  THorse.Get('/ping',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    begin
      Res.Send('pong');
    end);

  THorse.Listen(9000);
end;
```

## ⚡️ Quickstart Lazarus
```delphi
{$MODE DELPHI}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Horse,
  Horse.ManipulateRequest, // It's necessary to use the unit
  SysUtils;

procedure GetPing(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
begin
  Res.Send('Pong');
end;

procedure HandleRequest(Req: THorseRequest);
var
  Version: String = '';
begin
  Req.Headers.TryGetValue('x-appversion', Version);
  WriteLn(Format('Version: %s',[Version])); 
end;  

begin
  // It's necessary to add the middleware in the Horse:
  THorse.Use(ManipulateRequest(HandleRequest))

  THorse.Get('/ping', GetPing);

  THorse.Listen(9000);
end.
```

## ⚠️ License
`horse-manipulate-request` is free and open-source middleware licensed under the [MIT License](https://github.com/andre-djsystem/horse-manipulate-request/blob/master/LICENSE). 

 

