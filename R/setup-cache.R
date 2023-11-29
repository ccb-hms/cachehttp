

## Caching can be set up for multiple 'hosts'. Local URLs must always be of the form
##
## http://192.168.0.1:<PORT>/<key>/<suffix>
##
## Such a URL will be mapped to
##
## <value(key)>/<suffix>
##
## So, for example, we may call
##
## cacheMap(cran = "https://cloud.r-project.org")
##
## to make <http://192.168.0.1:<PORT>/cran/> a 'mirror' of <https://cloud.r-project.org/>
##
## The 'fun' function is an opportunity to say that only certain kinds of files would be cached. We could have
##
## fun = function(x) {
##     x <- tolower(x)
##     endsWith(x, ".tar.gz") || endsWith(x, ".tgz") || endsWith(x, "zip")
## })
##
## to cache only package files and nothing else (including html files)


.cachehttpMaps <- new.env(parent = emptyenv())


cacheMap <- function(key, value, fun = NULL, warn = TRUE)
{
    if (is.null(fun)) fun <- function(x) TRUE
    stopifnot(is.character(key), is.character(value), is.function(fun))
    if (key == "cache") stop("'cache' is not allowed as a key as it is reserved for internal use")
    if (warn && !is.null(.cachehttpMaps[[key]])) {
        warning("Replacing existing mapping with key: ", key)
    }
    .cachehttpMaps[[key]] <- list(value = value, fun = fun)
}


