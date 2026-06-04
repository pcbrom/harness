test_that("find_binary locates a binary on the PATH", {
  skip_on_os("windows")
  expect_true(nzchar(find_binary("ls")))
})

test_that("find_binary returns NA for an absent binary without erroring", {
  expect_true(is.na(find_binary("definitely-no-such-binary-xyz123")))
})

test_that("find_binary does not resolve symlinks to their target", {
  skip_on_os("windows")
  tmp <- withr::local_tempdir()
  real <- file.path(tmp, "real-tool")
  writeLines("#!/bin/sh\n", real)
  Sys.chmod(real, "0755")
  shim <- file.path(tmp, "tool-shim")
  ok <- file.symlink(real, shim)
  skip_if_not(ok, "symlink not supported")
  withr::local_envvar(PATH = paste(tmp, Sys.getenv("PATH"), sep = .Platform$path.sep))
  found <- find_binary("tool-shim")
  expect_match(found, "tool-shim$")
})
