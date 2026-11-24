source(here::here("R", "_load.R"))

wk <- function(n, start = "2020-03-05") as.Date(start) + 7 * (seq_len(n) - 1)

test_that("clean_curve drops leftover values of the previous campaign", {
  v <- c(100, 100, 0, 0, 0, 20, 60, 100, 100)
  cc <- clean_curve(wk(9), v)
  expect_equal(cc$status, "ok")
  expect_equal(cc$points$value, c(0, 20, 60, 100))
  expect_equal(cc$points$date[1], wk(9)[5]) # last zero before the rise
})

test_that("clean_curve flags incomplete and late-starting curves", {
  expect_equal(clean_curve(wk(5), c(0, 10, 30, 50, 70))$status, "incomplete")
  cc <- clean_curve(wk(4), c(30, 60, 90, 100))
  expect_equal(cc$status, "starts_above_zero")
  expect_true(cc$flags$starts_above_zero)
})

test_that("stale repeats are dropped, but 0 and 100 are kept", {
  cc <- clean_curve(wk(6), c(0, 30, 30, 30, 70, 100))
  expect_equal(cc$points$value, c(0, 30, 70, 100))
  expect_equal(cc$flags$n_stale_dropped, 2L)
  cc2 <- clean_curve(wk(6), c(0, 30, 30, 30, 70, 100), drop_stale_repeats = FALSE)
  expect_equal(nrow(cc2$points), 6)
})

test_that("linear 50 % date interpolates between bracketing records", {
  p <- tibble(date = wk(4), value = c(0, 40, 60, 100))
  r <- date50_linear(p)
  expect_equal(r$date50, wk(4)[2] + 4) # 3.5 days, rounded half up
  expect_equal(date50_linear(tibble(date = wk(3), value = c(0, 50, 100)))$date50, wk(3)[2])
  expect_equal(date50_linear(tibble(date = wk(2), value = c(60, 100)))$status, "starts_above_50")
})

test_that("dates crossing 1 January are handled", {
  p <- tibble(date = as.Date(c("2019-12-19", "2020-01-09")), value = c(20, 80))
  expect_equal(date50_linear(p)$date50, as.Date("2019-12-30")) # 10.5 days after 19 Dec
})

test_that("logistic fit recovers a known t50 and scale", {
  d <- as.Date("2020-04-02") + seq(0, 70, 7)
  t <- as.numeric(d - d[1])
  v <- round(100 / (1 + exp((30 - t) / 6)), 1)
  r <- date50_logistic(tibble(date = d, value = v))
  expect_equal(r$status, "ok")
  expect_equal(as.numeric(r$date50 - d[1]), 30, tolerance = 1)
  expect_equal(r$scale_days, 6, tolerance = 0.1)
})

test_that("campaign = harvest year", {
  dates <- as.Date(c("2019-08-29", "2019-09-05", "2020-07-16"))
  expect_equal(assign_campaign(dates, rep("winter", 3), campaign_start_month), c(2019L, 2020L, 2020L))
  expect_equal(assign_campaign(dates, rep("spring", 3), campaign_start_month), c(2019L, 2019L, 2020L))
})
