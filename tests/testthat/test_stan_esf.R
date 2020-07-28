
iter=30
refresh=0
source("helpers.R")

##devtools::load_all("~/dev/geostan")

context("stan_esf")
test_that("Poisson offset model works", {
    data(sentencing)
    n <- nrow(sentencing)
    C <- shape2mat(sentencing)
    ME <- list(offset = rep(10, n))
    SW(fit <- stan_esf(sents ~ offset(expected_sents),
                    data = sentencing,
                    ME = ME,
                    C = C,
                    chains = 1,
                    family = poisson(),
                    iter = iter,
                    refresh = refresh))
    expect_geostan(fit)
})

test_that("ESF works with covariate ME", {
    data(ohio)
    C <- shape2mat(ohio)    
    n <- nrow(ohio)
    ME <- list(ME = data.frame(unemployment = rep(0.75, n)))
    SW(fit <- stan_glm(gop_growth ~ unemployment + historic_gop,
                       data = ohio,
                       C = C,
                       ME = ME,
                       chains = 1,
                       iter = iter,
                       refresh = refresh))
    expect_geostan(fit)
})

test_that("ESF accepts covariate ME, multiple x proportions", {
    data(ohio)
    C <- shape2mat(ohio)        
    n <- nrow(ohio)
    ME <- list(ME = data.frame(unemployment = rep(0.75, n),
                          historic_gop = rep(3, n)),
               percent = c(1, 1))
    SW(
        fit <- stan_esf(gop_growth ~ unemployment + historic_gop,
                        data = ohio,
                        C = C,
                        ME = ME,
                        chains = 1,
                        iter = iter,
                        refresh = refresh)
       )
    expect_geostan(fit)
})

test_that("ESF accepts covariate ME, mixed (non-)proportions", {
    data(ohio)
    C <- shape2mat(ohio)        
    n <- nrow(ohio)
    ME <- list(ME = data.frame(unemployment = rep(0.75, n),
                          historic_gop = rep(3, n)),
               percent = c(1, 0))
    SW(
        fit <- stan_esf(gop_growth ~ unemployment + historic_gop,
                        data = ohio,
                        C = C,
                        ME = ME,
                        chains = 1,
                        iter = iter,
                        refresh = refresh)
    )
    expect_geostan(fit)
})

test_that("ESF accepts covariate ME with WX, mixed ME-non-ME", {
    data(ohio)
    C <- shape2mat(ohio)        
    n <- nrow(ohio)
    ME <- list(ME = data.frame(unemployment = rep(0.75, n),
                               historic_gop = rep(3, n),
                               college_educated = rep(3, n)),
               percent = c(1, 0, 1))
    SW(
        fit <- stan_esf(gop_growth ~ log(population) + college_educated + unemployment + historic_gop,
                    slx = ~ college_educated + unemployment + log(population),
                    data = ohio,
                    C = C,
                    ME = ME,
                    chains = 1,
                    iter = iter,
                    refresh = refresh)
    )
    expect_geostan(fit)
})



