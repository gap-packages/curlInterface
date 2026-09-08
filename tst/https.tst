#@local server
gap> LoadPackage( "curlInterface", false );
true
gap> LoadPackage( "io", false );
true
gap> ReadPackage( "curlInterface", "tst/https-server.g" );;
gap> server := CURLINTERFACE_StartHTTPSTestServer();;

# A self-signed certificate is rejected by default, and accepted only if
# verification is turned off explicitly
gap> CURLINTERFACE_VerifyCertResults( server );
[ false, true ]
gap> CURLINTERFACE_StopHTTPSTestServer( server );
