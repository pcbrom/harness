# Internal utilities: binary discovery, environment detection, light assertions.

# Locate an executable by name. Returns the absolute path or NA_character_.
# Looks first on the PATH, then in a small set of conventional install roots
# so that discovery works in non-login shells where PATH is trimmed.
find_binary <- function(name, extra_paths = character()) {
  hit <- unname(Sys.which(name))
  if (nzchar(hit)) {
    return(normalizePath(hit, mustWork = FALSE))
  }
  candidates <- c(
    extra_paths,
    file.path(path.expand("~"), ".local", "bin", name),
    file.path(path.expand("~"), "bin", name),
    file.path("/usr", "local", "bin", name),
    file.path("/opt", "homebrew", "bin", name)
  )
  for (cand in candidates) {
    if (file.exists(cand)) {
      return(normalizePath(cand, mustWork = FALSE))
    }
  }
  NA_character_
}

# Path to the bundled harness catalogue inside the installed package.
harness_catalogue_dir <- function() {
  system.file("harness", package = "harness")
}

# TRUE when running inside an RStudio session that exposes the rstudioapi
# terminal API. Kept defensive so the package also loads in plain R.
is_rstudio_terminal <- function() {
  if (!nzchar(Sys.getenv("RSTUDIO"))) {
    return(FALSE)
  }
  if (!requireNamespace("rstudioapi", quietly = TRUE)) {
    return(FALSE)
  }
  isTRUE(rstudioapi::isAvailable()) &&
    isTRUE(rstudioapi::hasFun("terminalCreate"))
}

# Detect an external terminal emulator for the headless fallback path.
find_terminal_emulator <- function() {
  if (identical(Sys.info()[["sysname"]], "Darwin")) {
    return(list(name = "open", launch = "open"))
  }
  for (term in c("x-terminal-emulator", "gnome-terminal", "konsole", "xterm")) {
    hit <- find_binary(term)
    if (!is.na(hit)) {
      return(list(name = term, launch = hit))
    }
  }
  NULL
}

# Coerce a YAML scalar or sequence to a character vector, dropping empties.
as_character_vector <- function(x) {
  if (is.null(x)) {
    return(character())
  }
  out <- unlist(x, use.names = FALSE)
  out <- as.character(out)
  out[nzchar(trimws(out))]
}

# Stop with a message tagged for the package, so callers can match the class.
harness_abort <- function(message, class = "harness_error") {
  cond <- structure(
    class = c(class, "harness_error", "error", "condition"),
    list(message = message, call = sys.call(-1))
  )
  stop(cond)
}
