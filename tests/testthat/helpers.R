SW <- function(expr) suppressWarnings(expr)
expect_geostan <- function(x) expect_s3_class(x, "geostan_fit")
