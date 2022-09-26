#' @title Precision Matrix Selection
#' @description For a given glasso path (in the form of a `huge` object) the
#' function recalculates the unpenalized likelihood via the `glasso()` function
#' and selects the model, i.e. the graph, with the smallest eBIC
#' \deqn{    eBIC_\theta = -2 \ell^{(n)}(\hat{\Omega}(E)) + \Abs{E} \log(n) + 4 \Abs{E}\theta \log(d)}
#'(see Foygel & Drton (2010)).
#' By default `partial = TRUE` which converts the entries in the resulting precision
#' matrix to partial correlations.
#'
#' @param x glasso path contained in a `huge` object
#' @param param \eqn{\theta} parameter for additional high-dimensional penalty
#' @param n sample size for likelihood recalculation
#' @param s sample covariance or correlation matrix that was used to estimate the glasso path
#' @param partial if set to `TRUE` the resulting precision matrix entries are negated so as to get partial correlations
#'
#' @return a symmetrix matrix of the same dimension as `s`
#' @export
#' @references
#' Foygel, Rina and Drton, Mathias. (2010).
#' Extended Bayesian Information Criteria for Gaussian Graphical Models.
#' In: Lafferty, J., Williams, C., Shawe-Taylor, J., Zemel, R. andCulotta,  A.  (editors),
#' Advances  in  Neural  Information  Processing  Systems,  Volume  23.Curran Associates, Inc. pp. 604–612.
omega.select <- function(x=x, param = param, n=n, s = s, partial = T){
  if (!requireNamespace("stats", quietly = TRUE)) {
    stop(
      "Package \"stats\" must be installed to use this function.",
      call. = FALSE
    )
  }
    if (!requireNamespace("glasso", quietly = TRUE)) {
      stop(
        "Package \"glasso\" must be installed to use this function.",
        call. = FALSE
    )
  }
  stopifnot((class(x)=="huge"))
  d=dim(x$data)[1]
  nlambda <- length(x$lambda)
  eBIC <- rep(0,nlambda)
  for (ind in 1:nlambda) {
    huge_path <- x$path[[ind]]
    edge <- edgenumber(huge_path)
    huge_path[upper.tri(huge_path, diag = T)] <- 1
    zero_mat <- which(huge_path == 0, arr.ind = T)
    loglik <- suppressWarnings(glasso::glasso(s = s, rho = 0, nobs = n, zero = zero_mat)$loglik)
    eBIC[ind] <- -2*loglik + edge*log(n) + 4*edge*param*log(d)
  }

  Omega_hat <- x$icov[[which.min(eBIC)]]
  if (partial == T){
    Omega_hat.standardized <- -1*stats::cov2cor(Omega_hat)
    diag(Omega_hat.standardized) <- -1*diag(Omega_hat.standardized)
  } else {
    Omega_hat.standardized <- stats::cov2cor(Omega_hat)
  }
  return(Omega_hat.standardized)
}
