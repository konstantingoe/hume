
#' @title Adhoc polyserial estimator
#' @description Returns the nonparanormal correlation estimate of a couple of randomvariables
#' where one is ordinal and the other one is continuous
#' @param x a discrete or continuous vector
#' @param y a discrete or continuous vector
#' @param maxcor maximal allowed correlation so as to make sure that we stay away from the boundary
#' @param more_verbose prints some extra information
#'
#' @return a value between [-1,1]
#' @export
#'
adhoc_polyserial <- function(x, y, maxcor = 0.9999, more_verbose = F){
  x <- if (missing(y)){
    x
  } else {cbind(x, y)}

  x <- as.data.frame(x)

  if (any(is.factor(x) == F)){
    if (more_verbose == T) cat("No factor variable specified. I'm taking the one that has fewer than 20 unique values!")
    factor_id <- sapply(x, function(id) length(unique(id)) < 20)
  } else {
    factor_id <- sapply(x, is.factor)
  }

  ### if both categorical perform polychoric correlation

  if (sum(factor_id) == 2){
    corr.hat <- polycor::polychor(x[,1], x[,2])
  } else if (sum(factor_id) == 0) {
    corr.hat <- 2*sin(pi/6 *spearman(x[,1], x[,2]))
  } else {
    ### retrieve numeric and discrete variable
    numeric_var <- x[,factor_id == F]
    factor_var <- as.numeric(x[,factor_id == T])

    n <- length(factor_var)
    cummarg_propotions <- c(0,cumsum(table(factor_var)/n))
    threshold_estimate <- stats::qnorm(cummarg_propotions)

    values <- sort(as.integer(unique(factor_var)))

    lambda <- sum(stats::dnorm(utils::head(threshold_estimate, -1)[-1]*diff(values)))
    s_disc <- stats::sd(factor_var)
    r <- npn.pearson(numeric_var,factor_var)
    corr.hat <- r*s_disc/lambda

    if (abs(corr.hat) >= 1){
      corr.hat <- sign(corr.hat)*maxcor
    }
    if (is.null(corr.hat)){corr.hat <- polycor::polyserial(numeric_var, factor_var)}
  }
  return(corr.hat)
}
