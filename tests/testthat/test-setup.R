test_that("community_skills_path honours COMMUNITY_SKILLS_PATH", {
  root <- make_fake_checkout(c("dplyr", "ggplot2"))
  withr::local_envvar(COMMUNITY_SKILLS_PATH = root)
  expect_identical(community_skills_path(), normalizePath(root, mustWork = FALSE))
})

test_that("community_skills_path returns NA when nothing is discoverable", {
  withr::local_envvar(COMMUNITY_SKILLS_PATH = tempfile("absent"))
  # Both home fallbacks are unlikely to hold a checkout in the check sandbox,
  # but guard the assertion to the env-var contract by pointing HOME away.
  withr::local_envvar(HOME = withr::local_tempdir())
  expect_true(is.na(community_skills_path()))
})

test_that("status() reports roles and registered adapters", {
  st <- status()
  expect_s3_class(st, "harness_status")
  expect_true(length(st$roles) >= 4L)
  expect_true("claude" %in% names(st$adapters))
})

test_that("setup() aborts when no checkout exists", {
  withr::local_envvar(COMMUNITY_SKILLS_PATH = tempfile("absent"))
  withr::local_envvar(HOME = withr::local_tempdir())
  expect_error(setup("data-scientist"), class = "harness_no_community_skills")
})

test_that("setup() reports skill coverage and missing skills", {
  root <- make_fake_checkout(c("dplyr", "ggplot2", "tidyr"))
  withr::local_envvar(COMMUNITY_SKILLS_PATH = root)
  proj <- make_fake_project()
  res <- setup("data-scientist", project_dir = proj, scaffold = TRUE)
  expect_s3_class(res, "harness_setup")
  expect_true(all(c("dplyr", "ggplot2", "tidyr") %in% res$role$skills_present))
  expect_true("broom" %in% res$role$skills_missing)
  expect_true(dir.exists(file.path(proj, "analysis", "scripts")))
})
