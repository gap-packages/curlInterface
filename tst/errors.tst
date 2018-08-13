#
# test error handling
#

# URL too long (Download)
gap> badURL := ListWithIdenticalEntries(4096,' ');;
gap> DownloadURL(badURL);
Error, CURL_URL: <URL> must be less than 4096 chars

# URL too long (Post)
gap> badURL := ListWithIdenticalEntries(4096,' ');;
gap> PostURL(badURL, "hello");
Error, CURL_URL: <URL> must be less than 4096 chars

# URL not a string (Download)
gap> DownloadURL(42);
Error, CURL_URL: <URL> must be a string

# URL not a string (Post)
gap> PostURL(42, "hello");
Error, CURL_URL: <URL> must be a string

# post_string not a string
gap> PostURL("httpbin.org/post", 17);                     
Error, CURL_URL: <post_string> must be a string

# invalid verifyCert
gap> DownloadURL("https://www.google.com", "maybe verify cert");
Error, CURL_URL: <verifyCert> must be true or false
