

## Use the httpuv package to serve files at
##
## http://192.168.0.1:<PORT>/<key>/<suffix>
##
## Step 1: Identify <key> from URL string s
##
## Step 2: Raise error if <key> is not in ls(.cachehttpMaps)
##
## Step 3: Evaluate h = fun(<suffix>). If FALSE, return a redirect
##         response [?] or download and serve file

## .cachehttpMaps[key] <- list(value = value, fun = fun)


## FIXME: may want to provide a way to customize cache location

.wrapURL <- function(url) {
    BiocFileCache::bfcrpath(BiocFileCache::BiocFileCache(), url)
}

.contentType <- function(suffix) {
    switch(tools::file_ext(suffix),
           htm = 'text/html',
           html = 'text/html',
           xpt = 'application/octet-stream',
           'application/octet-stream')
}


serveURL <- function(s)
{
    ## s looks like /<key>/suffix
    ssplit <- strsplit(s, split = "/", fixed = TRUE)[[1]]
    key <- ssplit[[2]]
    suffix <- paste(tail(ssplit, -2), collapse = "/")
    map <- .cachehttpMaps[[key]]
    h <- map$fun(suffix) # whether to cache
    remoteURL <- paste0(map$value, "/", suffix)
    str(list(key = key, suffix = suffix, h = h, remoteURL = remoteURL))
    if (h) {
        ## do caching

        localFile <- basename(.wrapURL(remoteURL))
        cat(sprintf("cache: %s -> %s\n", suffix, localFile))
        ## redirectTarget <- paste0("/cache/", localFile)
        redirectTarget <- paste0("http://127.0.0.1:8080/cache/", localFile)

        ## Attempt at HTTP redirect, but this doesn't work
###        if (FALSE)
        return(
            list(status = 301L,
                 headers = list('Content-Type' = .contentType(suffix),
                                'Location' = redirectTarget),
                 body = '')
        )

        ## Use HTML redirect instead. This works in a browser, but
        ## unfortuntely not in download.file(). We may have better
        ## luck with HTTP redirects if we can figure out how to do it.
        if (FALSE)
            list(status = 200L,
                 headers = list('Content-Type' = 'text/html'),
                 body = sprintf("<head><meta http-equiv='Refresh' content='0; URL=%s' /></head>",
                                redirectTarget))

        ## Very bad solution (esp for xpt files): return body as
        ## character string - what happens if there are NUL
        ## characters?

        list(status = 200L,
             headers = list('Content-Type' = .contentType(suffix)),
             body = '')
        

    }
    else { # redirect (FIXME: use http temporary redirect instead)
        list(status = 200L,
             headers = list('Content-Type' = 'text/html'),
             body = sprintf("<head><meta http-equiv='Refresh' content='0; URL=%s' /></head>",
                            remoteURL))
    }
}

## See https://github.com/rstudio/httpuv#readme

setupServer <- function(host = "0.0.0.0", port = 8080, static_path = "")
{
    app <- list(
        call = function(req) {
            suffix <- req$PATH_INFO
            serveURL(suffix)
        },
        staticPaths = list("/cache" = staticPath(static_path, indexhtml = FALSE))
    )
    s <- startServer(host = host, port = port,
                     app = app)
    s
}



