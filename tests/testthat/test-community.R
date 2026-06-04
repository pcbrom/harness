test_that("clone_community_skills returns an existing checkout without cloning", {
  root <- make_fake_checkout(c("dplyr"))
  expect_message(
    res <- clone_community_skills(dest = root, quiet = FALSE),
    "already present"
  )
  expect_identical(res, normalizePath(root, mustWork = FALSE))
})

test_that("clone_community_skills aborts on a non-empty foreign destination", {
  dest <- make_fake_project()
  writeLines("x", file.path(dest, "some-file"))
  expect_error(
    clone_community_skills(dest = dest),
    class = "harness_clone_dest_exists"
  )
})

test_that("clone_community_skills aborts when git is unavailable", {
  dest <- file.path(make_fake_project(), "fresh-clone")
  testthat::local_mocked_bindings(find_binary = function(...) NA_character_)
  expect_error(
    clone_community_skills(dest = dest),
    class = "harness_no_git"
  )
})

test_that("update_community_skills aborts when no checkout is given", {
  expect_error(
    update_community_skills(dest = NA_character_),
    class = "harness_no_community_skills"
  )
})

test_that("update_community_skills aborts on a non-git checkout", {
  root <- make_fake_checkout(c("dplyr"))
  expect_error(
    update_community_skills(dest = root),
    class = "harness_not_git_checkout"
  )
})

test_that("update_community_skills aborts when git is unavailable", {
  root <- make_fake_checkout(c("dplyr"))
  dir.create(file.path(root, ".git"))
  testthat::local_mocked_bindings(find_binary = function(...) NA_character_)
  expect_error(
    update_community_skills(dest = root),
    class = "harness_no_git"
  )
})

test_that("auto-update opt-in honours option and environment variable", {
  withr::local_options(harness.auto_update = NULL)
  withr::local_envvar(HARNESS_AUTO_UPDATE = "")
  expect_false(harness_auto_update_enabled())

  withr::local_options(harness.auto_update = TRUE)
  expect_true(harness_auto_update_enabled())

  withr::local_options(harness.auto_update = NULL)
  withr::local_envvar(HARNESS_AUTO_UPDATE = "yes")
  expect_true(harness_auto_update_enabled())
})
