#@local r, url, postString, requestType, server, baseurl
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
gap> CURLINTERFACE_StopHTTPTestServer( server );;
