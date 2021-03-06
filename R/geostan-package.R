#' The geostan R package.
#'
#' @description Bayesian spatial modeling powered by Stan. \code{geostan} offers access to a variety of hierarchical spatial models using the R formula interface. It is designed primarily for spatial epidemiology and public health research but is generally applicable to modeling areal data.
#'
#' @docType package
#' @name geostan-package
#' @aliases geostan
#' @useDynLib geostan, .registration = TRUE
#' @import methods
#' @import Rcpp
#' @importFrom rstan sampling 
#'
#' @references
#'
#' Carpenter, B., Gelman, A., Hoffman, M.D., Lee, D., Goodrich, B., Betancourt, M., Brubaker, M., Guo, J., Li, P., Riddell, A., 2017. Stan: A probabilistic programming language. Journal of statistical software 76.
#'
#' Donegan, C., Y. Chun and A. E. Hughes (2020). Bayesian Estimation of Spatial Filters with Moran’s Eigenvectors and Hierarchical Shrinkage Priors. Spatial Statistics. \url{https://doi.org/10.1016/j.spasta.2020.100450}
#'
#' Gabry, J., Goodrich, B. and Lysy, M. (2020). rstantools: Tools for developers of R packages interfacing with Stan. R package version 2.1.1 \url{https://mc-stan.org/rstantools}
#' 
#' Joseph, Max (2016). Exact Sparse CAR Models in Stan. Stan Case Studies, Vol. 3. \url{https://mc-stan.org/users/documentation/case-studies/mbjoseph-CARStan.html}
#' 
#' Morris, M., Wheeler-Martin, K., Simpson, D., Mooney, S. J., Gelman, A., & DiMaggio, C. (2019). Bayesian hierarchical spatial models: Implementing the Besag York Mollié model in stan. Spatial and spatio-temporal epidemiology, 31, 100301.
#' 
#' Stan Development Team (2019). RStan: the R interface to Stan. R package version 2.19.2. \url{https://mc-stan.org}
#'
NULL
