#' Calculate Spearman's rho
#'
#' @param x numeric vector
#' @param y numeric vector
#'
#' @return a number in [-1,1]
#' @export
#'
#' @examples
#' x <- sample(10,10)
#' y <- sin(x)
#' spearman(x,y)
spearman <- function(x,y){
  rankx <- rank(x)
  ranky <- rank(y)
  rankmean <- (length(rankx)+1)/2

  rho <- (sum((rankx - rankmean)*(ranky - rankmean)))/(sqrt(sum((rankx - rankmean)^2)*sum((ranky - rankmean)^2)))
  return(rho)
}
