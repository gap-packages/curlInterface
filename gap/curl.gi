#
# curlInterface: Simple Web Access
#
# Implementations
#
InstallGlobalFunction( "DownloadURL",
function(URL, opt...)
    local ret, verifyCert;
    if Length(opt) > 0 then
        verifyCert := opt[1];
    else
        verifyCert := true;
    fi;
    ret := CURL_READ_URL(URL, verifyCert);
    if ret[1] = false then
        return rec(success := false, error := ret[2]);
    else
        return rec(success := true, result := ret[2]);
    fi;
end);

InstallGlobalFunction( "PostURL",
function(URL, str, opt...)
    local verifyCert, ret;
    if Length(opt) > 0 then
        verifyCert := opt[1];
    else
        verifyCert := true;
    fi;
    ret := CURL_POST_URL(URL, str, verifyCert);
    if ret[1] = false then
        return rec(success := false, error := ret[2]);
    else
        return rec(success := true, result := ret[2]);
    fi;
end);
