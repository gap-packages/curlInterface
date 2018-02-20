#
# test error handling
#

# URL too long
gap> badURL := ListWithIdenticalEntries(4096,' ');;
gap> DownloadURL(badURL);
Error, ReadURL: <URL> must be less than 4096 chars
