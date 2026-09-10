#@local r, url, postString, requestType, server, baseurl, file
gap> LoadPackage( "curlInterface", false );
true
gap> LoadPackage( "io", false );
true
gap> ReadPackage( "curlInterface", "tst/http-server.g" );;
gap> server := CURLINTERFACE_StartHTTPTestServer();;
gap> baseurl := Concatenation( "http://127.0.0.1:",
>                             String( server.port ) );;

# Successful GET
gap> r := DownloadURL( Concatenation( baseurl, "/success" ) );;
gap> SortedList( RecNames( r ) );
[ "result", "success" ]
gap> r.success;
true
gap> r.result;
"download test response\n"

# A URL that is a string but not in IsStringRep
gap> url := List( Concatenation( baseurl, "/success" ), x -> x );;
gap> IsStringRep( url );
false
gap> DownloadURL( url ).result;
"download test response\n"

# Successful POST and exact body echo
gap> r := PostToURL( Concatenation( baseurl, "/post" ),
>                    "field1=true&field2=17" );;
gap> r.success;
true
gap> r.result;
"field1=true&field2=17"

# POST preserves embedded NUL bytes
gap> postString := "field1=my\000first\000field";;
gap> r := PostToURL( Concatenation( baseurl, "/post" ), postString );;
gap> r.success;
true
gap> r.result = postString;
true

# A POST body that is a string but not in IsStringRep
gap> postString := List( "animal=tiger&material=cotton", x -> x );;
gap> IsStringRep( postString );
false
gap> r := PostToURL( Concatenation( baseurl, "/post" ), postString,
>                    rec( verifyCert := true ) );;
gap> r.result = postString;
true

# A request type that is a string but not in IsStringRep
gap> requestType := List( "GET", x -> x );;
gap> IsStringRep( requestType );
false
gap> r := CurlRequest( Concatenation( baseurl, "/success" ),
>                      requestType, "" );;
gap> r.result;
"download test response\n"

# HEAD returns no body
gap> CurlRequest( Concatenation( baseurl, "/success" ), "HEAD", "" );
rec( result := "", success := true )

# DELETE reaches the deterministic route
gap> r := DeleteURL( Concatenation( baseurl, "/delete" ) );;
gap> r.success;
true
gap> r.result;
"delete test response\n"

# Verbose output does not change the result
gap> r := DownloadURL( Concatenation( baseurl, "/success" ),
>                      rec( verbose := true ) );;
gap> r.success and r.result = "download test response\n";
true

# Redirects are followed by default and when explicitly enabled
gap> url := Concatenation( baseurl, "/redirect" );;
gap> DownloadURL( url ).result;
"download test response\n"
gap> DownloadURL( url, rec( followRedirect := true ) ).result;
"download test response\n"
gap> DownloadURL( url, rec( followRedirect := false ) ).result;
"redirect response\n"

# 404 responses and failOnError
gap> url := Concatenation( baseurl, "/missing" );;
gap> r := DownloadURL( url );;
gap> r.success;
true
gap> r.result;
"not found\n"
gap> r := DownloadURL( url, rec( failOnError := true ) );;
gap> r.success;
false
gap> PositionSublist( r.error, "404" ) <> fail;
true

# A local disconnect exercises the transport-error result shape
gap> r := DownloadURL( Concatenation( baseurl, "/disconnect" ) );;
gap> SortedList( RecNames( r ) );
[ "error", "success" ]
gap> r.success;
false

# Timeout failure and success
gap> url := Concatenation( baseurl, "/delay" );;
gap> DownloadURL( url, rec( maxTime := 1 ) ).success;
false
gap> DownloadURL( url, rec( maxTime := 5 ) ).result;
"download test response\n"

# Downloading to a file
gap> file := Filename( DirectoryTemporary(), "target" );;
gap> r := DownloadURL( Concatenation( baseurl, "/success" ),
>                      rec( targetFile := file ) );;
gap> r.success;
true

# with a target file there is no body to hand back
gap> RecNames( r );
[ "success" ]
gap> StringFile( file );
"download test response\n"

# a failed request must not leave the file behind
gap> RemoveFile( file );;
gap> r := DownloadURL( Concatenation( baseurl, "/missing" ),
>                      rec( targetFile := file, failOnError := true ) );;
gap> r.success;
false
gap> IsExistingFile( file );
false

# nor after the connection drops mid-transfer
gap> r := DownloadURL( Concatenation( baseurl, "/disconnect" ),
>                      rec( targetFile := file ) );;
gap> r.success;
false
gap> IsExistingFile( file );
false

# an existing file survives a failed download, contents and all
gap> FileString( file, "do not touch\n" );;
gap> r := DownloadURL( Concatenation( baseurl, "/missing" ),
>                      rec( targetFile := file, failOnError := true ) );;
gap> r.success;
false
gap> StringFile( file );
"do not touch\n"

# and likewise when the connection drops mid-transfer
gap> r := DownloadURL( Concatenation( baseurl, "/disconnect" ),
>                      rec( targetFile := file ) );;
gap> r.success;
false
gap> StringFile( file );
"do not touch\n"

# a successful download replaces it
gap> r := DownloadURL( Concatenation( baseurl, "/success" ),
>                      rec( targetFile := file ) );;
gap> r.success;
true
gap> StringFile( file );
"download test response\n"
gap> RemoveFile( file );;

# a target file that cannot be opened is reported, not fatal
gap> r := DownloadURL( Concatenation( baseurl, "/success" ),
>                      rec( targetFile := "/no/such/directory/target" ) );;
gap> r.success;
false
gap> r.error;
"cannot open target file"

# argument checking
gap> DownloadURL( baseurl, rec( targetFile := 42 ) );
Error, CurlRequest: <opts>.targetFile must be a string or false
gap> CURLINTERFACE_StopHTTPTestServer( server );;
