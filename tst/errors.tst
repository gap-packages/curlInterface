#
# test error handling
#

# URL too long (Download)
gap> badURL := ListWithIdenticalEntries(4096,' ');;
gap> DownloadURL(badURL);
Error, CURL_URL: <URL> must be less than 4096 chars

# URL not a string (Download)
gap> DownloadURL(42);
Error, CURL_URL: <URL> must be a string
