# RFC: Caching of web resources

Proposal for an R package that would enable transparent caching of HTTP resources:

The main idea is to use the httpuv package (or something similar) to serve files from a 'local' address such as
`http://192.168.0.1:<PORT>/` that would use BiocFileCache internally.

Users would specify a mapping as follows, say:

```
cacheMap(local = "local-nhanes", remote = "https://wwwn.cdc.gov/nchs/nhanes",
         fun = function(x) {
             x <- tolower(x)
             endsWith(x, "htm") || endWith(x, "xpt")
         })
```

The server's algorithm would be as follows:

If a URL of the form `http://192.168.0.1:<PORT>/local-nhanes/foo/bar.html` is requested, it will 

- check if the first part (`local-nhanes`) matches an existing local key (otherwise go to the non-caching branch)

- call `fun(foo/bar.html)` to determine if the file should be cached (the default, if `fun = NULL`, is `TRUE`). This is to ensure we can skip special URLs which are doing searches or something similar. Otherwise go to the non-caching branch

- If caching, use BiocFileCache() to cache, and serve the downloaded file

- If not caching, download the file in a temporary location and serve

