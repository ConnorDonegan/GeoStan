data {
  int<lower=0> n; // number of observations
  int<lower=0> dx; // number of covariates
  int y[n]; // outcome variable
  matrix[n, dx] x; // covariates
  vector[n] offset; // if no offset provided, a vector of zeros
  vector[3] alpha_prior; // other priors
  row_vector[dx] beta_prior[3];
  vector[3] alpha_tau_prior;
  vector[2] t_nu_prior;
  int<lower=0,upper=1> has_re; // varying intercepts component
  int<lower=0> n_ids;
  int<lower=0,upper=n_ids> id[n];
}

transformed data {
  vector[n] log_E = log(offset);
}

parameters {
  real intercept;
  vector[dx] beta;
  vector[n_ids] alpha_re_tilde;
  real<lower=0> alpha_tau[has_re];
}

transformed parameters {
  vector[n] f;
  f = log_E + intercept;
  if (dx) f += x * beta;
  if (has_re) {
    for (i in 1:n) {
      f[i] += alpha_tau[has_re] * alpha_re_tilde[id[i]];
    }
  }
}

model {
  intercept ~ student_t(alpha_prior[1], alpha_prior[2], alpha_prior[3]);
  if (dx) beta ~ student_t(beta_prior[1], beta_prior[2], beta_prior[3]);
  if (has_re) {
    alpha_tau[has_re] ~ student_t(alpha_tau_prior[1], alpha_tau_prior[2], alpha_tau_prior[3]);
    alpha_re_tilde ~ std_normal();    
  }
  y ~ poisson_log(f); 
 }

generated quantities {
  vector[n] yrep;
  vector[n] fitted;
  vector[n] residual;
  vector[n] log_lik;
  vector[n_ids] alpha_re;
  if (has_re) {
    for (i in 1:n_ids) {
      alpha_re[i] = alpha_tau[has_re] * alpha_re_tilde[i];
    }
  }
  for (i in 1:n) {
    fitted[i] = exp(f[i]);
    residual[i] = fitted[i] - y[i];
    yrep[i] = poisson_log_rng(f[i]);
    log_lik[i] = poisson_log_lpmf(y[i] | f[i]);
  }
}

