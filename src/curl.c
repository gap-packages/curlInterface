//
// curlInterface: Simple Web Access
//

#include "src/compiled.h" // GAP headers

#include <stdio.h>
#include <curl/curl.h>

size_t write_string(void * ptr, size_t size, size_t nmemb, Obj buf)
{
    UInt len = GET_LEN_STRING(buf);
    UInt newlen = len + size * nmemb;
    GROW_STRING(buf, newlen);
    SET_LEN_STRING(buf, newlen);
    memcpy(CHARS_STRING(buf) + len, ptr, size * nmemb);
    return size * nmemb;
}

Obj FuncCURL_REQUEST(Obj self,
                     Obj URL,
                     Obj type,
                     Obj out_string,
                     Obj verifyCert,
                     Obj verbose,
                     Obj followRedirect)
{
    CURL *     curl;
    CURLcode   res;
    Obj        in_string = MakeString("");
    Obj        errorstring = 0;
    curl_off_t len;
    char       urlbuf[4096] = { 0 };
    char *     typebuf = NULL;

    if (!IS_STRING_REP(URL)) {
        URL = CopyToStringRep(URL);
    }

    if (!IS_STRING_REP(type)) {
        type = CopyToStringRep(type);
    }

    if (!IS_STRING_REP(out_string)) {
        out_string = CopyToStringRep(out_string);
    }

    // copy URL into a buffer, as the GAP string could be moved
    // by a garbage collection triggered by write_string
    len = GET_LEN_STRING(URL) + 1;
    if (len > sizeof(urlbuf)) {
        ErrorMayQuit("CURL_REQUEST: <URL> must be less than %d chars",
                     sizeof(urlbuf), 0L);
    }
    memcpy(urlbuf, CHARS_STRING(URL), len);

    res = curl_global_init(CURL_GLOBAL_DEFAULT);
    if (res != 0) {
        ErrorMayQuit("CURL_REQUEST: failed to initialize libcurl (error %d)",
                     (Int)res, 0L);
    }

    curl = curl_easy_init();
    if (curl) {
        char errbuf[CURL_ERROR_SIZE];
        curl_easy_setopt(curl, CURLOPT_ERRORBUFFER, errbuf);

        curl_easy_setopt(curl, CURLOPT_URL, urlbuf);
        curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, write_string);
        curl_easy_setopt(curl, CURLOPT_WRITEDATA, in_string);
        curl_easy_setopt(curl, CURLOPT_TCP_NODELAY, 1L);

        if (verbose == True)
            curl_easy_setopt(curl, CURLOPT_VERBOSE, 1L);

        if (followRedirect == True)
            curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1L);

        if (strcmp((const char *) CHARS_STRING(type), "GET") == 0) {
            // simply download from the URL
            curl_easy_setopt(curl, CURLOPT_HTTPGET, 1L);
        }
        else if (strcmp((const char *) CHARS_STRING(type), "POST") == 0) {
            // send a string to the URL
            len = GET_LEN_STRING(out_string); // no null character
            curl_easy_setopt(curl, CURLOPT_POST, 1L);
            curl_easy_setopt(curl, CURLOPT_POSTFIELDSIZE_LARGE, len);
            curl_easy_setopt(curl, CURLOPT_COPYPOSTFIELDS,
                             CHARS_STRING(out_string));
            // using COPYPOSTFIELDS copies the data right now
        }
        else if (strcmp((const char *) CHARS_STRING(type), "HEAD") == 0) {
            // only get headers, without body
            curl_easy_setopt(curl, CURLOPT_NOBODY, 1L);
        }
        else {
            // custom request e.g. DELETE
            len = GET_LEN_STRING(type) + 1; // include null character
            typebuf = (char *) malloc(len);
            memcpy(typebuf, CHARS_STRING(type), len);
            curl_easy_setopt(curl, CURLOPT_CUSTOMREQUEST, typebuf);
        }            

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
    free(typebuf);

    Obj prec = NEW_PREC(2);
    SET_LEN_PREC(prec, 2);
    SET_RNAM_PREC(prec, 1, RNamName("success"));
    if (errorstring) {
        SET_ELM_PREC(prec, 1, False);
        SET_RNAM_PREC(prec, 2, RNamName("error"));
        SET_ELM_PREC(prec, 2, errorstring);
    }
    else {
        SET_ELM_PREC(prec, 1, True);
        SET_RNAM_PREC(prec, 2, RNamName("result"));
        SET_ELM_PREC(prec, 2, in_string);
    }
    CHANGED_BAG(prec);
    return prec;
}

// Table of functions to export
static StructGVarFunc GVarFuncs[] = {
    GVAR_FUNC(CURL_REQUEST, 6,
              "url, type, out_string, verifyCert, verbose, followRedirect"),
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
