#' Parse a character period specification
#'
#' The period is parsed into frequency and period and returned as a named list.
#'
#' @inheritParams partition_index
#'
#' @export
#'
#' @examples
#'
#' parse_period('2 day')
#'
parse_period <- function(period) {
  UseMethod("parse_period")
}

#' @export
parse_period.default <- function(period) {
  glue_stop("Unsupported period specification. Only characters are allowed.")
}

#' @export
parse_period.character <- function(period) {

  # Cannot supply vector of periods. 1 character only
  if(length(period) != 1) {
    glue_stop("Only 1 period can be specified.")
  }

  # Split on " "
  period_split <- unlist(strsplit(period, " "))

  # Assign period_freq / period_char
  if(length(period_split) == 1) {

    period_freq <- 1
    period_char <- period_split

  } else if(length(period_split) == 2) {

    assert_freq_coerce_to_numeric(period_split[1])
    period_freq <- as.numeric(period_split[1])
    period_char <- period_split[2]

  } else {
    glue_stop("A maximum of 1 space character is allowed in the period.")
  }

  period_char <- parse_period_char(period_char)

  period_list <- list(freq = period_freq, period = period_char)

  period_list <- check_subsecond_period(period_list)

  period_list
}


#### Utils ---------------------------------------------------------------------

# Check that the RHS of period is correct
parse_period_char <- function(period) {

  if(string_length(period) == 1) {
    p <- parse_letter_period(period)
  } else {
    p <- parse_word_period(period)
  }

  p
}

# >1 letter character parsing
parse_word_period <- function(period) {

  key <- c("year", "quarter", "month", "week",
           "da",   "hour",    "min",   "sec",
           "ms",   "mil",     "us",    "mic")

  value <- c("year",     "quarter",  "month",    "week",
             "day",      "hour",     "min",      "sec",
             "millisec", "millisec", "microsec", "microsec")

  loc_vec <- pmatch(key, period)
  parsed_period <- value[!is.na(loc_vec)]

  if(length(parsed_period) == 0) {
    glue_stop("Period '{period}' specified incorrectly.")
  }

  parsed_period
}

# 1 letter parsing, case sensitive
parse_letter_period <- function(period) {
  switch (period,
          "y" = "year",     "Y" = "year",
          "q" = "quarter",  "Q" = "quarter",
          "m" = "month",     # Case sensitive
          "w" = "week",     "W" = "week",
          "d" = "day",      "D" = "day",
          "h" = "hour",     "H" = "hour",
          "M" = "min",       # Case sensitive
          "s" = "sec",      "S" = "sec",
          "l" = "millisec", "L" = "millisec",
          "u" = "microsec", "U" = "microsec",
          glue_stop("Period '{period}' specified incorrectly.")
  )
}

# Check that the freq can be coerced to numeric
assert_freq_coerce_to_numeric <- function(freq) {
  assertthat::assert_that(
    # Coercing to numeric should give a number, not NA
    suppressWarnings(!is.na(as.numeric(freq))),
    msg = "Frequency must be coercible to numeric."
  )
}

# If subsecond resolution, change to correct second representation
check_subsecond_period <- function(period_list) {

  multiplier <- switch(period_list$period,
         "millisec" = 1000,
         "microsec" = 1000000,
         0 # Default for >subsecond periods so it returns
  )

  if(!multiplier) return(period_list)

  period_list$freq   <- period_list$freq / multiplier
  period_list$period <- "sec"

  period_list
}
