#' prep_me_data
#' 
#' internal function to prepare observational error model for Stan
##' @param ME user-provided list of observational error stuff
##' @param x take design matrix from x.list$x
##' 
##' @return Partial data list to pass to Stan. 
##' @noRd
prep_me_data <- function(ME, x) { # for x pass in x.list$x
   # some defaults
  x.df <- as.data.frame(x)
  n <- nrow(x.df)  
  a.zero <- array(0, dim = 1)
  vec.zero <- array(0, dim = c(0, n))
  dx_me_unbounded <- 0
  dx_me_bounded <- 0
  x_me_bounded_idx = a.zero
  x_me_unbounded_idx = a.zero
  bounds <- c(0, 100)
  empty_car_parts <- list(
      M_diag = rep(1, n),
      nC = 1,
      dim_C = 1,
      nImC = 1,
      C = array(1, dim = c(1, 1)),          
      ImC = a.zero,
      ImC_v = a.zero,
      ImC_u = rep(0, n+1),
      Cidx = a.zero
  )
    if (is.null(ME)) { # return items in data list ready for Stan: no ME model at all. 
      x_obs <- x
      dx_obs <- ncol(x_obs)
      if (dx_obs) {
          x_obs_idx <- as.array(1:dx_obs, dim = dx_obs)
      } else {
          x_obs_idx <- a.zero
      }
      me.list <- list(
          dx_obs = dx_obs,
          dx_me_unbounded = dx_me_unbounded,
          dx_me_bounded = dx_me_bounded,
          x_obs_idx = x_obs_idx,
          x_me_bounded_idx = x_me_bounded_idx,
          x_me_unbounded_idx = x_me_unbounded_idx,
          bounds = bounds,          
          x_obs = x_obs,
          x_me_bounded = vec.zero,
          x_me_unbounded = vec.zero,
          sigma_me_bounded = vec.zero,
          sigma_me_unbounded = vec.zero,
          offset_me = rep(0, times = n),
          model_offset = 0,
          spatial_me = FALSE
      )
      me.list <- c(me.list, empty_car_parts)
      return(me.list)
  }
    if (!inherits(ME, "list")) stop("ME must be a list .")
    if (!is.null(ME$spatial)) {
        if (length(ME$spatial) != 1 | !ME$spatial %in% c(0, 1, TRUE, FALSE)) stop("ME$spatial must be logical (0, 1, TRUE, or FALSE) and of length 1.")
        spatial_me = ME$spatial
    } else {
        spatial_me <- FALSE
    }
#### observational error in offset terms: remove because it samples extremely poorly.
  ## if (length(ME$offset)) { # ME model for offset; holding for future implementation. Ignored.
  ##       offset_me <- ME$offset
  ##       model_offset <- 1
  ##     } else {
  ##         offset_me <- rep(0, times = n)
  ##         model_offset <- 0
  ##     }
      # start building the return data list
    ## me.list <- list(
    ##     offset_me = offset_me,
    ##     model_offset = model_offset,
    ##     spatial_me = spatial_me
    ## )
 ##  if (is.null(ME$se)) {
 ##      # in this case there is no ME.X
 ##      x_obs <- x
 ##      dx_obs <- ncol(x_obs)
 ##          if (dx_obs) {
 ##              x_obs_idx <- as.array(1:dx_obs, dim = dx_obs)
 ##          } else {
 ##              x_obs_idx <- a.zero
 ##          }
 ##      me.x.list <- list(
 ##          dx_obs = dx_obs,
 ##          dx_me_unbounded = dx_me_unbounded,
 ##          dx_me_bounded = dx_me_bounded,
 ##          x_obs_idx = x_obs_idx,
 ##          x_me_bounded_idx = x_me_bounded_idx,
 ##          x_me_unbounded_idx = x_me_unbounded_idx,
 ##          bounds = bounds,          
 ##          x_obs = x_obs,
 ##          x_me_bounded = vec.zero,
 ##          x_me_unbounded = vec.zero,
 ##          sigma_me_bounded = vec.zero,
 ##          sigma_me_unbounded = vec.zero
 ##      )
 ##          me.list <- c(me.list, me.x.list)
 ## } else {
    if (!inherits(ME$se, "data.frame")) stop("ME$se must be a list in which the element named ME is of class data.frame, containing standard errors for the observations.")
    if  (!all(names(ME$se) %in% names(x.df))) stop("All column names in ME$se must be found in the model matrix (from model.matrix(formula, data)). This error may occur if you've included some kind of data transformation in your model formula, such as a logarithm or polynomial, which is not supported for variables with sampling/measurement error.")
    if (length(ME$bounded)) {
        if (length(ME$bounded) != ncol(ME$se)) stop("ME$bounded mis-specified: bounded must be a vector with one element per column in the ME dataframe.")
        bounded <- which(ME$bounded == 1)
        not.bounded <- which(ME$bounded == 0)
        if (length(ME$bounds)) {
            if(length(ME$bounds) != 2 | !inherits(ME$bounds, "numeric")) stop("ME$bounds must be numeric vector of length 2.")
            bounds <- ME$bounds
        }
    } else {
        bounded <- integer(0) #rep(0, times = ncol(ME$se))
        not.bounded <- 1:ncol(ME$se) #rep(1, times = ncol(ME$se))
    }           
                                        # gather any/all variables without ME
    x_obs_idx <- as.array( which( !names(x.df) %in% names(ME$se) )) 
    x_obs <- as.data.frame(x.df[, x_obs_idx])
    dx_obs <- ncol(x_obs)
                                        # now X.me needs to be parsed into bounded/non-bounded variables and ordered as x
    nm_me_unbounded <- names(ME$se)[not.bounded]
    x_me_unbounded <- data.frame( x.df[, nm_me_unbounded] )
    names(x_me_unbounded) <- nm_me_unbounded
    x_me_unbounded_order <- na.omit( match(names(x.df), names(x_me_unbounded)) )
    x_me_unbounded <- as.matrix(x_me_unbounded[, x_me_unbounded_order], nrow = n)
    dx_me_unbounded <- ncol(x_me_unbounded)
    sigma_me_unbounded <- as.matrix(ME$se[,not.bounded], nrow = n)
    sigma_me_unbounded <- as.matrix(sigma_me_unbounded[, x_me_unbounded_order], nrow = n)
    x_me_unbounded_idx <- as.array( which( names(x.df) %in% nm_me_unbounded ))
          
    nm_me_bounded <- names(ME$se)[bounded]
    x_me_bounded <- data.frame( x.df[, nm_me_bounded] )
    names(x_me_bounded) <- nm_me_bounded
    x_me_bounded_order <- na.omit( match(names(x.df), names(x_me_bounded)) )
    x_me_bounded <- as.matrix(x_me_bounded[, x_me_bounded_order], nrow = n)
    dx_me_bounded <- ncol(x_me_bounded)
    sigma_me_bounded <- as.matrix(ME$se[,bounded], nrow = n)
    sigma_me_bounded <- as.matrix(sigma_me_bounded[, x_me_bounded_order], nrow = n)
    x_me_bounded_idx <- as.array( which( names(x.df) %in% nm_me_bounded ))
 
    if (any(x_me_bounded < bounds[1]) | any(x_me_bounded > bounds[2])) stop("In ME: bounded variable has elements outside of user-provided bounds (", bounds[1], ", ", bounds[2], ")")
          # handle unused parts
    if (!dx_obs) {
        x_obs <- model.matrix(~ 0, x.df) 
        x_obs_idx <- a.zero
    }
    if (!dx_me_bounded) {
        sigma_me_bounded <- x_me_bounded <- vec.zero 
        x_me_bounded_idx <- a.zero
    }
    if (!dx_me_unbounded) {
        sigma_me_unbounded <- x_me_unbounded <- vec.zero
        x_me_unbounded_idx <- a.zero
    }
     # return items in data list ready for Stan: with ME model for covariates
    me.list <- list(
        dx_obs = dx_obs,
        dx_me_unbounded = dx_me_unbounded,
        dx_me_bounded = dx_me_bounded,
        x_obs_idx = x_obs_idx,
        x_me_bounded_idx = x_me_bounded_idx,
        x_me_unbounded_idx = x_me_unbounded_idx,
        bounds = bounds,
        x_obs = x_obs, 
        x_me_bounded = array(t(x_me_bounded), dim = c(dx_me_bounded, n)),
        x_me_unbounded = array(t(x_me_unbounded), dim = c(dx_me_unbounded, n)),
        sigma_me_bounded = array(t(sigma_me_bounded), dim = c(dx_me_bounded, n)),
        sigma_me_unbounded = array(t(sigma_me_unbounded), dim = c(dx_me_unbounded, n)),
        spatial_me = spatial_me
    )
    if (spatial_me) {
       if(!inherits(ME$car_parts, "list")) stop("If ME$spatial = TRUE, you must provide car_parts---a list of data for the CAR model. See ?prep_car_data.")
        if(!all(c("nC", "nImC", "ImC", "ImC_v", "ImC_u", "Cidx", "M_diag", "C") %in% names(ME$car_parts))) stop("car_parts is missing at least one required part. See ?prep_car_data. Did you use cmat = TRUE?")
        me.list <- c(me.list, ME$car_parts)
    } else {
        me.list <- c(me.list, empty_car_parts)
    }       
    return(me.list)
}


