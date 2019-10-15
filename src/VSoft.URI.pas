unit VSoft.URI;

interface

type
  TQueryParam = record
    Name : string;
    Value : string;
  end;

//TODO : Encoding/Decoding'

  TURI = record
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
    function GetIsEmpty : boolean;
    procedure SetQueryParams(const Value: TArray<TQueryParam>);
    class function GetDefaultPortForScheme(const scheme : string) : integer;static;
    class function InternalParse(const uriString : string; const decode : boolean) : TURI;static;
    constructor Create(const originalString : string; const decoded : boolean; 
                       const scheme, username, password, host, path, fragement : string; 
                       const port : integer; const queryParams : TArray<TQueryParam>;
                       const hasAuthority : boolean);overload;
    constructor Create(const originalString : string);overload; 
  public
    class function Parse(const uriString : string; const decode : boolean = true) : TURI;static;
    class function TryParse(const uriString : string; const decode : boolean; out value : TURI) : boolean;static;
    class function TryParseWithError(const uriString : string; const decode : boolean; out value : TURI; out error : string) : boolean;static;
    class function Empty : TURI; static;
    function ToString() : string;
    property OriginalUriString : string read FOriginal;
    property Scheme   : string read FScheme write FScheme;
    property UserName : string read FUsername write FUsername;
    property Password : string read FPassword write FPassword;
    property Host     : string read FHost     write FHost;
    property Port     : integer read FPort     write FPort;
    property Path     : string read FPath     write FPath;
    property QueryParams : TArray<TQueryParam> read FQueryParams write SetQueryParams;
    property Fragment : string read FFragment write FFragment;
  end;

implementation

uses
  System.Types,
  System.SysUtils;


const
  Alpha = ['A'..'Z', 'a'..'z', '_'];
  Numeric =  ['0'..'9'];
  AlphaNumeric = Alpha + Numeric;
  SchemeChars = Alpha + ['.', '+', '-'];
  
{$WARN WIDECHAR_REDUCED OFF} 
function IsAlpha(const c : Char) : boolean;
begin
  result := c in Alpha;
end;

function IsAlphaNumeric(const c : Char) : boolean;
begin
  result := c in AlphaNumeric;
end;

function IsSchemeChar(const c : Char) : boolean;
begin
  result := c in SchemeChars;
end;

function IsNumeric(const c : Char) : boolean;
begin
  result := c in Numeric;
end;

{$WARN 	WIDECHAR_REDUCED ON}
{ TURI }

constructor TURI.Create(const originalString : string; const decoded : boolean; const scheme, username, password, host, path, fragement : string; const port : integer; const queryParams : TArray<TQueryParam>;const hasAuthority : boolean );
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


constructor TURI.Create(const originalString: string);
begin
  //empty on purpose;
end;

class function TURI.Empty: TURI;
begin
  result := TURI.Create('');
end;

class function TURI.GetDefaultPortForScheme(const scheme: string): integer;
begin
  result := -1;
  if scheme = 'http' then
    exit(80);
  if scheme = 'https' then
    exit(443);
 
end;

function TURI.GetIsEmpty: boolean;
begin
  result := FScheme = '';
end;


