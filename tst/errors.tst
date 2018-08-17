#
# test error handling
#

# URL too long (Download)
gap> badURL := ListWithIdenticalEntries(4096,' ');;
gap> DownloadURL(badURL);
Error, CURL_REQUEST: <URL> must be less than 4096 chars

# URL too long (Post)
gap> badURL := ListWithIdenticalEntries(4096,' ');;
gap> PostToURL(badURL, "hello");
Error, CURL_REQUEST: <URL> must be less than 4096 chars

# URL not a string (Download)
gap> DownloadURL(42);
Error, CurlRequest: <URL> must be a string

# URL not a string (Post)
gap> PostToURL(42, "hello");
Error, CurlRequest: <URL> must be a string

# request type not a string
gap> CurlRequest("www.google.com", 637, "hello", true);
Error, CurlRequest: <type> must be a string

# post_string not a string
gap> PostToURL("httpbin.org/post", 17);                     
Error, CurlRequest: <out_string> must be a string

# invalid verifyCert
gap> DownloadURL("https://www.google.com", "maybe verify cert");
Error, CurlRequest: <verifyCert> must be true or false
