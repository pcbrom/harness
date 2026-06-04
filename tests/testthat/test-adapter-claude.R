test_that("the claude adapter is registered and exposes the interface", {
  expect_true("claude" %in% adapters())
  ad <- get_adapter("claude")
  expect_identical(ad$name, "claude")
  expect_true(is.function(ad$build_config))
  expect_true(is.function(ad$terminal_command))
  expect_true(is.function(ad$find_binary))
})

test_that("get_adapter aborts on an unknown coder", {
  expect_error(get_adapter("no-such-coder"), class = "harness_unknown_adapter")
})

test_that("build_config writes settings, links present skills, reports missing", {
  root <- make_fake_checkout(c("dplyr", "ggplot2", "tidyr", "broom"))
  home <- make_fake_project()
  proj <- make_fake_project()
  ad <- get_adapter("claude")
  cfg <- ad$build_config(
    role("data-scientist"), proj,
    opts = list(config_home = home, skills_path = root)
  )
  expect_true(file.exists(cfg$settings_path))
  expect_true(all(c("dplyr", "ggplot2", "tidyr", "broom") %in% cfg$skills_linked))
  expect_true("gtsummary" %in% cfg$skills_missing)
  # linked skills resolve to a SKILL.md through the symlink
  linked <- file.path(cfg$skills_root, "dplyr", "SKILL.md")
  expect_true(file.exists(linked))
})

test_that("settings.json merge preserves unrelated user keys", {
  root <- make_fake_checkout(c("dplyr"))
  home <- make_fake_project()
  proj <- make_fake_project()
  dir.create(home, showWarnings = FALSE, recursive = TRUE)
  jsonlite::write_json(
    list(theme = "dark", permissions = list(allow = list("Read"))),
    file.path(home, "settings.json"),
    auto_unbox = TRUE, pretty = TRUE
  )
  ad <- get_adapter("claude")
  ad$build_config(
    role("data-scientist"), proj,
    opts = list(config_home = home, skills_path = root)
  )
  settings <- jsonlite::read_json(file.path(home, "settings.json"))
  expect_identical(settings$theme, "dark")
  expect_identical(settings$harness$role, "data-scientist")
  expect_identical(settings$harness$execution_policy, "manual")
})

test_that("build_config writes the role prompt into the project .claude dir", {
  root <- make_fake_checkout(c("dplyr"))
  home <- make_fake_project()
  proj <- make_fake_project()
  ad <- get_adapter("claude")
  cfg <- ad$build_config(
    role("paper-author"), proj,
    opts = list(config_home = home, skills_path = root)
  )
  expect_true(file.exists(cfg$prompt_file))
  body <- paste(readLines(cfg$prompt_file), collapse = "\n")
  expect_match(body, "Execution policy")
})

test_that("build_config aborts when the checkout is absent", {
  home <- make_fake_project()
  proj <- make_fake_project()
  ad <- get_adapter("claude")
  expect_error(
    ad$build_config(
      role("data-scientist"), proj,
      opts = list(config_home = home, skills_path = NA_character_)
    ),
    class = "harness_no_community_skills"
  )
})
