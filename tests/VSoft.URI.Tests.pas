unit VSoft.URI.Tests;

interface

uses
  DUnitX.TestFramework;


type
  [TestFixture]
  TURITests = class
  public
    [Test]
    procedure Test_Will_Fail_OnEmpty;

    [Test]
    procedure Test_Will_Fail_OnEmpty_Scheme;

    [TestCase('1','http://www.finalbuilder.com')]
    [TestCase('2','https://www.finalbuilder.com')]
    [TestCase('3','https://www.finalbuilder.com/with/a/path')]
    [TestCase('4','https://vincent:password@wiki.finalbuilder.com:9443/fsdfs/dsfsdf?dsfsdfsd=dfsdf#fragment')]
    [TestCase('5','urn:oasis:names:specification:docbook:dtd:xml:4.1.2')]
    [TestCase('6','https://vincent:password@[2001:cdba:0000:0000:0000:0000:3257:9652]:9443/one/two?hello=world&goodbye=cruelworld#fragment')]
    [TestCase('7','https://john.doe@www.example.com:123/forum/questions/?tag=networking&order=newest#top')]
    [TestCase('8','mailto:someone@example.com')]
    procedure Test_IsValid_Uri(const uriString : string);

    [Test]
    [TestCase('1','helloworld')]
    procedure Test_Will_Fail_On_Invalid(const uriString : string);

    [Test]
    procedure Test_all_the_parts;

    [Test]
    procedure Test_http_default_port;

  end;

implementation

uses
  System.SysUtils,
  VSoft.URI;

procedure TURITests.Test_all_the_parts;
var
  uri : TURI;
  error : string;
begin
 Assert.IsTrue(TURI.TryParseWithError('https://vincent:password@[2001:cdba:0000:0000:0000:0000:3257:9652]:9443/one/two?hello=world&goodbye=cruelworld#fragment', true, uri, error),'Expected uri to be valid : ' + error);
  Assert.AreEqual('https', uri.Scheme);
  Assert.AreEqual('vincent', uri.UserName);
  Assert.AreEqual('password', uri.Password);
  Assert.AreEqual('[2001:cdba:0000:0000:0000:0000:3257:9652]', uri.Host);
  Assert.AreEqual(9443, uri.Port);
  Assert.AreEqual('one/two', uri.Path);
  Assert.AreEqual(2, Length(uri.QueryParams));
  Assert.AreEqual('hello', uri.QueryParams[0].Name);
  Assert.AreEqual('world', uri.QueryParams[0].Value);
  Assert.AreEqual('goodbye', uri.QueryParams[1].Name);
  Assert.AreEqual('cruelworld', uri.QueryParams[1].Value);
end;

procedure TURITests.Test_http_default_port;
var
  uri : TURI;
  error : string;
begin
  Assert.IsTrue(TURI.TryParseWithError('http://vincent:password@[2001:cdba:0000:0000:0000:0000:3257:9652]/one/two?hello=world&goodbye=cruelworld#fragment', true, uri, error),'Expected uri to be valid : ' + error);
  Assert.AreEqual('http', uri.Scheme);
  Assert.AreEqual(80, uri.Port);
end;

procedure TURITests.Test_IsValid_Uri(const uriString : string);
var
    uri : TURI;
    error : string;
begin
  Assert.IsTrue(TURI.TryParseWithError(uriString, true, uri, error),'Excpected uri to be valid : ' + error);
  Assert.AreEqual(uriString, uri.ToString);
end;

procedure TURITests.Test_Will_Fail_OnEmpty;
begin
  Assert.WillRaise(
    procedure
    var
      uri : TURI;
    begin
      uri := TURI.Parse('');
    end,
    EArgumentException);

end;

procedure TURITests.Test_Will_Fail_OnEmpty_Scheme;
begin
  Assert.WillRaise(
    procedure
    var
      uri : TURI;
    begin
      uri := TURI.Parse(':sdfsdf:Sdfsdf:sdfsdf');
    end,
    EArgumentException);

end;

procedure TURITests.Test_Will_Fail_On_Invalid(const uriString: string);
var
  uri : TURI;
begin
  Assert.IsFalse(TURI.TryParse(uriString, true, uri),'Excpected uri to be invalid');

end;

initialization
  TDUnitX.RegisterTestFixture(TURITests);

end.
