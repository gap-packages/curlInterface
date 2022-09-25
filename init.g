#
# curlInterface: Simple Web Access
#
# Reading the declaration part of the package.
#
_PATH_SO:=Filename(DirectoriesPackagePrograms("curlInterface"), "curl.so");
if _PATH_SO <> fail then
    LoadDynamicModule(_PATH_SO);
fi;
Unbind(_PATH_SO);

# work around a bug in some PackageManager versions, see
# <https://github.com/gap-packages/PackageManager/pull/100>.
Unbind(DownloadURL);

ReadPackage( "curlInterface", "gap/curl.gd");
