#############################################################################
##
##  A small HTTP server for the curlInterface tests.
##

BindGlobal( "CURLINTERFACE_HandleHTTPTestRequest",
function( listener, socket )
  local connection, line, parts, method, uri, contentLength, body,
        status, response, location, headers;

  IO_close( listener );
  connection := IO_WrapFD( socket, IO.DefaultBufSize, IO.DefaultBufSize );
  line := IO_ReadLine( connection );
  if line = fail then
    IO_Close( connection );
    IO_exit( 1 );
  fi;
  parts := SplitString( line, " \r\n" );
  if Length( parts ) < 2 then
    IO_Close( connection );
    IO_exit( 1 );
  fi;
  method := parts[1];
  uri := parts[2];

  contentLength := 0;
  repeat
    line := IO_ReadLine( connection );
    if line <> fail and not line in [ "", "\n", "\r\n" ] then
      parts := SplitString( line, ": \r\n" );
      parts := Filtered( parts, part -> part <> "" );
      if Length( parts ) >= 2 and
         LowercaseString( parts[1] ) = "content-length" then
        contentLength := Int( parts[2] );
      fi;
    fi;
  until line = fail or line in [ "", "\n", "\r\n" ];
  if line = fail then
    IO_Close( connection );
    IO_exit( 1 );
  fi;

  body := IO_ReadBlock( connection, contentLength );
  if body = fail or Length( body ) <> contentLength then
    IO_Close( connection );
    IO_exit( 1 );
  fi;

  if uri = "/disconnect" then
    IO_Close( connection );
    IO_exit( 0 );
  fi;

  status := "200 OK";
  response := "download test response\n";
  location := "";
  if uri = "/post" and method = "POST" then
    response := body;
  elif uri = "/delete" and method = "DELETE" then
    response := "delete test response\n";
  elif uri = "/missing" then
    status := "404 Not Found";
    response := "not found\n";
  elif uri = "/redirect" then
    status := "302 Found";
    response := "redirect response\n";
    location := "Location: /success\r\n";
  elif uri = "/delay" then
    Sleep( 2 );
  elif uri <> "/success" then
    status := "404 Not Found";
    response := "not found\n";
  fi;

  headers := Concatenation(
      "HTTP/1.1 ", status, "\r\n",
      location,
      "Content-Type: text/plain\r\n",
      "Content-Length: ", String( Length( response ) ), "\r\n",
      "Connection: close\r\n\r\n" );
  IO_Write( connection, headers );
  if method <> "HEAD" then
    IO_Write( connection, response );
  fi;
  IO_Flush( connection );
  IO_Close( connection );
  IO_exit( 0 );
end );

BindGlobal( "CURLINTERFACE_StartHTTPTestServer", function()
  local listener, address, port, pid, socket, handler;

  listener := IO_socket( IO.PF_INET, IO.SOCK_STREAM, "tcp" );
  if listener = fail then
    Error( "cannot start the HTTP test server" );
  fi;
  if IO_bind( listener, IO_MakeIPAddressPort( "127.0.0.1", 0 ) ) = fail or
     IO_listen( listener, 8 ) <> true then
    IO_close( listener );
    Error( "cannot start the HTTP test server" );
  fi;
  address := IO_getsockname( listener );
  port := 256 * INT_CHAR( address[3] ) + INT_CHAR( address[4] );

  pid := IO_fork();
  if pid = 0 then
    while true do
      socket := IO_accept( listener,
                           IO_MakeIPAddressPort( "0.0.0.0", 0 ) );
      if socket = fail then
        IO_exit( 0 );
      fi;
      handler := IO_fork();
      if handler = 0 then
        CURLINTERFACE_HandleHTTPTestRequest( listener, socket );
      elif handler < 0 then
        IO_close( socket );
        IO_exit( 1 );
      else
        IO_close( socket );
        IO_IgnorePid( handler );
      fi;
    od;
  elif pid < 0 then
    IO_close( listener );
    Error( "cannot fork the HTTP test server" );
  fi;

  IO_close( listener );
  return rec( pid := pid, port := port );
end );

BindGlobal( "CURLINTERFACE_StopHTTPTestServer", function( server )
  IO_kill( server.pid, IO.SIGTERM );
  IO_WaitPid( server.pid, true );
end );
