#' @title Nonparanormal product moment correlation
#' @description Calculates the nonparanormal version of the pearson correlation between a continuous and discrete variable
#' @param cont numeric vector
#' @param disc categorical vector; can be factor or integer
#'
#' @return a correlation, i.e. a value in [,1,1]
#' @export
#'
npn.pearson <- function(cont,disc){
  f.x <- f.hat(cont)
  y <- as.integer(disc)
  r <- stats::cor(f.x,y, method = "pearson")
  return(r)
}
