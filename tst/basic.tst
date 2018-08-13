gap> LoadPackage("curlInterface", false);
true

# Check HTTP
gap> r := DownloadURL("http://www.google.com");;
gap> SortedList(RecNames(r));
[ "result", "success" ]
gap> r.success;
true
gap> IsMatchingSublist(r.result, "google");
false
gap> IsMatchingSublist("google", r.result);
false

# Sanity check the result without actually printing it
gap>  PositionSublist(r.result, "google") <> fail;
true
gap> r.result[1];
'<'

# Check HTTPS
gap> r := DownloadURL("https://www.google.com");;
gap> SortedList(RecNames(r));
[ "result", "success" ]
gap> r.success;
true
gap> IsMatchingSublist(r.result, "google");
false
gap> IsMatchingSublist("google", r.result);
false

# Sanity check the result without actually printing it
gap>  PositionSublist(r.result, "google") <> fail;
true
gap> r.result[1];
'<'

# Check FTP
gap> r := DownloadURL("ftp://speedtest.tele2.net/1KB.zip");;
gap> SortedList(RecNames(r));
[ "result", "success" ]
gap> r.success;
true
gap> r.result = ListWithIdenticalEntries(1024, '\000');
true

# Check bad URL
gap> r := DownloadURL("https://www.google.cheesebadger");;
gap> SortedList(RecNames(r));
[ "error", "success" ]
gap> r.success;
false
gap> r.error;
"Could not resolve host: www.google.cheesebadger"

# Check successful POST requests
gap> r := PostURL("httpbin.org/post", "field1=true&field2=17");;
gap> SortedList(RecNames(r));
[ "result", "success" ]
gap> r.success;
true
gap> PositionSublist(r.result, "\"field1\": \"true\"") <> fail;
true
gap> PositionSublist(r.result, "\"field2\": \"17\"") <> fail;  
true
gap> PositionSublist(r.result, "field3") <> fail;
false

# Check POST method not allowed (405)
gap> r := PostURL("www.google.com", "myfield=42");;
gap> SortedList(RecNames(r));
[ "result", "success" ]
gap> r.success;
true
gap> PositionSublist(r.result, "myfield") <> fail;
false
gap> PositionSublist(r.result, "405") <> fail;
true

# Check bad URL with POST
gap> r := PostURL("https://www.google.cheesebadger", "hello");;
gap> SortedList(RecNames(r));
[ "error", "success" ]
gap> r.success;
false
gap> r.error;
"Could not resolve host: www.google.cheesebadger"

# Check not IsStringRep (url)
gap> url := List("https://www.google.com", letter -> letter);;
gap> IsStringRep(url);
false
gap> r := DownloadURL(url);;
gap> SortedList(RecNames(r));
[ "result", "success" ]
gap> r.success;
true
gap> PositionSublist(r.result, "google") <> fail;
true

# Check not IsStringRep (post_string)
gap> post_string := List("animal=tiger&material=cotton", letter -> letter);;
gap> IsStringRep(post_string);
false
gap> r := PostURL("httpbin.org/post", post_string, true);;
gap> r.success;
true
gap> PositionSublist(r.result, "\"animal\": \"tiger\"") <> fail;
true
gap> PositionSublist(r.result, "\"material\": \"cotton\"") <> fail;
true
gap> PositionSublist(r.result, "lion") <> fail;
false
