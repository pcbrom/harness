test_that("scaffold_layout reports without creating when create = FALSE", {
  proj <- make_fake_project()
  out <- scaffold_layout("data-scientist", proj, create = FALSE)
  expect_s3_class(out, "data.frame")
  expect_true(all(!out$existed))
  expect_false(dir.exists(file.path(proj, "analysis", "scripts")))
})

test_that("scaffold_layout creates the declared folders when create = TRUE", {
  proj <- make_fake_project()
  out <- scaffold_layout("data-scientist", proj, create = TRUE)
  for (p in out$path) {
    expect_true(dir.exists(file.path(proj, p)))
  }
})

test_that("scaffold_layout is idempotent", {
  proj <- make_fake_project()
  scaffold_layout("statistician", proj, create = TRUE)
  out <- scaffold_layout("statistician", proj, create = TRUE)
  expect_true(all(out$existed))
})
