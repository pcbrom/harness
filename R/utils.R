# Internal utilities: binary discovery, environment detection, light assertions.

# Locate an executable by name. Returns the absolute path or NA_character_.
# Looks first on the PATH, then in a small set of conventional install roots,
# then asks the user's login shell. The R process under RStudio inherits a
# trimmed PATH that often omits npm-global, version-manager and similar bins
# that the interactive terminal sees, so the login-shell probe recovers them.
# Returned paths are kept as discovered, without resolving symlinks: launcher
# shims (npm, nvm, version managers) must be invoked through the shim, not
# through the script file they point at.
find_binary <- function(name, extra_paths = character()) {
  hit <- unname(Sys.which(name))
  if (nzchar(hit)) {
    return(hit)
  }
  home <- path.expand("~")
  candidates <- c(
    extra_paths,
    file.path(home, ".local", "bin", name),
    file.path(home, "bin", name),
    file.path(home, ".npm-global", "bin", name),
    file.path(home, ".local", "share", "npm", "bin", name),
    file.path(home, ".bun", "bin", name),
    file.path(home, ".opencode", "bin", name),
    # node version managers keep their bins outside the default PATH: nvm and
    # fnm install global CLIs (opencode, codex) under a per-version bin dir.
    rev(Sys.glob(file.path(home, ".nvm", "versions", "node", "*", "bin", name))),
    rev(Sys.glob(file.path(home, ".local", "share", "fnm", "node-versions",
                           "*", "installation", "bin", name))),
    file.path("/usr", "local", "bin", name),
    file.path("/opt", "homebrew", "bin", name)
  )
  for (cand in candidates) {
    if (file.exists(cand)) {
      return(cand)
    }
  }
  find_binary_via_login_shell(name)
}

# Ask the user's shell for the binary path. PATH entries from version managers
# live either in the login profile or in the interactive rc, so both a login
# (-lc) and an interactive (-ic) probe are tried; the interactive one matches
# the terminal that the user actually launches the coder in. Bounded with a
# timeout when available, and silent on any failure.
find_binary_via_login_shell <- function(name) {
  if (.Platform$OS.type != "unix") {
    return(NA_character_)
  }
  shell <- Sys.getenv("SHELL", "")
  if (!nzchar(shell)) {
    shell <- "bash"
  }
  probe <- paste0("command -v ", name, " 2>/dev/null")
  timeout_bin <- unname(Sys.which("timeout"))
  for (flags in c("-lc", "-ic")) {
    out <- tryCatch(
      suppressWarnings(
        if (nzchar(timeout_bin)) {
          system2(timeout_bin, c("5", shell, flags, shQuote(probe)),
                  stdout = TRUE, stderr = FALSE)
        } else {
          system2(shell, c(flags, shQuote(probe)), stdout = TRUE, stderr = FALSE)
        }
      ),
      error = function(e) character()
    )
    out <- out[nzchar(out)]
    if (length(out) >= 1L) {
      cand <- out[length(out)]
      if (file.exists(cand)) {
        return(cand)
      }
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
