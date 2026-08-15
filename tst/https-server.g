#############################################################################
##
##  An HTTPS server with a self-signed certificate for the curlInterface
##  tests, used to check that certificates really are verified unless
##  `verifyCert` is false. Implemented via `openssl s_server`; if openssl is
##  missing, the tests using it are skipped.
##

BindGlobal( "CURLINTERFACE_OpenSSL", function()
  local openssl;

  openssl := Filename( DirectoriesSystemPrograms(), "openssl" );
  if openssl = fail or not IsExecutableFile( openssl ) then
    return fail;
  fi;
  return openssl;
end );

# Bind port 0 to have the kernel pick a free port, then release it again.
BindGlobal( "CURLINTERFACE_FreePort", function()
  local listener, address, port;

  listener := IO_socket( IO.PF_INET, IO.SOCK_STREAM, "tcp" );
  if listener = fail then
    return fail;
  fi;
  if IO_bind( listener, IO_MakeIPAddressPort( "127.0.0.1", 0 ) ) = fail then
    IO_close( listener );
    return fail;
  fi;
  address := IO_getsockname( listener );
  port := 256 * INT_CHAR( address[3] ) + INT_CHAR( address[4] );
  IO_close( listener );
  return port;
end );

# Waits for the server to accept requests. Tries both settings of
# `verifyCert`, so that this succeeds no matter which of them rejects a
# self-signed certificate.
BindGlobal( "CURLINTERFACE_WaitForHTTPSServer", function( url )
  local i;

  for i in [ 1 .. 10 ] do
    if DownloadURL( url, rec( verifyCert := false ) ).success or
       DownloadURL( url ).success then
      return true;
    fi;
    Sleep( 1 );
  od;
  return false;
end );

# Returns a record with components `pid` and `url`, or `fail` if no HTTPS
# server could be started.
BindGlobal( "CURLINTERFACE_StartHTTPSTestServer", function()
  local openssl, sh, dir, cert, key, port, url, pid, devnull;

  openssl := CURLINTERFACE_OpenSSL();
  sh := Filename( DirectoriesSystemPrograms(), "sh" );
  if openssl = fail or sh = fail then
    return fail;
  fi;

  # LibreSSL's `req` has no `-quiet`, so silence it via the shell
  dir := DirectoryTemporary();
  cert := Filename( dir, "cert.pem" );
  key := Filename( dir, "key.pem" );
  if Process( dir, sh, InputTextNone(), OutputTextNone(),
              [ "-c", Concatenation(
                  "'", openssl, "' req -x509 -newkey rsa:2048 -nodes",
                  " -keyout '", key, "' -out '", cert, "'",
                  " -days 1 -subj /CN=localhost 2>/dev/null" ) ] ) <> 0 then
    return fail;
  fi;

  port := CURLINTERFACE_FreePort();
  if port = fail then
    return fail;
  fi;
  url := Concatenation( "https://localhost:", String( port ), "/" );

  pid := IO_fork();
  if pid = 0 then
    devnull := IO_open( "/dev/null", IO.O_WRONLY, 0 );
    if devnull <> fail then
      IO_dup2( devnull, 1 );
      IO_dup2( devnull, 2 );
    fi;
    IO_execv( openssl,
              [ "s_server", "-quiet", "-www", "-accept", String( port ),
                "-cert", cert, "-key", key ] );
    IO_exit( 1 );
  elif pid < 0 then
    return fail;
  fi;

  if CURLINTERFACE_WaitForHTTPSServer( url ) <> true then
    IO_kill( pid, IO.SIGTERM );
    IO_WaitPid( pid, true );
    return fail;
  fi;

  return rec( pid := pid, url := url );
end );

BindGlobal( "CURLINTERFACE_StopHTTPSTestServer", function( server )
  if server <> fail then
    IO_kill( server.pid, IO.SIGTERM );
    IO_WaitPid( server.pid, true );
  fi;
end );

# Downloads from the test server once with the default options and once with
# `verifyCert := false`, and returns the two `success` values.
BindGlobal( "CURLINTERFACE_VerifyCertResults", function( server )
  if server = fail then
    if CURLINTERFACE_OpenSSL() = fail then
      # skip the test on systems without openssl
      return [ false, true ];
    fi;
    return "could not start the HTTPS test server";
  fi;
  return [ DownloadURL( server.url ).success,
           DownloadURL( server.url, rec( verifyCert := false ) ).success ];
end );
