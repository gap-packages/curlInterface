#
# curlInterface: Simple Web Access
#
# Declarations
#

#! @Arguments URL[, verifyCert]
#! @Description
#!  Download a URL from the internet. Accepts a web address
#!  as a string, which can start with either of http:// or https://
#!  The optional argument <A>verifyCert</A> can be set to <K>false</K>
#!  to disable verification of HTTPS certificates. If not specified,
#!  it defaults to <K>true</K>.
#! @Returns A record describing the result. This record will always
#!  contain the option 'success', which will be <K>true</K> or
#!  <K>false</K>. If 'success' is <K>true</K>, then 'result' will
#!  contain the downloaded file. If 'success' is <K>false</K>, then
#!  'error' will contain a human-readable string describing the error.
DeclareGlobalFunction( "DownloadURL" );
