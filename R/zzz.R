.onLoad <- function(libname, pkgname) rr_init()

.onUnload <- function(libpath) {
  if (isTRUE(.rr$started) && !is.null(.rr$listener)) try(.rr$listener$stop(), silent = TRUE)
}
