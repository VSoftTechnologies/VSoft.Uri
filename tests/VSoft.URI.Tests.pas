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
    [TestCase('9','c:\temp\foo\bar\test.txt')]
    [TestCase('10','\\server\c\temp\foo\bar')]
    [TestCase('11','https://192.168.0.1:999/with/a/path')]
    [TestCase('12','\\192.168.0.1\c\temp\foo\bar')]
    procedure Test_IsValid_Uri(const uriString : string);

    [Test]
    [TestCase('1','helloworld')]
    procedure Test_Will_Fail_On_Invalid(const uriString : string);

    [Test]
    procedure Test_all_the_parts;

    [Test]
    procedure Test_http_default_port;


    [TestCase('1','https://www.finalbuilder.com|https://www.finalbuilder.com|/|/','|')]
    [TestCase('2','https://www.finalbuilder.com/with/a/path|https://www.finalbuilder.com/with/a/path|/with/a/path|/with/a/path','|')]
    [TestCase('3','https://vincent:password@wiki.finalbuilder.com:9443/fsdfs/dsfsdf?dsfsdfsd=dfsdf#fragment|https://vincent:password@wiki.finalbuilder.com:9443/fsdfs/dsfsdf?dsfsdfsd=dfsdf#fragment|/fsdfs/dsfsdf|/fsdfs/dsfsdf','|')]
    [TestCase('4','c:\temp\foo\bar\test.txt|file:///c:/temp/foo/bar/test.txt|c:/temp/foo/bar/test.txt|c:\temp\foo\bar\test.txt','|')]
    [TestCase('5','\\server\c\temp\foo\bar|file://server/c/temp/foo/bar|/c/temp/foo/bar|\\server\c\temp\foo\bar','|')]
    [Test]
    procedure Test_Parts(const uriString, absoluteUri, absolutePath, localPath : string);

    [Test]
    [TestCase('1','\\server\c\temp\foo\bar|true','|')]
    [TestCase('2','file://server/c/temp/foo/bar|true','|')]
    [TestCase('4','file:///c:/temp/foo/bar/test.txt|false','|')]
    procedure Test_IsUnc(const uriString : string; const isUnc : boolean);

  end;

implementation

uses
  System.SysUtils,
  VSoft.URI;

procedure TURITests.Test_all_the_parts;
var
  uri : IUri;
  error : string;
begin
  Assert.IsTrue(TUriFactory.TryParseWithError('https://vincent:password@[2001:cdba:0000:0000:0000:0000:3257:9652]:9443/one/two?hello=world&goodbye=cruelworld#fragment', true, uri, error),'Expected uri to be valid : ' + error);
  Assert.AreEqual('https', uri.Scheme);
  Assert.AreEqual('vincent', uri.UserName);
  Assert.AreEqual('password', uri.Password);
  Assert.AreEqual('[2001:cdba:0000:0000:0000:0000:3257:9652]', uri.Host);
  Assert.AreEqual(9443, uri.Port);
  Assert.AreEqual('/one/two', uri.AbsolutePath);
  Assert.AreEqual(2, Length(uri.QueryParams));
  Assert.AreEqual('hello', uri.QueryParams[0].Name);
  Assert.AreEqual('world', uri.QueryParams[0].Value);
  Assert.AreEqual('goodbye', uri.QueryParams[1].Name);
  Assert.AreEqual('cruelworld', uri.QueryParams[1].Value);
end;

procedure TURITests.Test_http_default_port;
var
  uri : IUri;
  error : string;
begin
  Assert.IsTrue(TUriFactory.TryParseWithError('http://vincent:password@[2001:cdba:0000:0000:0000:0000:3257:9652]/one/two?hello=world&goodbye=cruelworld#fragment', true, uri, error),'Expected uri to be valid : ' + error);
  Assert.AreEqual('http', uri.Scheme);
  Assert.AreEqual(80, uri.Port);
end;

procedure TURITests.Test_IsUnc(const uriString: string; const isUnc: boolean);
var
  uri : IUri;
  error : string;
begin
  Assert.IsTrue(TUriFactory.TryParseWithError(uriString, true, uri, error),'Excpected uri to be valid : ' + error);
  Assert.AreEqual<boolean>(isUnc, uri.IsUnc);
end;

procedure TURITests.Test_IsValid_Uri(const uriString : string);
var
  uri : IUri;
  error : string;
begin
  Assert.IsTrue(TUriFactory.TryParseWithError(uriString, true, uri, error),'Excpected uri to be valid : ' + error);
end;

procedure TURITests.Test_Parts(const uriString, absoluteUri, absolutePath, localPath: string);
var
  uri : IUri;
  error : string;
begin
  Assert.IsTrue(TUriFactory.TryParseWithError(uriString, true, uri, error),'Expected uri to be valid : ' + error);
  Assert.AreEqual(absoluteUri, uri.AbsoluteUri);
  Assert.AreEqual(localPath, uri.LocalPath);

end;

procedure TURITests.Test_Will_Fail_OnEmpty;
begin
  Assert.WillRaise(
    procedure
    var
      uri : IUri;
    begin
      uri := TUriFactory.Parse('');
    end,
    EArgumentException);

end;

procedure TURITests.Test_Will_Fail_OnEmpty_Scheme;
begin
  Assert.WillRaise(
    procedure
    var
      uri : IUri;
    begin
      uri := TUriFactory.Parse(':sdfsdf:Sdfsdf:sdfsdf');
    end,
    EArgumentException);

end;

procedure TURITests.Test_Will_Fail_On_Invalid(const uriString: string);
var
  uri : IUri;
begin
  Assert.IsFalse(TUriFactory.TryParse(uriString, true, uri),'Excpected uri to be invalid');

end;

initialization
  TDUnitX.RegisterTestFixture(TURITests);

end.
