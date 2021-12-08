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
    function GetQueryString: string;
    function GetAbsolutePath: string;
    function GetBaseUriString : string;

    procedure SetFragment(const value: string);
    procedure SetHost(const value: string);
    procedure SetPassword(const value: string);
    procedure SetPath(const value: string);
    procedure SetPort(const value: Integer);
    procedure SetQueryParams(const value: TArray<TQueryParam>);
    procedure SetScheme(const value: string);
    procedure SetUsername(const value: string);
    procedure SetQueryString(const value: string);
  public
    constructor Create(const originalString : string; const decoded : boolean;
                       const scheme, username, password, host, path, fragement : string;
                       const port : integer; const queryParams : TArray<TQueryParam>;
                       const hasAuthority : boolean);overload;
    constructor Create(const originalString : string);overload;
    function ToString: string;override;

    class function GetDefaultPortForScheme(const scheme: string): integer;
  end;

type
  TStringSplitOptions = (None, ExcludeEmpty);

function Split(const value : string; const Separator: array of Char; Count: Integer;  Options: TStringSplitOptions): TArray<string>;

function SplitQueryString(const value : string) : TArray<TQueryParam>;


implementation

uses
  System.SysUtils;

function IndexOfAny(const value : string; const AnyOf: array of Char; StartIndex, Count: Integer): Integer;
var
  I: Integer;
  C: Char;
  Max: Integer;
begin
  if (StartIndex + Count) >= Length(value) then
    Max := Length(value)
  else
    Max := StartIndex + Count;

  I := StartIndex;
  while I < Max do
  begin
    for C in AnyOf do
      if value[I] = C then
        Exit(I);
    Inc(I);
  end;
  Result := -1;
end;



function Split(const value : string; const Separator: array of Char; Count: Integer;  Options: TStringSplitOptions): TArray<string>;
const
  DeltaGrow = 32;
var
  NextSeparator, LastIndex: Integer;
  Total: Integer;
  CurrentLength: Integer;
  S: string;
begin
  Total := 0;
  LastIndex := 1;
  CurrentLength := 0;
  NextSeparator := IndexOfAny(value, Separator, LastIndex, Length(value));
  while (NextSeparator >= 0) and (Total < Count) do
  begin
    S := Copy(value, LastIndex, NextSeparator - LastIndex);
    if (S <> '') or ((S = '') and (Options <> ExcludeEmpty)) then
    begin
      Inc(Total);
      if CurrentLength < Total then
      begin
        CurrentLength := Total + DeltaGrow;
        SetLength(Result, CurrentLength);
      end;
      Result[Total - 1] := S;
    end;
    LastIndex := NextSeparator + 1;
    NextSeparator := IndexOfAny(value, Separator, LastIndex, Length(value));
  end;

  if (LastIndex < Length(value)) and (Total < Count) then
  begin
    Inc(Total);
    SetLength(Result, Total);
    Result[Total - 1] := Copy(value, LastIndex, Length(value));
  end
  else
    SetLength(Result, Total);
end;


function SplitQueryString(const value : string) : TArray<TQueryParam>;
var
  pairs : TArray<string>;
  pair  : TArray<string>;
  i : integer;
begin
  SetLength(result, 0);
  if value = '' then
    exit;
  pairs := Split(value, ['&'], MaxInt, None);
  SetLength(result, Length(pairs));
  for i := 0 to Length(pairs) -1 do
  begin
    pair := Split(pairs[i], ['='], MaxInt, None);
    result[i].Name := pair[0];
    if length(pair) > 1 then
      result[i].Value := pair[1];
  end;
end;


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
  if (FPort > 0) and (FPort <> GetDefaultPortForScheme(FScheme)) and ((FScheme = 'http')  or  (FScheme = 'https')) then
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

function TUriImpl.GetBaseUriString: string;
begin
  result := FScheme + '://' + FHost;
  if FScheme = 'http' then
  begin
    if FPort <> 80 then
       result := result + ':' + IntToStr(FPort);
  end
  else if FScheme = 'https' then
  begin
    if FPort <> 443 then
       result := result + ':' + IntToStr(FPort);
  end;
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

function TUriImpl.GetQueryString: string;
var
  i : integer;
  l : integer;
begin
  result := '';
  l := Length(FQueryParams) - 1;
  if l > 0 then
  begin
    for i := 0 to l do
    begin
      result := FQueryParams[i].Name + '=' + FQueryParams[i].Value;
      if i < l then
        result := result + '&';
    end;
  end;

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

procedure TUriImpl.SetQueryString(const value: string);
begin
  FQueryParams := SplitQueryString(value);
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
