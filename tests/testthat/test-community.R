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
