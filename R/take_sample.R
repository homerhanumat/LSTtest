#' Samples from various kinds of objects
#'
#' A set of methods to generate random samples from data frames and data simulations.
#' For data frames, individual rows are sampled. For vectors, elements are sampled.
#'
#' @details These are based in spirit on the sample functions in the `{mosaic}` package,
#' but are redefined here to 1) avoid a dependency on `{mosaic}` and 2) bring the arguments in
#' line with the `.by =` features of `{dplyr}`.
#'
#' @param x The object from which to sample
#' @param n Size of the sample.
#' @param \ldots Arguments to pass along to specific sample methods.
#' @param replace Logical flag: whether to sample with replacement. (default: `FALSE`)
#'
#' @examples
#' take_sample(sim_03, n=5) # run a simulation
#' take_sample(Clock_auction, n = 3) # from a data frame
#' take_sample(1:6, n = 6) # sample from a vector
#'
#' @returns A vector or a data frame depending on the nature of the `x` argument.
#' @export
take_sample <- function (x, n, replace = FALSE, ...) {
  UseMethod('take_sample')
}


#' @export
take_sample.vector <- function(x, n=length(x), replace=FALSE, ...) {
  base::sample(x, size = n, replace = replace, ...)
}

#' @export
take_sample.data.frame <- function(x, n = nrow(x), replace = FALSE, ..., .by = NULL) {

  # slice_sample uses `by` instead of `.by`
  # I can get this to work only by turning `.by` into a character string
  # containing the desired names.
  groups <- substitute(.by) # `groups` will be a call

  if (!is.null(groups)) {
    # handle cases with multiple .by variables
    if (is.call(groups)) {
      if (!is.name(groups[[2]])) groups <- eval(groups)
      else groups <- all.vars(groups)
    }
  }

  dplyr::slice_sample(x, n = n, by = all_of(groups), replace = replace)
}

#' @export
take_sample.datasim <- function(x, n = 5, replace = FALSE, ..., seed = NULL, report_hidden=FALSE) {
   datasim_run(x, n = n, seed = seed, report_hidden = report_hidden)
}

#' @param .by Variables to use to define groups for sampling, as in `{dplyr}`. The sample size
#' applies to each group.
#' @param groups Variable indicating blocks to sample within
#' @param orig.ids Logical. If `TRUE`, append a column named "orig.ids" with the
#' row from the original `x` that the same came from.
#' @param prob Probabilities to use for sampling, one for each element of `x`
#'
#' @rdname take_sample
#' @export
take_sample.default <- function(x, n = length(x), replace=FALSE, prob=NULL, .by = NULL,
                           groups = .by, orig.ids=FALSE, ...) {
  size <- n
  missingSize <- missing(size)
  haveGroups <- ! is.null(groups)
  if (length(x) == 1L && is.numeric(x) && x >= 1) {
    n <- x
    x <- 1:n
    if (missingSize)  size <- n
  } else {
    n <- length(x)
    if (missingSize) size <- length(x)
  }
  if (haveGroups && size != n) {
    warning("'size' is ignored when using groups.")
    size <- n
  }
  ids <- 1:n

  if (haveGroups) {
    groups <- rep( groups, length.out = size)  # recycle as needed
    result <- stats::aggregate( ids, by = list(groups), FUN = base::sample,
                         simplify = FALSE,
                         replace = replace, prob = prob)
    result <- unlist(result$x)
    if (orig.ids) { nms <- ids[result] }
    result <- x[result]
    if (orig.ids) { names(result) <- nms }
    return(result)
  }
  result <- base::sample(x, size, replace = replace, prob = prob)
  return(result)
}

#' A convenience function for sampling with replacement
#' @rdname take_sample
#' @export
resample <- function(..., replace = TRUE) {
  take_sample(..., replace = replace)
}

#' A convenience function for shuffling, typically used with
#' within model_train(), but available elsewhere for, e.g. demonstrations
#' @rdname take_sample
#' @export
shuffle <- function(...) {
  take_sample(...)
}
