# Session registry of the terminal that launch() opened, so the editor bridge
# can send to it. Stored in a package-local environment; falls back to finding a
# harness terminal by its caption when the registry is empty or stale.

.harness_session <- new.env(parent = emptyenv())

# Record the terminal launch() created.
harness_register_terminal <- function(id, caption, adapter, role) {
  .harness_session$terminal_id <- id
  .harness_session$terminal_caption <- caption
  .harness_session$adapter <- adapter
  .harness_session$role <- role
  invisible(id)
}

# TRUE when a terminal id is still open in the RStudio terminal list.
terminal_exists <- function(id) {
  if (is.null(id) || !nzchar(id)) {
    return(FALSE)
  }
  ids <- tryCatch(rstudioapi::terminalList(), error = function(e) character())
  id %in% ids
}

# Find an open terminal whose caption marks it as a harness terminal.
find_harness_terminal <- function() {
  ids <- tryCatch(rstudioapi::terminalList(), error = function(e) character())
  for (id in ids) {
    ctx <- tryCatch(rstudioapi::terminalContext(id), error = function(e) NULL)
    caption <- if (is.null(ctx)) "" else as.character(ctx$caption %||% "")
    if (startsWith(caption, "harness:")) {
      return(id)
    }
  }
  NULL
}

# The terminal to send to: the registered one if still open, else the first
# harness terminal found in the terminal list, else NULL.
harness_active_terminal <- function() {
  id <- .harness_session$terminal_id
  if (!is.null(id) && terminal_exists(id)) {
    return(id)
  }
  find_harness_terminal()
}
