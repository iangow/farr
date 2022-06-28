set.seed(2021)

temp <- get_got_data(N = 500, T = 10, Xvol = 0.75,
                     Evol = 0.75, rho_X = 0.5, rho_E = 0.5)

test_that("get_got_data works", {
  expect_equal(length(unique(temp$firm)), 500)
})
