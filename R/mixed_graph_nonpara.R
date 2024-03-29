#' @title Mixed Graph Estimation under Nonparanormal assumption
#' @description Estimates precision matrix and adjacency matrix, i.e. the undirected graph,
#' given a (potentially high dimensional) data set that contains discrete and continuous variables.
#' If nominal variables are present, they should be transformed to a dummy system.
#'
#' @param data A data set of dimension \eqn{n \times d}
#' @param verbose Prints some useful information, defaults to `TRUE`
#' @param nlam Length of the glasso path. Default is 50
#' @param param Value to which the additional dimensionality penalty in the eBIC should be set. Default is .1
#' @param names Can be either boolean of a character vector of length \eqn{d}. Default is `FALSE`

#'
#' @return A list with the following elements is returned:
#' \itemize{
#'   \item Estimated Precision Matrix - The estimated precision matrix. If `partial = TRUE` the entries correspond to partial correlations.
#'   \item Adjacency Matrix - The corresponding adjacency matrix that encodes the undirected graph.
#'   \item Sample Correlation Matrix - The sample correlation matrix plugged into the glasso routine.
#'   \item Edgenumber - The number of edges in the graph
#'   \item Max Degree - The largest number of connections across all nodes in the graph.
#'   \item initial_mat_singular - Boolean whether correlation matrix was singular and had to be transformed to the pd-cone.
#' }
#' @export
#' @examples
#' require(huge)
#' latent.data = huge::huge.generator(n = 50, d = 60, graph = "hub", g = 4)$data
#' data <- latent.data
#' binarize <- ncol(latent.data)/2
#' pbin <- stats::runif(floor(binarize),.4,.6)
#' for(i in 1:binarize){
#'    data[,i] <- stats::qbinom(stats::pnorm(scale(latent.data[,i])),size=1,prob = pbin[i])
#' }
#' mixed.graph <- mixed.graph.nonpara(data)
#' latent.graph <- mixed.graph.nonpara(latent.data)
#' all.equal(mixed.graph$`Adjacency Matrix`, latent.graph$`Adjacency Matrix`)
#'

mixed.graph.nonpara <- function(data = data, verbose = T, nlam = 50, param = .1, names = F){
  if (sum(sapply(data, is.factor)) == 0 & verbose == T){
    cat("Warning, there are no factors in the input data.
        I'm checking your input and declare factors for level(x)<20")
  }
  d <- ncol(data)
  n <- nrow(data)

  data <- as.data.frame(data)
  factor_ids <- sapply(data, function(id) length(unique(id)) < 20)
  data[,factor_ids] <- lapply(data[,factor_ids], factor)

  rho <- matrix(1,d,d)

  if (!requireNamespace("polycor", quietly=TRUE))
    stop("Please install package \"polycor\".")

  for(i in 1:(d-1)) {
    for(j in (i+1):d){
      if (is.numeric(data[,i]) & is.numeric(data[,j])){
        rho[i,j] <- rho[j,i] <- 2*sin(pi/6 *spearman(data[,i], data[,j]))
      }
      if ((is.factor(data[,i]) & is.numeric(data[,j])) |  (is.numeric(data[,i]) & is.factor(data[,j]))) {
        rho[i,j] <- rho[j,i] <- adhoc_polyserial(data[,i], data[,j])
      }
      if (is.factor(data[,i]) & is.factor(data[,j])) {
        rho[i,j] <- rho[j,i] <- polycor::polychor(data[,i], data[,j])
      }
    }
  }

  if (!requireNamespace("stringr", quietly=TRUE))
    stop("Please install package \"stringr\".")
  pair <- rho[lower.tri(rho)]
  if (any(abs(pair) > .9))
    sapply(seq_along(rho[lower.tri(rho)][which(abs(pair) > .95)]), function (k) warning(paste0('Correlation of the pair ',
                                                                                               stringr::str_c(as.character(which(rho[lower.tri(rho)][which(abs(pair) > .9)][k] == rho,
                                                                                                                        arr.ind = T)[,1]), collapse = ",")),
                                                                                        ' is close to boundary. Inverse might be misleading. '))

  if (!requireNamespace("corpcor", quietly=TRUE))
    stop("Please install package \"corpcor\".")
  if (!requireNamespace("Matrix", quietly=TRUE))
    stop("Please install package \"Matrix\".")

  ### eigenvalue decomposition and truncate eigenvalues at 0

  if (!corpcor::is.positive.definite(rho)) {
    initial_mat_singular <- T
    rho_pd <- as.matrix(Matrix::nearPD(rho, corr = T, keepDiag = T)$mat)
  } else {
    initial_mat_singular <- F
    rho_pd <- rho
  }
  #diag(rho_pd) <- 1


  if (!requireNamespace("huge", quietly=TRUE))
    stop("Please install package \"huge\".")

  #now with rho_pd we have the sample correlation matrix
  huge.result <- huge::huge(rho_pd,nlambda=nlam,method="glasso",verbose=FALSE)
  if (!requireNamespace("glasso", quietly=TRUE))
      stop("Please install package \"glasso\".")
  Omega_hat <- hume::omega.select(x=huge.result, n=n, s = rho_pd, param = param, partial = T)
  number_edges <- edgenumber(Omega_hat)
  max_degree <- max(sapply(1:d, function(k) (sum(abs(Omega_hat[k,]) > 0) -1)))

  adj_estimate <- abs(Omega_hat) > 0

  if (!missing(names) & !is.logical(names)){
    if (length(names) != d)
      stop("Name vector has to be the same length as number of columns in data matrix")
    colnames(Omega_hat) <- rownames(Omega_hat) <- colnames(adj_estimate) <- rownames(adj_estimate)  <- colnames(rho_pd) <- rownames(rho_pd) <- names
  } else if (!missing(names) & is.logical(names) & names == T){
    colnames(Omega_hat) <- rownames(Omega_hat) <- colnames(adj_estimate) <- rownames(adj_estimate)  <- colnames(rho_pd) <- rownames(rho_pd) <- names(data)
  }

  output <- list("Estimated Precision Matrix" = Omega_hat, "Adjacency Matrix" = adj_estimate,
                 "Sample Correlation Matrix" = rho_pd, "Edgenumber" = number_edges, "Max Degree" = max_degree, "initial_mat_singular" = initial_mat_singular)
  return(output)
}

