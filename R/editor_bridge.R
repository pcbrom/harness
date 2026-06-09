# Editor bridge: an RStudio addin that sends the editor selection, with a short
# note, to the coder running in the harness terminal tab. It forwards text the
# user wrote; it does not run an agent loop and does not call a language model,
# so it stays within the audit-first design.

# Compose the one-line message: the note, then a file:line reference to the
# selection. The reference keeps the message a single line, which an interactive
# coder submits as one prompt; the coder opens the file to read the lines.
compose_bridge_message <- function(context, selection, note) {
  path <- context$path %||% ""
  ref <- ""
  rng <- selection$range
  if (nzchar(path) && !is.null(rng)) {
    ref <- sprintf("%s:%d-%d", basename(path),
                   rng$start[[1]], rng$end[[1]])
  }
  parts <- c(trimws(note), if (nzchar(ref)) paste0("(", ref, ")"))
  paste(parts[nzchar(parts)], collapse = " ")
}

#' Send the editor selection to the coder terminal
#'
#' An RStudio addin. It reads the current editor selection, asks for a short
#' note, and sends the note with a `file:line` reference to the coder running in
#' the harness terminal that [launch()] opened. Bind it to a keyboard shortcut
#' through Tools, Modify Keyboard Shortcuts, Addins.
#'
#' The function forwards text the user wrote; it does not run an agent loop and
#' does not call a language model. It requires RStudio and an open harness
#' terminal.
#'
#' @return The message sent, invisibly, or `NULL` when cancelled.
#' @export
send_selection_to_coder <- function() {
  if (!requireNamespace("rstudioapi", quietly = TRUE) ||
      !isTRUE(rstudioapi::isAvailable())) {
    harness_abort("send_selection_to_coder() requires RStudio.",
                  class = "harness_no_rstudio")
  }
  context <- rstudioapi::getSourceEditorContext()
  if (is.null(context)) {
    harness_abort("no active source editor to read a selection from.",
                  class = "harness_no_editor")
  }
  note <- rstudioapi::showPrompt("harness", "Note for the coder:", "")
  if (is.null(note)) {
    return(invisible(NULL))
  }
  selection <- context$selection[[1]]
  message_text <- compose_bridge_message(context, selection, note)
  if (!nzchar(message_text)) {
    return(invisible(NULL))
  }
  id <- harness_active_terminal()
  if (is.null(id)) {
    harness_abort(
      "no harness terminal found; launch() a coder first.",
      class = "harness_no_terminal"
    )
  }
  rstudioapi::terminalSend(id, paste0(message_text, "\n"))
  if (rstudioapi::hasFun("terminalActivate")) {
    rstudioapi::terminalActivate(id)
  }
  invisible(message_text)
}
