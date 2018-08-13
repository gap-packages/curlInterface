//
// curlInterface: Simple Web Access
//

#include "src/compiled.h" // GAP headers


#include <stdio.h>
#include <curl/curl.h>

typedef enum {CURL_GET, CURL_POST} request_type;

size_t write_string(void * ptr, size_t size, size_t nmemb, Obj buf)
{
    UInt len = GET_LEN_STRING(buf);
    UInt newlen = len + size * nmemb;
    GROW_STRING(buf, newlen);
    SET_LEN_STRING(buf, newlen);
    memcpy(CHARS_STRING(buf) + len, ptr, size * nmemb);
    return size * nmemb;
}

Obj CURL_URL(Obj URL, Obj verifyCert, request_type type, Obj post_string)
{
    CURL *   curl;
    CURLcode res;
    Obj      string = MakeString("");
    Obj      errorstring = 0;
    UInt     len;
    char     arraybuf[4096] = { 0 };

    if (verifyCert != True && verifyCert != False) {
        ErrorMayQuit("CURL_URL: <verifyCert> must be true or false", 0L, 0L);
    }

    if (!IS_STRING(URL)) {
        ErrorMayQuit("CURL_URL: <URL> must be a string", 0L, 0L);
    }

    if (!IS_STRING_REP(URL)) {
        URL = CopyToStringRep(URL);
    }

    // copy URL into a buffer, as the GAP string could be moved
    // by a garbage collection triggered by write_string
    len = GET_LEN_STRING(URL) + 1;
    if (len > sizeof(arraybuf)) {
        ErrorMayQuit("CURL_URL: <URL> must be less than %d chars",
                     sizeof(arraybuf), 0L);
    }
    memcpy(arraybuf, CHARS_STRING(URL), len);

    res = curl_global_init(CURL_GLOBAL_DEFAULT);
    if (res != 0) {
        ErrorMayQuit("CURL_URL: failed to initialize libcurl (error %d)",
                     (Int)res, 0L);
    }

    curl = curl_easy_init();
    if (curl) {
        char errbuf[CURL_ERROR_SIZE];
        curl_easy_setopt(curl, CURLOPT_ERRORBUFFER, errbuf);

        curl_easy_setopt(curl, CURLOPT_URL, arraybuf);
        curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, write_string);
        curl_easy_setopt(curl, CURLOPT_WRITEDATA, string);

        if (verifyCert == True) {
            //
            // If you want to connect to a site who isn't using a certificate
            // that is signed by one of the certs in the CA bundle you have,
            // you can skip the verification of the server's certificate. This
            // makes the connection A LOT LESS SECURE.
            //
            // If you have a CA cert for the server stored someplace else than
            // in the default bundle, then the CURLOPT_CAPATH option might
            // come handy for you.
            //
            curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, 0L);

            //
            // If the site you're connecting to uses a different host name
            // that what they have mentioned in their server certificate's
            // commonName (or subjectAltName) fields, libcurl will refuse to
            // connect. You can skip this check, but this will make the
            // connection less secure.
            //
            curl_easy_setopt(curl, CURLOPT_SSL_VERIFYHOST, 0L);
        }

        // Perform the request, res will get the return code
        res = curl_easy_perform(curl);

        // Check for errors
        if (res != CURLE_OK) {
            if (*errbuf)
                errorstring = MakeImmString(errbuf);
            else
                errorstring = MakeImmString(curl_easy_strerror(res));
        }

        // always cleanup
        curl_easy_cleanup(curl);
    }

    curl_global_cleanup();

    Obj plist = NEW_PLIST(T_PLIST, 2);
    SET_LEN_PLIST(plist, 2);
    if (errorstring) {
        SET_ELM_PLIST(plist, 1, False);
        SET_ELM_PLIST(plist, 2, errorstring);
    }
    else {
        SET_ELM_PLIST(plist, 1, True);
        SET_ELM_PLIST(plist, 2, string);
    }
    return plist;
}

// GAP-callable functions
Obj FuncCURL_READ_URL(Obj self, Obj URL, Obj verifyCert)
{
    return CURL_URL(URL, verifyCert, CURL_GET, NULL);
}

// Table of functions to export
static StructGVarFunc GVarFuncs[] = {
    GVAR_FUNC(CURL_READ_URL, 2, "url, verifyCert"),
    { 0 }
};

// initialise kernel data structures
static Int InitKernel(StructInitInfo * module)
{
    InitHdlrFuncsFromTable(GVarFuncs);

    return 0;
}

// initialise library data structures
static Int InitLibrary(StructInitInfo * module)
{
    InitGVarFuncsFromTable(GVarFuncs);

    return 0;
}

// table of init functions
static StructInitInfo module = {
    .type = MODULE_DYNAMIC,
    .name = "curl",
    .initKernel = InitKernel,
    .initLibrary = InitLibrary,
};

StructInitInfo * Init__Dynamic(void)
{
    return &module;
}
