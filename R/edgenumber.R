
#' @title Edgenumber
#' @description Calculates number of edges given some precision matrix. Thresholding is allowed but defaulted to 0.
#'
#' @param Precision a square matrix whose entries are equal to negative partial correlations.
#' @param cut thresholding parameter when entries are treated to be non-zero.
#'
#' @return a number corresponding to the number of edges present in the underlying graph.
edgenumber <- function(Precision=Precision, cut=0){
  sum((abs(Precision) > (0 + cut))[lower.tri((abs(Precision) > (0 + cut)))])
}
