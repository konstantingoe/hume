#' @title Estimate monotone transformation functions
#' @description Implements the Winsorized estimator in Liu, Lafferty, Wasserman (2009),
#' @param x a numeric vector
#'
#' @return a numeric vector of same length as input
#' @export
#' @references Liu, Han, Lafferty, John and Wasserman, Larry. (2009). The nonparanormal: Semi-parametric estimation of high dimensional undirected graphs.Journal of Machine Learn-ing Research10(80), 2295–2328.

f.hat <- function(x){
  n <- length(x)
  npn.thresh <- 1/(4 * (n^0.25) * sqrt(pi * log(n)))
  x <- stats::qnorm(pmin(pmax(rank(x)/n, npn.thresh),
                  1 - npn.thresh))
  x <- x/stats::sd(x)
  return(x)
}
