# Date at which 50 % of surveyed fields reached a stage, from a cleaned curve.
#
# Two estimators:
#   - linear: interpolation between the two weekly records bracketing 50 %
#   - logistic: fit of v(t) = 100 / (1 + exp((t50 - t) / scale)) on the whole
#     cleaned curve; t50 is the date at 50 %, `scale` (days) measures the spread
#     of the stage across fields (10 % -> 90 % takes ~4.4 * scale days).
#     The upper asymptote is fixed at 100 %, so no artificial 0/100 % points are
#     needed to stabilise the fit (the legacy EC code padded the curves instead).
#
# Dates are handled as Date objects throughout (no day-of-year arithmetic), so
# curves crossing 1 January need no special treatment.

#' @param points tibble(date, value) from clean_curve()
#' @return tibble with date50, bracket_days (gap between bracketing records),
#'   from_zero (lower bracket is 0 %), status
date50_linear <- function(points) {
  na <- tibble::tibble(date50 = as.Date(NA), bracket_days = NA_real_,
                       from_zero = NA, status = NA_character_)
  if (nrow(points) < 2) return(dplyr::mutate(na, status = "too_few_points"))
  v <- points$value
  d <- points$date
  i <- which(v >= 50)[1]
  if (is.na(i)) return(dplyr::mutate(na, status = "never_reaches_50"))
  if (i == 1) return(dplyr::mutate(na, status = "starts_above_50"))
  if (v[i] == 50) {
    return(tibble::tibble(date50 = d[i], bracket_days = 0, from_zero = FALSE, status = "ok"))
  }
  frac <- (50 - v[i - 1]) / (v[i] - v[i - 1])
  t50 <- as.numeric(d[i - 1]) + frac * as.numeric(d[i] - d[i - 1])
  tibble::tibble(
    date50 = as.Date(round_half_up(t50), origin = "1970-01-01"),
    bracket_days = as.numeric(d[i] - d[i - 1]),
    from_zero = v[i - 1] == 0,
    status = "ok"
  )
}

#' @return tibble with date50, scale_days, rmse, n_points, status
date50_logistic <- function(points, min_points = 3) {
  na <- tibble::tibble(date50 = as.Date(NA), scale_days = NA_real_, rmse = NA_real_,
                       n_points = nrow(points), status = NA_character_)
  if (nrow(points) < min_points) return(dplyr::mutate(na, status = "too_few_points"))
  t0 <- points$date[1]
  df <- data.frame(t = as.numeric(points$date - t0), v = points$value)

  # starting value: first record at or above 50 %
  t_start <- df$t[which(df$v >= 50)[1]]
  if (is.na(t_start)) t_start <- max(df$t)

  fit <- tryCatch(
    stats::nls(v ~ 100 / (1 + exp((t50 - t) / scale)), data = df,
               start = list(t50 = t_start, scale = 5),
               algorithm = "port", lower = c(t50 = -Inf, scale = 0.1),
               control = stats::nls.control(maxiter = 200, warnOnly = FALSE)),
    error = function(e) NULL
  )
  if (is.null(fit)) return(dplyr::mutate(na, status = "no_convergence"))

  cf <- stats::coef(fit)
  if (cf[["t50"]] < min(df$t) - 14 || cf[["t50"]] > max(df$t) + 14) {
    return(dplyr::mutate(na, status = "t50_outside_data"))
  }
  tibble::tibble(
    date50 = t0 + round_half_up(cf[["t50"]]),
    scale_days = cf[["scale"]],
    rmse = sqrt(mean(stats::residuals(fit)^2)),
    n_points = nrow(df),
    status = "ok"
  )
}

# R's round() rounds half to even, which would make x.5 days depend on parity
round_half_up <- function(x) floor(x + 0.5)
