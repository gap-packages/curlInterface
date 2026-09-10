//
// curlInterface: Simple Web Access
//

#include "gap_all.h" // GAP headers

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>
#include <curl/curl.h>

#undef PACKAGE
#undef PACKAGE_BUGREPORT
#undef PACKAGE_NAME
#undef PACKAGE_STRING
#undef PACKAGE_TARNAME
#undef PACKAGE_URL
#undef PACKAGE_VERSION

#include "pkgconfig.h"    // our own autoconf results

#if !defined(GAP_KERNEL_MAJOR_VERSION) || GAP_KERNEL_MAJOR_VERSION < 7
#define CONST_CSTR_STRING(x) CSTR_STRING(x)
#endif

size_t write_string(char * ptr, size_t size, size_t nmemb, void * outstream)
{
    Obj buf = (Obj)outstream;
    UInt len = GET_LEN_STRING(buf);
    UInt newlen = len + size * nmemb;
    GROW_STRING(buf, newlen);
    SET_LEN_STRING(buf, newlen);
    memcpy(CSTR_STRING(buf) + len, ptr, size * nmemb);
    return size * nmemb;
}

// Write straight to a file, for CURLOPT_WRITEDATA when a target is given.
size_t write_file(char * ptr, size_t size, size_t nmemb, void * outstream)
{
    return fwrite(ptr, size, nmemb, (FILE *)outstream);
}

// room for the ".<pid>.part" that names the temporary file
#define TARGET_TEMP_SUFFIX_LEN 32

// Could a completed download be moved onto <path>?  A directory cannot be
// replaced by a file, and an existing file we may not write should not be
// replaced either, even though 'rename' would happily do it.  Saying so here
// costs a 'stat' and saves downloading a body that has nowhere to go.
static int can_replace_file(const char * path)
{
    struct stat st;

    if (stat(path, &st) != 0)
        return 1;    // nothing there yet; opening the temporary file decides

    return S_ISDIR(st.st_mode) ? 0 : access(path, W_OK) == 0;
}

