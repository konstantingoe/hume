test_that("spearmans rho actually between [-1,1]", {
  expect_equal(spearman(x <- sample(10,10),2*x), 1)
  expect_equal(spearman("cat","dog"), NaN)
})
