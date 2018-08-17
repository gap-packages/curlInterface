#
# curlInterface: Simple Web Access
#
# Implementations
#
InstallGlobalFunction("CurlRequest",
function(URL, type, out_string, verifyCert)
    local ret;
    if not IsString(URL) then
        ErrorNoReturn("CurlRequest: <URL> must be a string");
    elif not IsString(type) then
        ErrorNoReturn("CurlRequest: <type> must be a string");
    elif not IsString(out_string) then
        ErrorNoReturn("CurlRequest: <out_string> must be a string");
    elif verifyCert <> true and verifyCert <> false then
        ErrorNoReturn("CurlRequest: <verifyCert> must be true or false");
    fi;
    return CURL_REQUEST(URL, type, out_string, verifyCert);
end);

InstallGlobalFunction( "DownloadURL",
function(URL, opt...)
    local verifyCert, ret;
    if Length(opt) > 0 then
        verifyCert := opt[1];
    else
        verifyCert := true;
    fi;
    return CurlRequest(URL, "GET", "", verifyCert);
end);

InstallGlobalFunction( "PostToURL",
function(URL, str, opt...)
    local verifyCert;
    if Length(opt) > 0 then
        verifyCert := opt[1];
    else
        verifyCert := true;
    fi;
    return CurlRequest(URL, "POST", str, verifyCert);
end);