class function TURI.InternalParse(const uriString: string; const decode : boolean): TURI;
var
  sScheme : string;
  sUsername: string;
  sPassword: string;
  sHost: string;
  iPort: integer;
  sPath: string;
  sFragment : string;
  queryParams : TArray<TQueryParam>;  
  bHasAuthority : boolean;
  
  idx     : integer;
  len     : integer;
  function FindSchemeDelimiter(const limit: Integer): Integer;
  var
    i : Integer;
  begin
    result := -1; //assume there isn't a :
    for i := 1 to limit do
    begin
      case uriString[i] of
        '0'..'9', 'a'..'z', 'A'..'Z', '+', '-', '.': ; //valid scheme char, continue searching
        ':': exit(i);
      else
        //not a valid scheme char, and we haven't found the : yet so bomb out.
        exit(-2);
      end;
    end;
  end;

  procedure SplitQueryString(const value : string);
  var
    pairs : TArray<string>;
    pair  : TArray<string>;
    param : TQueryParam;
    i : integer;
  begin
    pairs := value.Split(['&']);
    SetLength(queryParams, Length(pairs));
    for i := 0 to Length(pairs) -1 do
    begin
      pair := pairs[i].Split(['=']);
      queryParams[i].Name := pair[0];
      if length(pair) > 1 then
        queryParams[i].Value := pair[1];
    end;
    
  end;
  
  
  //        userinfo       host      port
  //        ┌──┴───┐ ┌──────┴──────┐ ┌┴┐
  //https://john.doe@www.example.com:123/forum/questions/?tag=networking&order=newest#top
  //└─┬─┘   └───────────┬──────────────┘└───────┬───────┘ └───────────┬─────────────┘ └┬┘
  //scheme          authority                  path                 query           fragment
  procedure ParseWithAuthority;
  var
    i : integer;
    j : integer;
    sAuthority : string;
    sPort : string;
    sUserInfo : string;
    userParts : TArray<string>;
    sQueryString : string;
  begin
    bHasAuthority := true;
    iPort := -1;
    Inc(idx,2); // skip the //
    j := FindDelimiter('/,?,#',uriString, idx);
    if j > 0 then
    begin
      sAuthority := Copy(uriString,idx,j - idx);
      Inc(idx,j -idx);
    end
    else
    begin
      sAuthority := Copy(uriString,idx,len);
      idx := len;
    end;

    if Length(sAuthority) > 0 then
    begin   
      i := pos('@', sAuthority);
      if i > 0 then //we have user info;
      begin
        sUserInfo := Copy(sAuthority,1, i-1);
        userParts := sUserInfo.Split([':']);
        if Length(userParts) = 2 then
        begin
          sUsername := userParts[0];
          sPassword := userParts[1];
        
        end
        else
          sUsername := sUserInfo;
        Delete(sAuthority, 1, i);        
      end;
      //check for ip6 address
      if sAuthority.StartsWith('[') then
      begin
        i := LastDelimiter(']',sAuthority);
        if i = 0  then
          raise Exception.Create('Missing closing ] for ipv6 address');
        sHost := Copy(sAuthority,1, i);
        Delete(sAuthority,1,i);
      end;
      //check for port
      i := LastDelimiter(':',sAuthority);
      if i > 0 then
      begin
        Inc(i);
        j := i;        
        while IsNumeric(sAuthority[i]) and (i <= Length(sAuthority))  do
          Inc(i);
          
        if i - j > 0  then
        begin
          sPort := Copy(sAuthority,j ,i - j);   
          Delete(sAuthority,j-1,i-j + 1);      
          iPort := StrToIntDef(sPort,-1);
        end
        else
          raise Exception.Create('Invalid url, found : but no port');
      end;
      //might have been set if it's ipv6
      if sHost = '' then
        sHost := sAuthority;

      if sHost = '' then
        raise Exception.Create('No host segment found');

    end;
    //idx should be at the / after the port
    if idx > len then
      exit;
    Inc(idx);

    //find the fragment
    i := LastDelimiter('#', uriString);   
    if i > idx then
    begin
      sFragment := Copy(uriString, i + 1, len - i);
      Dec(len,len - i);
      Dec(len,1); //#
    end;
    //find the queryString;
    i := LastDelimiter('?',uriString);
    if i > idx then
    begin
      sQueryString := Copy(uriString, i + 1, len - i);
      Dec(len,len - i);
      Dec(len); //?
      if Length(sQueryString) >  0 then
        SplitQueryString(sQueryString);
    end;
    if len > idx then
      sPath := Copy(uriString, idx, len - idx + 1);

   if iPort = -1 then
    iPort := TURI.GetDefaultPortForScheme(sScheme);
  end;

  //urn:oasis:names:specification:docbook:dtd:xml:4.1.2
  //└┬┘ └──────────────────────┬──────────────────────┘
  //scheme                    path  
  procedure ParseNoAuthority;
  begin
    bHasAuthority := false;
    iPort := -1; //
    sPath := Copy(uriString, idx, len);
  end;
  
  
begin
  if uriString = '' then
    raise EArgumentException.Create('Empty uri string');

  if not IsAlpha(uriString[1]) then
    raise EArgumentException.Create('Uri must start with alpha character [a..z,A..Z]');
    
  len := Length(uriString);

  idx := FindSchemeDelimiter(len);

  
  if idx = -2 then
    raise EArgumentException.Create('Non scheme characters found in scheme.');
  if idx = -1 then
    raise EArgumentException.Create('Invalid Uri : ' + uriString);    

  //first char is :
  if idx = 1 then
    raise EArgumentException.Create('Empty Uri Scheme : ' + uriString);    
 
  sScheme := Copy(uriString, 1,idx -1);
  Inc(idx); //skip the :

  //check if we have authority
  if pos('//',uriString, idx) = idx then
    ParseWithAuthority
  else
    ParseNoAuthority;

  result := TUri.Create(uriString, decode, sScheme, sUsername, sPassword,sHost,sPath,sFragment, iPort,queryParams, bHasAuthority);    
end;

class function TURI.Parse(const uriString: string; const decode : boolean = true): TURI;
begin
  result := TURI.InternalParse(uriString.Trim,decode);
end;

procedure TURI.SetQueryParams(const Value: TArray<TQueryParam>);
begin
  FQueryParams := Value;
end;

function TURI.ToString(): string;
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
      result := FScheme.ToLower + '://'
    else
      result := FScheme + ':';
  end else
    result := '';
    
  result := result + sAuth + FHost;
  if (FPort > 0) and (FPort <> GetDefaultPortForScheme(FScheme)) and ((FScheme = 'https')  or  (FScheme = 'https')) then
    result := result + ':' + FPort.ToString;
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
  if Fragment <> '' then
    result := result + '#' + Fragment;
end;

class function TURI.TryParse(const uriString: string; const decode : boolean; out value: TURI): boolean;
begin
  try
    value := TURI.InternalParse(uriString.Trim, decode);
    result := true;
  except
    value := Default(TURI);
    result := false    
  end;
end;

class function TURI.TryParseWithError(const uriString: string; const decode : boolean;  out value: TURI; out error: string): boolean;
begin
  try
    value := TURI.InternalParse(uriString.Trim, decode);
    result := true;
  except
    on e : Exception do
    begin  
      value := Default(TURI);
      error := e.Message;
      result := false;
    end;
  end;
end;

end.
