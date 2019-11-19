unit VSoft.Uri.Impl;

interface

uses
  VSoft.Uri;

type
  TUriImpl = class(TInterfacedObject, IUri)
  private
    FOriginal : string;
    FDecoded  : boolean;
    FScheme: string;
    FUsername: string;
    FPassword: string;
    FHost: string;
    FPort: integer;
    FPath: string;
    FFragment : string;
    FQueryParams : TArray<TQueryParam>;
    FHasAuthority : boolean;
  protected
    function GetFragment: string;
    function GetHasAuthority: Boolean;
    function GetHost: string;
    function GetIsEmpty: Boolean;
    function GetIsFile: Boolean;
    function GetIsUnc: Boolean;
    function GetOriginal: string;
    function GetPassword: string;
    function GetPort: Integer;
    function GetQueryParams: TArray<TQueryParam>;
    function GetScheme: string;
    function GetUsername: string;
    function GetAbsoluteUri: string;
    function GetLocalPath: string;



    procedure SetFragment(const value: string);
    procedure SetHost(const value: string);
    procedure SetPassword(const value: string);
    procedure SetPath(const value: string);
    procedure SetPort(const value: Integer);
    procedure SetQueryParams(const value: TArray<TQueryParam>);
    procedure SetScheme(const value: string);
    procedure SetUsername(const value: string);
    function GetAbsolutePath: string;
  public
    constructor Create(const originalString : string; const decoded : boolean;
                       const scheme, username, password, host, path, fragement : string;
                       const port : integer; const queryParams : TArray<TQueryParam>;
                       const hasAuthority : boolean);overload;
    constructor Create(const originalString : string);overload;
    function ToString: string;override;

    class function GetDefaultPortForScheme(const scheme: string): integer;
  end;

implementation

uses
  System.SysUtils;

{ TUriImpl }

constructor TUriImpl.Create(const originalString: string; const decoded: boolean; const scheme, username, password, host, path, fragement: string; const port: integer; const queryParams: TArray<TQueryParam>; const hasAuthority: boolean);
begin
  FOriginal := originalString;
  FDecoded  := decoded;
  FScheme := scheme;
  FUsername := username;
  FPassword := password;
  FHost := host;
  FPath := path;
  FFragment := fragement;
  FQueryParams := queryParams;
  FPort := port;
  FHasAuthority := hasAuthority;

end;

constructor TUriImpl.Create(const originalString: string);
begin
  FOriginal := originalString;
end;

function TUriImpl.GetAbsolutePath: string;
begin
  result := '/' + FPath;
end;

function TUriImpl.GetAbsoluteUri: string;
var
  sAuth: string;
  i : integer;
begin
  if FUsername <> '' then
    if FPassword <> '' then
      sAuth := FUsername + ':' + FPassword + '@'
    else
      sAuth := FUsername + '@'
  else
    sAuth := '';
  if FScheme <> '' then
  begin
    if FHasAuthority then
      result := LowerCase(FScheme) + '://'
    else
      result := FScheme + ':';
  end else
    result := '';

  result := result + sAuth + FHost;
  if (FPort > 0) and (FPort <> GetDefaultPortForScheme(FScheme)) and ((FScheme = 'https')  or  (FScheme = 'https')) then
    result := result + ':' + IntToStr(FPort);
  if FPath <> '' then
  begin
    if FHasAuthority then
      result := result + '/' + FPath
    else
      result := result + FPath

  end;
  if Length(FQueryParams) > 0 then
  begin
    result := result + '?';
    for i := 0 to Length(FQueryParams) - 1 do
    begin
      if i > 0  then
        result := result + '&';
      result := result + FQueryParams[i].Name + '=' + FQueryParams[i].Value;
    end;
  end;
  if FFragment <> '' then
    result := result + '#' + FFragment;
end;

class function TUriImpl.GetDefaultPortForScheme(const scheme: string): integer;
begin
  result := -1;
  if scheme = 'http' then
    exit(80);
  if scheme = 'https' then
    exit(443);
end;

function TUriImpl.GetFragment: string;
begin
  result := FFragment;
end;

function TUriImpl.GetHasAuthority: Boolean;
begin
  result := FHasAuthority;
end;

function TUriImpl.GetHost: string;
begin
  result := FHost;
end;

function TUriImpl.GetIsEmpty: Boolean;
begin
  result := FScheme = '';
end;

function TUriImpl.GetIsFile: Boolean;
begin
  result := FScheme = 'file';
end;

function TUriImpl.GetIsUnc: Boolean;
begin
  result := (FScheme = 'file') and (FHost <> '');
end;

function TUriImpl.GetLocalPath: string;
begin
  if FScheme = 'file' then
  begin
    result := StringReplace(FPath, '/', '\', [rfReplaceAll] );
    if FHost <> '' then
      result := '\\' + FHost + '\' + result;
  end
  else
    result := '/' + FPath;
end;

function TUriImpl.GetOriginal: string;
begin
  result := FOriginal;
end;

function TUriImpl.GetPassword: string;
begin
  result := FPassword;
end;


function TUriImpl.GetPort: Integer;
begin
  result := FPort;
end;

function TUriImpl.GetQueryParams: System.TArray<TQueryParam>;
begin
  result := FQueryParams;
end;

function TUriImpl.GetScheme: string;
begin
  result := FScheme;
end;

function TUriImpl.GetUsername: string;
begin
  result := FUsername;
end;

procedure TUriImpl.SetFragment(const value: string);
begin
  FFragment := value;
end;

procedure TUriImpl.SetHost(const value: string);
begin
  FHost := value;
end;

procedure TUriImpl.SetPassword(const value: string);
begin
  FPassword  := value;
end;

procedure TUriImpl.SetPath(const value: string);
begin
  FPath := value;
end;

procedure TUriImpl.SetPort(const value: Integer);
begin
  FPort := value;
end;

procedure TUriImpl.SetQueryParams(const value: TArray<TQueryParam>);
begin
  FQueryParams := Value;
end;

procedure TUriImpl.SetScheme(const value: string);
begin
  FScheme := value;
end;

procedure TUriImpl.SetUsername(const value: string);
begin
  FUsername := value;
end;

function TUriImpl.ToString: string;
begin
  result := GetAbsoluteUri;
end;

end.
