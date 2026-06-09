test_that("compose_bridge_message builds the note plus a file:line reference", {
  ctx <- list(path = "/proj/analysis/scripts/run.R")
  sel <- list(range = list(start = c(40L, 1L), end = c(58L, 10L)))
  msg <- compose_bridge_message(ctx, sel, "  refactor this  ")
  expect_match(msg, "refactor this")
  expect_match(msg, "run\\.R:40-58")
})

test_that("compose_bridge_message omits the reference without a path", {
  ctx <- list(path = "")
  sel <- list(range = list(start = c(1L, 1L), end = c(1L, 1L)))
  expect_identical(compose_bridge_message(ctx, sel, "note"), "note")
})

test_that("find_harness_terminal returns a terminal with a harness caption", {
  testthat::local_mocked_bindings(
    terminalList = function() c("t1", "t2"),
    terminalContext = function(id) {
      list(caption = if (identical(id, "t2")) {
        "harness:claude:data-scientist"
      } else {
        "other"
      })
    },
    .package = "rstudioapi"
  )
  expect_identical(find_harness_terminal(), "t2")
})

test_that("harness_active_terminal prefers the registered terminal when open", {
  harness_register_terminal("t9", "harness:codex:statistician", "codex",
                            "statistician")
  withr::defer(assign("terminal_id", NULL, envir = .harness_session))
  testthat::local_mocked_bindings(
    terminalList = function() c("t9"),
    .package = "rstudioapi"
  )
  expect_identical(harness_active_terminal(), "t9")
})

test_that("send_selection_to_coder sends the composed message to the terminal", {
  sent <- new.env()
  sent$lines <- character()
  testthat::local_mocked_bindings(
    isAvailable = function(...) TRUE,
    getSourceEditorContext = function(...) {
      list(
        path = "/proj/run.R",
        selection = list(list(
          range = list(start = c(5L, 1L), end = c(9L, 3L)),
          text = "x <- 1"
        ))
      )
    },
    showPrompt = function(...) "do this",
    terminalSend = function(id, text) {
      sent$lines <- c(sent$lines, text)
      invisible(NULL)
    },
    terminalActivate = function(id) invisible(NULL),
    hasFun = function(name) FALSE,
    .package = "rstudioapi"
  )
  testthat::local_mocked_bindings(harness_active_terminal = function() "term-1")
  res <- send_selection_to_coder()
  expect_match(res, "do this")
  expect_match(res, "run\\.R:5-9")
  expect_true(any(grepl("do this", sent$lines)))
})

test_that("send_selection_to_coder returns NULL when the note is cancelled", {
  testthat::local_mocked_bindings(
    isAvailable = function(...) TRUE,
    getSourceEditorContext = function(...) {
      list(path = "/p/x.R", selection = list(list(
        range = list(start = c(1L, 1L), end = c(1L, 1L))
      )))
    },
    showPrompt = function(...) NULL,
    .package = "rstudioapi"
  )
  expect_null(send_selection_to_coder())
})

test_that("send_selection_to_coder aborts when no harness terminal exists", {
  testthat::local_mocked_bindings(
    isAvailable = function(...) TRUE,
    getSourceEditorContext = function(...) {
      list(path = "/p/x.R", selection = list(list(
        range = list(start = c(2L, 1L), end = c(4L, 1L))
      )))
    },
    showPrompt = function(...) "hi",
    .package = "rstudioapi"
  )
  testthat::local_mocked_bindings(harness_active_terminal = function() NULL)
  expect_error(send_selection_to_coder(), class = "harness_no_terminal")
})
