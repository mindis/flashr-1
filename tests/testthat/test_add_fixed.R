test_that("adding sparse factors/loadings works", {
  set.seed(1)
  n = 20
  p = 50

  n_ll = 1
  ll1 = matrix(0, ncol=n_ll, nrow=n)
  ll1[1:5, 1] = c(1, 2, 3, 4, 5)
  ff1 = matrix(rnorm(n_ll*p), ncol=n_ll, nrow=p)
  Y = ll1 %*% t(ff1) + rnorm(n*p)

  # Test adding sparse loadings:
  LL = ll1
  LL[LL != 0] = NA
  fl = flash_add_fixed_loadings(Y, LL = LL, backfit = FALSE)$fit
  # Check that sparsity pattern is maintained and fixl is set correctly:
  expect_equal(sum(fl$EL[ll1 == 0] != 0), 0)
  expect_equal(sum(fl$EL[ll1 != 0] == 0), 0)
  expect_equal(sum(fl$fixl[ll1 == 0] == FALSE), 0)
  expect_equal(sum(fl$fixl[ll1 != 0] == TRUE), 0)

  n_ff = 2
  ff2 = matrix(0, ncol=n_ff, nrow=p)
  ff2[1:5, 1] = c(1, 2, 3, 4, 5)
  ff2[6:10, 2] = rep(10, 5)
  ll2 = matrix(rnorm(n_ff*n), ncol=n_ff, nrow=n)
  Y = Y + ll2 %*% t(ff2)

  # Test sparse factors (add to existing matrix):
  FF = ff2
  FF[FF != 0] = NA
  fl = flash_add_fixed_factors(Y, FF, f_init=fl, backfit=FALSE)$fit
  # Check that sparsity pattern is maintained and fixf is set correctly:
  EF = fl$EF
  expect_equal(sum(EF[,(n_ll+1):ncol(EF)][ff2 == 0] != 0), 0)
  expect_equal(sum(EF[,(n_ll+1):ncol(EF)][ff2 != 0] == 0), 0)
  fixf = fl$fixf
  expect_equal(sum(fixf[,(n_ll+1):ncol(fixf)][ff2 == 0] == FALSE), 0)
  expect_equal(sum(fixf[,(n_ll+1):ncol(fixf)][ff2 != 0] == TRUE), 0)

  # Add a factor with only one missing element:
  FF = matrix(c(NA, rep(1, p-1)), ncol=1)
  fl = flash_add_fixed_factors(Y, FF, f_init=fl, backfit = FALSE)$fit
  fixf = fl$fixf
  expect_equal(sum(fixf[,(n_ll+n_ff+1):ncol(fixf)][!is.na(FF)] == FALSE), 0)
  expect_equal(sum(fixf[,(n_ll+n_ff+1):ncol(fixf)][is.na(FF)] == TRUE), 0)

  # Add a bunch of loadings with all fixed elements:
  LL = diag(1, nrow=n, ncol=n)
  fl = flash_add_fixed_loadings(Y, LL, f_init=fl, backfit=FALSE)$fit
  expect_equal(sum(fl$fixl[,(n_ll+n_ff+2):ncol(fl$fixl)] == FALSE), 0)
  # factors not fixed:
  expect_equal(sum(fl$fixf[,(n_ll+n_ff+2):ncol(fl$fixf)] == TRUE), 0)

  # Add vector:
  LL = rep(1, n)
  fl = flash_add_fixed_loadings(Y, LL, backfit=FALSE)$fit
  # Try to add vector of wrong dimension:
  LL = rep(1, n + 1)
  expect_error(fl = flash_add_fixed_loadings(Y, LL, fl))
  # Try to add fixl that doesn't match LL:
  LL = matrix(1, nrow=n, ncol=2)
  fixl = rep(1, n)
  expect_error(fl = flash_add_fixed_loadings(Y, LL, fl, fixl))

  # Test with missing data:
  Y.na = Y
  Y.na[sample(n*p, floor(0.1*n*p), replace = FALSE)] = NA

  LL = diag(1, nrow=n, ncol=n)
  fl = flash_add_fixed_loadings(Y.na, LL, backfit=FALSE)
  fl = flash(Y.na, f_init=fl, backfit=TRUE, greedy=FALSE, nullcheck=FALSE, tol=1)
  expect_equal(fl$fit$fixl, matrix(TRUE, nrow=n, ncol=n))

  FF = c(rep(1, 5), rep(NA, p - 5))
  fl = flash_add_fixed_factors(Y.na, FF, backfit=FALSE)
  fl = flash(Y.na, f_init=fl, backfit=TRUE, greedy=FALSE, nullcheck=FALSE, tol=1)
  expect_equal(fl$fit$fixf, matrix(c(rep(TRUE, 5), rep(FALSE, p - 5)), ncol=1))
})
