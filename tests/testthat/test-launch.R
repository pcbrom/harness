test_that("dry_run configures the session without opening a terminal", {
  root <- make_fake_checkout(c("dplyr", "ggplot2", "tidyr"))
  home <- make_fake_project()
  proj <- make_fake_project()
  res <- launch(
    "claude", role = "data-scientist", project_dir = proj,
    dry_run = TRUE, config_home = home, skills_path = root
  )
  expect_s3_class(res, "harness_launch")
  expect_true(res$dry_run)
  expect_false(res$spawned)
  expect_identical(res$role, "data-scientist")
  expect_true(file.exists(res$config$settings_path))
  expect_true(dir.exists(file.path(proj, "analysis", "scripts")))
})

test_that("launch reports a manual command when no terminal is available", {
  root <- make_fake_checkout(c("dplyr"))
  home <- make_fake_project()
  proj <- make_fake_project()
  testthat::local_mocked_bindings(
    is_rstudio_terminal = function() FALSE,
    find_terminal_emulator = function() NULL
  )
  expect_message(
    res <- launch(
      "claude", role = "data-scientist", project_dir = proj,
      dry_run = FALSE, config_home = home, skills_path = root,
      binary = "claude-test-binary"
    ),
    "Run, in"
  )
  expect_false(res$spawned)
  expect_identical(res$method, "manual")
})

test_that("launch opens an RStudio terminal when one is available", {
  root <- make_fake_checkout(c("dplyr"))
  home <- make_fake_project()
  proj <- make_fake_project()
  sent <- new.env()
  sent$lines <- character()
  testthat::local_mocked_bindings(
    is_rstudio_terminal = function() TRUE
  )
  testthat::local_mocked_bindings(
    terminalCreate = function(...) "term-1",
    terminalSend = function(id, text) {
      sent$lines <- c(sent$lines, text)
      invisible(NULL)
    },
    .package = "rstudioapi"
  )
  res <- launch(
    "claude", role = "data-scientist", project_dir = proj,
    dry_run = FALSE, config_home = home, skills_path = root,
    binary = "claude-test-binary"
  )
  expect_true(res$spawned)
  expect_identical(res$method, "rstudio")
  expect_true(any(grepl("claude-test-binary", sent$lines)))
})

test_that("unique_terminal_caption avoids a caption already in use", {
  testthat::local_mocked_bindings(
    terminalList = function() "t1",
    terminalContext = function(id) list(caption = "harness:claude:data-scientist"),
    .package = "rstudioapi"
  )
  cap <- unique_terminal_caption("harness:claude:data-scientist")
  expect_identical(cap, "harness:claude:data-scientist (2)")
})

test_that("unique_terminal_caption returns the base when it is free", {
  testthat::local_mocked_bindings(
    terminalList = function() character(),
    terminalContext = function(id) list(caption = ""),
    .package = "rstudioapi"
  )
  expect_identical(
    unique_terminal_caption("harness:codex:statistician"),
    "harness:codex:statistician"
  )
})

test_that("launch requires a role", {
  expect_error(launch("claude"), "role")
})
