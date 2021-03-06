% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/convenience-functions.R
\name{waic}
\alias{waic}
\title{WAIC}
\usage{
waic(fit, pointwise = FALSE, digits = 2)
}
\arguments{
\item{fit}{An \code{geostan_fit} object or any Stan model with a parameter named "log_lik", the pointwise log predictive likelihood}

\item{pointwise}{Logical, should a vector of values for each observation be returned?}

\item{digits}{Round results to this many digits.}
}
\value{
A vector of length 3 with \code{WAIC}, a rough measure of the effective number of parameters estimated by the model \code{Eff_pars}, and log predictive density \code{Lpd}. If \code{pointwise = TRUE}, results are returned in a \code{data.frame}.
}
\description{
Widely Application Information Criteria (WAIC) for model evaluation
}
\examples{

\dontrun{
data(ohio)
fit <- stan_glm(gop_growth ~ 1, data = ohio, chains = 3, iter = 1500)
waic(fit)
}
}
\seealso{
See \link[loo]{waic} as well as the more robust \link[loo]{loo}
}
