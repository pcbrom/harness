test_that("available_roles lists the four phase-1 harnesses", {
  roles <- available_roles()
  expect_setequal(
    roles,
    c("data-scientist", "statistician", "package-maintainer", "paper-author")
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
