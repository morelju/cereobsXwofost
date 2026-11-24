# Isolating the usable part of one Cereobs curve.
#
# A curve is the weekly series of "% of fields having reached stage s" for one
# crop x region x campaign. Raw series can contain:
#   - leftover values of the previous campaign before the reset to 0,
#   - weeks where the value was not updated (same value repeated),
#   - small decreases (reporting noise),
#   - curves that never reach 100 % (campaign cut, missing weeks).
#
# clean_curve() keeps the segment from the last 0 before the rise up to the first
# time the curve reaches its maximum, and optionally drops stale repeats.

#' @param date Date vector (one record per week)
#' @param value numeric, % of fields at stage
#' @param min_max_value curves whose maximum stays below this are "incomplete"
#' @param drop_stale_repeats drop interior values (0 < v < 100) equal to the
#'   previous kept value, i.e. weeks without update
#' @return list(points = tibble(date, value), status = character, flags = list)
clean_curve <- function(date, value, min_max_value = 80, drop_stale_repeats = TRUE) {
  o <- order(date)
  date <- date[o]
  value <- value[o]
  ok <- !is.na(value)
  date <- date[ok]
  value <- value[ok]

  empty <- list(points = tibble::tibble(date = as.Date(character()), value = numeric()),
                flags = list(starts_above_zero = NA, n_decreases = NA_integer_,
                             n_stale_dropped = NA_integer_))
  if (length(value) < 2) return(c(empty, status = "empty"))

  zeros <- which(value == 0)
  if (length(zeros) == 0) {
    # recording started after the stage had begun
    first0 <- 1L
    starts_above_zero <- TRUE
  } else {
    first0 <- zeros[1]
    starts_above_zero <- FALSE
  }

  after <- value[first0:length(value)]
  mx <- max(after)
  if (mx < min_max_value) return(c(empty, status = "incomplete"))

  end <- first0 - 1L + which(after == mx)[1]
  start <- if (starts_above_zero) 1L else max(zeros[zeros <= end])
  seg_date <- date[start:end]
  seg_value <- value[start:end]
  if (length(seg_value) < 2) return(c(empty, status = "too_short"))

  n_stale <- 0L
  if (drop_stale_repeats && length(seg_value) > 2) {
    keep <- rep(TRUE, length(seg_value))
    last_kept <- seg_value[1]
    for (i in 2:length(seg_value)) {
      v <- seg_value[i]
      if (v > 0 && v < 100 && v == last_kept && i != length(seg_value)) {
        keep[i] <- FALSE
      } else {
        last_kept <- v
      }
    }
    n_stale <- sum(!keep)
    seg_date <- seg_date[keep]
    seg_value <- seg_value[keep]
  }

  list(
    points = tibble::tibble(date = seg_date, value = seg_value),
    status = if (starts_above_zero) "starts_above_zero" else "ok",
    flags = list(
      starts_above_zero = starts_above_zero,
      n_decreases = sum(diff(seg_value) < 0),
      n_stale_dropped = n_stale
    )
  )
}
