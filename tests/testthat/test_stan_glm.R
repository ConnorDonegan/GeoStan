
iter=30
refresh=0
source("helpers.R")

context("stan_glm")
test_that("Poisson offset model works", {
    data(sentencing)
    n <- nrow(sentencing)
    ME <- list(offset = rep(10, n))
    SW(fit <- stan_glm(sents ~ offset(expected_sents),
                    data = sentencing,
                    ME = ME,
                    chains = 1,
                    family = poisson(),
                    iter = iter,
                    refresh = refresh))
    expect_geostan(fit)
})

test_that("GLM works with covariate ME", {
    data(ohio)
    n <- nrow(ohio)
    ME <- list(ME = data.frame(unemployment = rep(0.75, n)))
    SW(fit <- stan_glm(gop_growth ~ unemployment + historic_gop,
                    data = ohio,
                    ME = ME,
                    chains = 1,
                    iter = iter,
                    refresh = refresh))
    expect_geostan(fit)
})

test_that("GLM accepts covariate ME, multiple x proportions", {
    data(ohio)
    n <- nrow(ohio)
    ME <- list(ME = data.frame(unemployment = rep(0.75, n),
                          historic_gop = rep(3, n)),
               percent = c(1, 1))
    SW(
        fit <- stan_glm(gop_growth ~ unemployment + historic_gop,
                    data = ohio,
                    ME = ME,
                    chains = 1,
                    iter = iter,
                    refresh = refresh)
       )
    expect_geostan(fit)
})

test_that("GLM accepts covariate ME, mixed (non-)proportions", {
    data(ohio)
    n <- nrow(ohio)
    ME <- list(ME = data.frame(unemployment = rep(0.75, n),
                          historic_gop = rep(3, n)),
               percent = c(1, 0))
    SW(
        fit <- stan_glm(gop_growth ~ unemployment + historic_gop,
                    data = ohio,
                    ME = ME,
                    chains = 1,
                    iter = iter,
                    refresh = refresh)
    )
    expect_geostan(fit)
})

test_that("GLM accepts covariate ME with WX, mixed ME-non-ME", {
    data(ohio)
    n <- nrow(ohio)
    ME <- list(ME = data.frame(unemployment = rep(0.75, n),
                          historic_gop = rep(3, n)),
               percent = c(1, 0))
    SW(
        fit <- stan_glm(gop_growth ~ log(population) + college_educated + unemployment + historic_gop,
                    slx = ~ college_educated + unemployment,
                    data = ohio,
                    C = shape2mat(ohio),
                    ME = ME,
                    chains = 1,
                    iter = iter,
                    refresh = refresh)
    )
    expect_geostan(fit)
})

test_that("Binomial GLM accepts covariate ME with WX, mixed ME-non-ME", {
    data(ohio)
    n <- nrow(ohio)
    ME <- list(ME = data.frame(unemployment = rep(0.75, n),
                          historic_gop = rep(3, n)),
               percent = c(1, 1))
    SW(
        fit <- stan_glm(cbind(trump_2016, total_2016 - trump_2016) ~ log(population) + college_educated + unemployment + historic_gop,
                    slx = ~ college_educated + unemployment,
                    data = ohio,
                    C = shape2mat(ohio),
                    ME = ME,
                    chains = 1,
                    family = binomial(),
                    iter = iter,
                    refresh = refresh)
    )
    expect_geostan(fit)
})



