unit VSoft.URI;

interface

type
  TQueryParam = record
    Name : string;
    Value : string;
  end;

//TODO : Encoding/Decoding'

  IUri = interface
  ['{48515EE4-EA48-4BDB-B7B0-FB9D0A3E26CD}']
    function GetOriginal : string;
    function GetScheme: string;
    function GetUsername: string;
    function GetPassword: string;
    function GetHost: string;
    function GetPort: integer;
    function GetFragment : string;
    function GetQueryParams : TArray<TQueryParam>;
    function GetHasAuthority : boolean;
    function GetIsEmpty : boolean;
    function GetIsUnc : boolean;
    function GetIsFile : boolean;
    function GetAbsoluteUri : string;
    function GetLocalPath : string;
    function GetAbsolutePath : string;

    function ToString() : string;


    procedure SetScheme(const value: string);
    procedure SetUsername(const value: string);
    procedure SetPassword(const value: string);
    procedure SetHost(const valuet: string);
    procedure SetPort(const valuet: integer);
    procedure SetPath(const valueh: string);
    procedure SetFragment(const value : string);
    procedure SetQueryParams(const value : TArray<TQueryParam>);

    property OriginalUriString : string read GetOriginal;
    property Scheme   : string read GetScheme write SetScheme;
    property UserName : string read GetUsername write SetUsername;
    property Password : string read GetPassword write SetPassword;
    property Host     : string read GetHost     write SetHost;
    property Port     : integer read GetPort     write SetPort;
    property QueryParams : TArray<TQueryParam> read GetQueryParams write SetQueryParams;
    property Fragment : string read GetFragment write SetFragment;
    property IsEmpty  : boolean read GetIsEmpty;
    property IsFile   : boolean read GetIsFile;
    property IsUnc    : boolean read GetIsUnc;
    property AbsoluteUri : string read GetAbsoluteUri;
    property AbsolutePath : string read GetAbsolutePath;
    property LocalPath : string read GetLocalPath;

  end;

  type
    TUriFactory = class
    public
      class function Parse(const uriString : string; const decode : boolean = true) : IUri;static;
      class function TryParse(const uriString : string; const decode : boolean; out value : IUri) : boolean;static;
      class function TryParseWithError(const uriString : string; const decode : boolean; out value : IUri; out error : string) : boolean;static;
      class function Empty : IUri; static;
    end;

implementation

uses
  System.Types,
  System.SysUtils,
  VSoft.Uri.Impl;


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






{ TUriFactory }

class function TUriFactory.Empty: IUri;
begin
  result := TUriImpl.Create('');
end;

class function TUriFactory.Parse(const uriString: string; const decode: boolean): IUri;
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

   if (sScheme = 'file') and (uriString[idx] = '/') then
    begin
      //it's a filepath so treat it differently
      Inc(idx); // skip the /
      sPath := Copy(uriString,idx, len);
      exit;
    end;




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
    iPort := TUriImpl.GetDefaultPortForScheme(sScheme);
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


  //can't parse unc without a scheme, so add one.
  if uriString.StartsWith('\\') then
  begin
    result := TUriFactory.Parse('file:' + StringReplace(uriString, '\','/',[rfReplaceAll]),decode);
    exit;
  end;

  //check for windows file path.
  if length(uriString) >= 3 then
  begin
    if IsAlpha(uriString[1]) and (copy(uriString,2,2) = ':\') then
    begin
      result := TUriFactory.Parse('file:///' + StringReplace(uriString, '\','/',[rfReplaceAll]),decode);
      exit;
    end;
  end;



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

  result := TUriImpl.Create(uriString, decode, sScheme, sUsername, sPassword,sHost,sPath,sFragment, iPort,queryParams, bHasAuthority);
end;


class function TUriFactory.TryParse(const uriString: string; const decode: boolean; out value: IUri): boolean;
begin
  try
    value := TUriFactory.Parse(uriString.Trim, decode);
    result := true;
  except
    value := nil;
    result := false
  end;

end;

class function TUriFactory.TryParseWithError(const uriString: string; const decode: boolean; out value: IUri; out error: string): boolean;
begin
  try
    value := TUriFactory.Parse(uriString.Trim, decode);
    result := true;
  except
    on e : Exception do
    begin
      value := nil;
      error := e.Message;
      result := false;
    end;
  end;
end;

end.