Obj FuncCURL_REQUEST(Obj self, Obj input_list)
{
    CURL *     curl;
    CURLcode   res;
    Obj        in_string = MakeString("");
    Obj        errorstring = 0;
    curl_off_t len;
    char       urlbuf[4096] = { 0 };
    char *     typebuf = NULL;
    char *     targetbuf = NULL;
    char *     tempbuf = NULL;
    FILE *     targetfile = NULL;

    const int n = LEN_PLIST(input_list);
    GAP_ASSERT(n == 9);    // paranoia check, GAP enforces this

    Obj URL = ELM_PLIST(input_list, 1);
    if (!IS_STRING_REP(URL)) {
        URL = CopyToStringRep(URL);
    }

    Obj type = ELM_PLIST(input_list, 2);
    if (!IS_STRING_REP(type)) {
        type = CopyToStringRep(type);
    }

    Obj out_string = ELM_PLIST(input_list, 3);
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
    memcpy(urlbuf, CONST_CSTR_STRING(URL), len);

    // If a target file was given, write the body straight into it instead of
    // building it up in memory.  Copy the name out of the GAP string for the
    // same reason as the URL above.
    Obj target = ELM_PLIST(input_list, 9);
    if (target != False) {
        if (!IS_STRING_REP(target)) {
            target = CopyToStringRep(target);
        }
        len = GET_LEN_STRING(target) + 1;
        targetbuf = (char *)malloc(len);
        memcpy(targetbuf, CONST_CSTR_STRING(target), len);

        // Write to a temporary file beside the target and rename it into
        // place once the transfer succeeded, so that a failure leaves
        // whatever was at the target alone instead of truncating it.  The
        // pid keeps two GAP processes fetching the same target apart.
        tempbuf = (char *)malloc(len + TARGET_TEMP_SUFFIX_LEN);
        snprintf(tempbuf, len + TARGET_TEMP_SUFFIX_LEN, "%s.%ld.part",
                 targetbuf, (long)getpid());

        if (can_replace_file(targetbuf))
            targetfile = fopen(tempbuf, "wb");
        if (targetfile == NULL) {
            Obj prec = NEW_PREC(2);
            SET_LEN_PREC(prec, 2);
            SET_RNAM_PREC(prec, 1, RNamName("success"));
            SET_ELM_PREC(prec, 1, False);
            SET_RNAM_PREC(prec, 2, RNamName("error"));
            SET_ELM_PREC(prec, 2, MakeImmString("cannot open target file"));
            CHANGED_BAG(prec);
            free(tempbuf);
            free(targetbuf);
            return prec;
        }
    }

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
        if (targetfile != NULL) {
            curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, write_file);
            curl_easy_setopt(curl, CURLOPT_WRITEDATA, targetfile);
        }
        else {
            curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, write_string);
            curl_easy_setopt(curl, CURLOPT_WRITEDATA, in_string);
        }
        curl_easy_setopt(curl, CURLOPT_TCP_NODELAY, 1L);
        curl_easy_setopt(curl, CURLOPT_USERAGENT, "curlInterface/GAP package");

        Obj verifyCert = ELM_PLIST(input_list, 4);
        Obj verbose = ELM_PLIST(input_list, 5);
        Obj followRedirect = ELM_PLIST(input_list, 6);
        Obj failOnError = ELM_PLIST(input_list, 7);
        Int maxTime = Int_ObjInt(ELM_PLIST(input_list, 8));

        if (verbose == True)
            curl_easy_setopt(curl, CURLOPT_VERBOSE, 1L);

        if (followRedirect == True)
            curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1L);

        if (failOnError == True)
            curl_easy_setopt(curl, CURLOPT_FAILONERROR, 1L);

        if (maxTime != 0)
            curl_easy_setopt(curl, CURLOPT_TIMEOUT, maxTime);

        if (strcmp(CONST_CSTR_STRING(type), "GET") == 0) {
            // simply download from the URL
            curl_easy_setopt(curl, CURLOPT_HTTPGET, 1L);
        }
        else if (strcmp(CONST_CSTR_STRING(type), "POST") == 0) {
            // send a string to the URL
            len = GET_LEN_STRING(out_string); // no null character
            curl_easy_setopt(curl, CURLOPT_POST, 1L);
            curl_easy_setopt(curl, CURLOPT_POSTFIELDSIZE_LARGE, len);
            curl_easy_setopt(curl, CURLOPT_COPYPOSTFIELDS,
                             CONST_CSTR_STRING(out_string));
            // using COPYPOSTFIELDS copies the data right now
        }
        else if (strcmp(CONST_CSTR_STRING(type), "HEAD") == 0) {
            // only get headers, without body
            curl_easy_setopt(curl, CURLOPT_NOBODY, 1L);
        }
        else {
            // custom request e.g. DELETE
            len = GET_LEN_STRING(type) + 1; // include null character
            typebuf = (char *) malloc(len);
            memcpy(typebuf, CONST_CSTR_STRING(type), len);
            curl_easy_setopt(curl, CURLOPT_CUSTOMREQUEST, typebuf);
        }

        if (verifyCert == False) {
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

    if (targetfile != NULL) {
        if (fclose(targetfile) != 0 && errorstring == 0)
            errorstring = MakeImmString("cannot write target file");
        if (errorstring == 0 && rename(tempbuf, targetbuf) != 0)
            errorstring = MakeImmString("cannot write target file");
        if (errorstring)
            remove(tempbuf);
        free(tempbuf);
        free(targetbuf);
    }

    // With a target file there is no body to hand back, so the result record
    // has just 'success', or 'success' and 'error'.
    Obj prec = NEW_PREC(2);
    SET_LEN_PREC(prec, 2);
    SET_RNAM_PREC(prec, 1, RNamName("success"));
    if (errorstring) {
        SET_ELM_PREC(prec, 1, False);
        SET_RNAM_PREC(prec, 2, RNamName("error"));
        SET_ELM_PREC(prec, 2, errorstring);
    }
    else if (targetfile != NULL) {
        SET_LEN_PREC(prec, 1);
        SET_ELM_PREC(prec, 1, True);
    }
    else {
        SET_ELM_PREC(prec, 1, True);
        SET_RNAM_PREC(prec, 2, RNamName("result"));
        SET_ELM_PREC(prec, 2, in_string);
    }
    CHANGED_BAG(prec);
    return prec;
}

Obj FuncCURL_VERSION(Obj self)
{
    return MakeImmString(curl_version());
}

// Table of functions to export
static StructGVarFunc GVarFuncs[] = {
    GVAR_FUNC(CURL_REQUEST, 9,
              "url, type, out_string, verifyCert, verbose, followRedirect, failOnError, maxTime, targetFile"),
    GVAR_FUNC(CURL_VERSION, 0, ""),
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
