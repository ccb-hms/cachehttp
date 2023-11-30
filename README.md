# cachehttp: Caching of web resources

An R package to enable transparent caching of HTTP resources:

This package uses the
[httpuv](https://github.com/rstudio/httpuv/#readme) package to serve
files from a 'local' address such as `http://127.0.0.1:<PORT>/` that
would use essentially redirect to an external host, but use the
[BiocFileCache](https://bioconductor.org/packages/release/bioc/html/BiocFileCache.html)
package internally to cache downloaded files.

Users can specify a mapping as follows:

```r
add_cache(key = "cdc", value = "https://wwwn.cdc.gov",
          fun = function(x) {
          x <- tolower(x)
              endsWith(x, "htm") || endsWith(x, "xpt")
          })
```

The server's algorithm would be as follows:

If a URL of the form `http://192.168.0.1:<PORT>/cdc/foo/bar.html` is requested, it will 

- check if first part (`cdc`) matches an existing key (otherwise error)

- call `fun("foo/bar.html")` to determine if the file should be cached
  (the default, if `fun = NULL`, is `TRUE`). This is to ensure we can
  skip special URLs which are doing searches or something
  similar. Otherwise go to the non-caching branch.

- If caching, use `BiocFileCache()` to cache `<value>/foo/bar.html`, and serve the downloaded file

- If not caching, either redirect (this seems to have some issues with
  `download.file()` which need to be investigated further) or download
  the file in a temporary location and serve.



## Install

```r
remotes::install_github("ccb-hms/cachehttp")
```

## Test


```r
require(cachehttp)

add_cache("cdc", "https://wwwn.cdc.gov",
          fun = function(x) {
              x <- tolower(x)
              endsWith(x, ".htm") || endsWith(x, ".xpt")
          })

s <- start_cache(host = "0.0.0.0", port = 8080,
                 static_path = BiocFileCache::bfccache(BiocFileCache::BiocFileCache()))
```

Browsing files seem to be OK.

```r
## should bypass cache and redirect to CDC - but query parameters not handled [TODO]
browseURL("http://127.0.0.1:8080/cdc/nchs/nhanes/search/datapage.aspx?Component=Demographics")

## create cached files explicitly (for testing, will be done automatically during regular use)
cachehttp:::.wrapURL("https://wwwn.cdc.gov/nchs/nhanes/2007-2008/POOLTF_E.htm")
cachehttp:::.wrapURL("https://wwwn.cdc.gov/nchs/nhanes/2007-2008/POOLTF_E.xpt")

## Check that cache URL paths are served as expected [check name in
## putput above and change if needed]
browseURL("http://127.0.0.1:8080/cache/9e5d38d7a4ed_POOLTF_E.htm")

## Finally, the URLs that we are interested in should get redirected to cache URLs
browseURL("http://127.0.0.1:8080/cdc/nchs/nhanes/2007-2008/POOLTF_E.htm")
```

Check that `download.file()` works (it has trouble following
redirects). But _note_ that this has to be run from a _different_
session.

```r
xpt_path <- "~/out.xpt"
download.file("http://127.0.0.1:8080/cdc/nchs/nhanes/2007-2008/POOLTF_E.xpt",
              destfile = xpt_path)
```

## Debugging

To see debugging messages, set

```r
options(verbose = TRUE)
```
