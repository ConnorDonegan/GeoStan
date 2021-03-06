% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/convenience-functions.R
\name{moran_plot}
\alias{moran_plot}
\title{Moran plot}
\source{
Anselin, Luc. "Local indicators of spatial association—LISA." Geographical analysis 27, no. 2 (1995): 93-115.
}
\usage{
moran_plot(
  y,
  w,
  xlab = "y (centered)",
  ylab = "Spatial Lag",
  pch = 20,
  col = "darkred",
  size = 2,
  alpha = 1,
  lwd = 0.5
)
}
\arguments{
\item{y}{A numeric vector of length n.}

\item{w}{An n x n spatial connectivity matrix.}

\item{xlab}{Label for the x-axis.}

\item{ylab}{Label for the y-axis.}

\item{pch}{Symbol type.}

\item{col}{Symbol color.}

\item{size}{Symbol size.}

\item{alpha}{Symbol transparency.}

\item{lwd}{Width of the regression line.}
}
\value{
Returns a \code{gg} plot, a scatter plot with \code{y} on the x-axis and its spatially lagged values on the y-axis (i.e. a Moran plot).
}
\description{
Plots a set of values against their spatially lagged values and gives the Moran coefficient as a measure of spatial autocorrelation.
}
\details{
For details on the symbol parameters see the documentation for \link[ggplot2]{geom_point}.

If any observations with no neighbors are found (i.e. \code{any(rowSums(w) == 0)}) they will be dropped automatically and a message will print stating how many were dropped.
}
\examples{

library(sf)
data(ohio)
y <- ohio$unemployment
w <- shape2mat(ohio, "W")
moran_plot(y, w)

}
\seealso{
\link[geostan]{mc}, \link[geostan]{lisa}, \link[geostan]{aple}
}
