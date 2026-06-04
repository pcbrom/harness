# Smoke tests for the opencode and codex adapters, mirroring the claude tests.

test_that("opencode and codex are registered", {
  expect_true(all(c("claude", "opencode", "codex") %in% adapters()))
})

test_that("opencode build_config writes opencode.json and links skills", {
  root <- make_fake_checkout(c("dplyr", "ggplot2", "tidyr"))
  proj <- make_fake_project()
  ad <- get_adapter("opencode")
  cfg <- ad$build_config(
    role("data-scientist"), proj,
    opts = list(config_home = proj, skills_path = root)
  )
  expect_true(file.exists(cfg$settings_path))
  expect_match(cfg$settings_path, "opencode\\.json$")
  expect_true(all(c("dplyr", "ggplot2", "tidyr") %in% cfg$skills_linked))
  expect_true("broom" %in% cfg$skills_missing)
  settings <- jsonlite::read_json(cfg$settings_path)
  expect_identical(settings$harness$execution_policy, "manual")
  expect_true(file.exists(file.path(cfg$skills_root, "dplyr", "SKILL.md")))
  # prompt lands in AGENTS.md
  expect_true(file.exists(file.path(proj, "AGENTS.md")))
})

test_that("codex build_config writes .codex/config.json and links skills", {
  root <- make_fake_checkout(c("dplyr"))
  proj <- make_fake_project()
  ad <- get_adapter("codex")
  cfg <- ad$build_config(
    role("data-scientist"), proj,
    opts = list(skills_path = root)
  )
  expect_true(file.exists(cfg$settings_path))
  expect_match(cfg$settings_path, "\\.codex/config\\.json$")
  expect_true("dplyr" %in% cfg$skills_linked)
  expect_true(file.exists(file.path(proj, "AGENTS.md")))
})

test_that("an existing AGENTS.md is not overwritten", {
  root <- make_fake_checkout(c("dplyr"))
  proj <- make_fake_project()
  writeLines("user owned agents file", file.path(proj, "AGENTS.md"))
  ad <- get_adapter("opencode")
  cfg <- ad$build_config(
    role("data-scientist"), proj,
    opts = list(config_home = proj, skills_path = root)
  )
  expect_identical(readLines(file.path(proj, "AGENTS.md"))[1], "user owned agents file")
  expect_match(cfg$prompt_file, "harness-data-scientist\\.md$")
})

test_that("opencode config merge preserves existing keys", {
  root <- make_fake_checkout(c("dplyr"))
  proj <- make_fake_project()
  jsonlite::write_json(
    list(model = "anthropic/claude"), file.path(proj, "opencode.json"),
    auto_unbox = TRUE
  )
  ad <- get_adapter("opencode")
  ad$build_config(
    role("data-scientist"), proj,
    opts = list(config_home = proj, skills_path = root)
  )
  settings <- jsonlite::read_json(file.path(proj, "opencode.json"))
  expect_identical(settings$model, "anthropic/claude")
  expect_identical(settings$harness$role, "data-scientist")
})

test_that("dry_run launch works for opencode and codex", {
  root <- make_fake_checkout(c("dplyr"))
  for (coder in c("opencode", "codex")) {
    proj <- make_fake_project()
    res <- launch(
      coder, role = "data-scientist", project_dir = proj,
      dry_run = TRUE, skills_path = root
    )
    expect_s3_class(res, "harness_launch")
    expect_identical(res$adapter, coder)
    expect_true(file.exists(res$config$settings_path))
  }
})

test_that("role_list tabulates every role", {
  rl <- role_list()
  expect_s3_class(rl, "data.frame")
  expect_setequal(rl$role, available_roles())
  expect_true(all(rl$skills > 0L))
  expect_true(all(c("role", "version", "skills", "description") %in% names(rl)))
})
