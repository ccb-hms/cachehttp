## See https://github.com/rstudio/httpuv#readme

## Use the httpuv package to serve files at
##
## http://192.168.0.1:<PORT>/<key>/<suffix>
##
## Step 1: Identify <key> from URL string s
##
## Step 2: Raise error if <key> is not in names(.cachehttpMaps)
##
## Step 3: Evaluate h = fun(<suffix>). If FALSE, return a redirect
##         response [?] or download and serve file

## .cachehttpMaps[[key]] <- list(value = value, fun = fun)


## FIXME: may want to provide a way to customize cache location

.wrapURL <- function(url) {
    bfcrpath(BiocFileCache(), url)
}

.contentType <- function(suffix) {
    switch(file_ext(suffix),
           htm = 'text/html',
           html = 'text/html',
           xpt = 'application/octet-stream',
           'application/octet-stream')
}


serveURL <- function(req, verbose = getOption("verbose"))
{
    .GlobalEnv$last_req <- req
    if (verbose) print(ls.str(req))
    s <- req$PATH_INFO
    ## s looks like /<key>/suffix
    ssplit <- strsplit(s, split = "/", fixed = TRUE)[[1]]
    key <- ssplit[[2]]
    suffix <- paste(tail(ssplit, -2), collapse = "/")
    if (!(key %in% names(.cachehttpMaps))) stop("Invalid key")
    map <- .cachehttpMaps[[key]]
    doCache <- map$fun(suffix) # whether to cache
    remoteURL <- paste0(map$value, "/", suffix)
    if (verbose) str(list(key = key, suffix = suffix, cache = doCache, remoteURL = remoteURL))

    if (doCache) {
        localFile <- .wrapURL(remoteURL)
        if (verbose) cat(sprintf("cache: %s -> %s\n", suffix, basename(localFile)))

        ## It is not immediately clear from httpuv docs or README that
        ## the following should work, but the docs refer to the rook
        ## specification
        ##
        ## https://github.com/jeffreyhorner/Rook/blob/a5e45f751/README.md
        ## 
        ## which says that if body = c(file = localFile), the contents
        ## of localFile will be served. As of httpuv_1.6.12, this does
        ## _not_ work [why??], but body = list(file = localFile)
        ## does. From the code, it appears that body$owned [FALSE] can
        ## also be set, but not sure what that is.
  
        list(status = 200L,
             headers = list('Content-Type' = .contentType(suffix)),
             body = list(file = localFile))
    }
    else { # redirect
        ## FIXME: use http temporary redirect with 'Location' header
        ## instead) - but check that download.file() works
        list(status = 200L,
             headers = list('Content-Type' = 'text/html'),
             body = sprintf("<head><meta http-equiv='Refresh' content='0; URL=%s%s' /></head>",
                            remoteURL, req$QUERY_STRING))
    }
}


## Should we always start this in .onLoad()?

start_cache <- function(host = "0.0.0.0", port = 8080, static_path = "")
{
    app <- list(
        call = function(req) {
            serveURL(req)
        },
        staticPaths = list("/cache" = staticPath(static_path, indexhtml = FALSE))
    )
    s <- startServer(host = host, port = port,
                     app = app)
    s
}



