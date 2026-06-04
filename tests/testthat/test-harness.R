test_that("available_roles lists the full taxonomy of seventeen harnesses", {
  roles <- available_roles()
  expect_setequal(
    roles,
    c(
      "data-scientist", "statistician", "package-maintainer", "paper-author",
      "data-engineer", "ml-engineer", "shiny-developer", "code-documenter",
      "econometrician", "epidemiologist", "clinical-biostat",
      "geospatial-analyst", "causal-inference", "forecast-specialist",
      "reproducibility-engineer", "bioinformatician", "performance-engineer"
    )
  )
})

test_that("each bundled harness loads and validates against the schema", {
  for (nm in available_roles()) {
    h <- role(nm)
    expect_s3_class(h, "harness_role")
    expect_identical(h$name, nm)
    expect_true(length(h$skills) > 0L)
    expect_true(is.list(h$layout) && length(h$layout) > 0L)
  }
})

test_that("caveat 2 is structural: every harness pins manual execution", {
  for (nm in available_roles()) {
    h <- role(nm)
    expect_identical(as.character(h$execution_policy), "manual")
  }
})

test_that("validate_harness rejects a missing required field", {
  bad <- list(name = "x", version = "0.1.0", description = "d",
              skills = "dplyr", system_prompt = "p",
              execution_policy = "manual")
  expect_error(validate_harness(bad, "x"), class = "harness_schema_error")
})

test_that("validate_harness rejects a non-manual execution policy", {
  bad <- list(name = "x", version = "0.1.0", description = "d",
              skills = "dplyr", system_prompt = "p",
              layout = list(scripts = "s"), execution_policy = "auto")
  expect_error(validate_harness(bad, "x"), class = "harness_policy_error")
})

test_that("role() aborts on an unknown name", {
  expect_error(role("no-such-role"), class = "harness_unknown_role")
})

test_that("print.harness_role is stable", {
  expect_output(print(role("data-scientist")), "data-scientist")
})

test_that("role_skills lists the skills of a single role", {
  rs <- role_skills("data-scientist")
  expect_s3_class(rs, "data.frame")
  expect_setequal(rs$skill, role("data-scientist")$skills)
  expect_true(all(rs$role == "data-scientist"))
})

test_that("role_skills covers every role when called without a name", {
  rs <- role_skills()
  expect_setequal(unique(rs$role), available_roles())
})

test_that("role_skills marks availability against a fixture checkout", {
  root <- make_fake_checkout(c("dplyr", "ggplot2"))
  withr::local_envvar(COMMUNITY_SKILLS_PATH = root)
  rs <- role_skills("data-scientist", available = TRUE)
  expect_true("available" %in% names(rs))
  expect_true(rs$available[rs$skill == "dplyr"])
  expect_false(rs$available[rs$skill == "gtsummary"])
})
