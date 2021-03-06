/**
  * Gather terms for the regularized horseshoe model (Piironen and Vehtari)
  *
  * @return A vector of coefficientes
  **/
  vector rhs_prior(int dev,
		   vector z,
		   real aux1_global,
		   real aux2_global,
		   vector aux1_local,
		   vector aux2_local,
		   real caux,
		   real scale_global,
		   real slab_scale,
		   real error_scale) {
  real tau = aux1_global * sqrt(aux2_global) * scale_global * error_scale;
  real c = slab_scale * sqrt(caux);
  vector[dev] lambda = aux1_local .* sqrt(aux2_local);
  vector[dev] lambda_tilde = sqrt( c^2 * square(lambda) ./ (c^2 + square(tau) * square(lambda)) );
  return z .* lambda_tilde * tau;
}

/**
 * Log probability of the conditional autoregressive (CAR) model,
 * excluding additive constants.
 *
 * @param y Process to model
 * @param mu Mean vector
 * @param tau Scale parameter
 * @param rho Spatial dependence parameter
 * @param ImC Sparse representation of (I - C): non-zero values only
 * @param v Column indices for values in ImC
 * @param u Row starting indices for values in ImC
 * @param Cidx Indices for the off-diagonal elements in ImC
 * @param M_inv Diagonal elements from the inverse of the conditional  variances (M^-1)
 * @param lambda Eigenvalues of M^{-1/2}*C*M^{1/2}
 * @param n Length of y
 *
 * @return Log probability density of CAR prior up to additive constant
*/
real car_normal_lpdf(vector y, vector mu,
		     real tau, real rho,
		     vector ImC, int[] v, int[] u, int[] Cidx,
		     vector M_inv, vector lambda,
		     int n) {
  vector[n] z = y - mu;  
  vector[num_elements(ImC)] ImrhoC = ImC; // (I - C)
  vector[n] zMinv = z .* M_inv;           // z' * M^-1
  vector[n] ImrhoCz;                      // (I - rho * C) * z
  vector[n] ldet_prec;
  ImrhoC[Cidx] = rho * ImC[Cidx];        // (I - rho C) 
  ImrhoCz = csr_matrix_times_vector(n, n, ImrhoC, v, u, z);
  for (i in 1:n) ldet_prec[i] = log1m(rho * lambda[i]);
  return 0.5 * (
		-2 * n * log(tau)
		+ sum(ldet_prec)
		- (1 / tau^2) * dot_product(zMinv, ImrhoCz)
		);
}

/**
  * Calculate eigenvalues of M^{-1/2}*C*M^{1/2} for CAR model
  *
  * @param C n by n connectivity matrix
  * @param M_inv Inverse of conditional variances, from M in Sigma = (I - rho C)^-1 M.
  *
  * @return A n-length vector of eigenvalues
  **/
vector eMCM(matrix C, vector M_inv) {
    int n = num_elements(M_inv);
    vector[n] lambda;       
    vector[n] invsqrtM;
    vector[n] sqrtM;
    for (i in 1:n) invsqrtM[i] = sqrt(M_inv[i]);
    for (i in 1:n) sqrtM[i] = 1/sqrt(M_inv[i]);
    lambda = eigenvalues_sym(diag_matrix(invsqrtM) * C * diag_matrix(sqrtM));
    return (lambda);
}



/**
 * Log probability of the intrinsic conditional autoregressive (ICAR) prior,
 * excluding additive constants. 
 *
 * @param phi Vector of parameters for spatial smoothing (on unit scale)
 * @param spatial_scale Scale parameter for the ICAR model
 * @param node1 
 * @param node2
 * @param k number of groups
 * @param group_size number of observational units in each group
 * @param group_idx index of observations in order of their group membership
 * @param has_theta If the model contains an independent partial pooling term, phi for singletons can be zeroed out; otherwise, they require a standard normal prior. Both BYM and BYM2 have theta.
 *
 * @return Log probability density of ICAR prior up to additive constant
 **/
real icar_normal_lpdf(vector phi, real spatial_scale,
              int[] node1, int[] node2, 
              int k, int[] group_size, int[] group_idx,
              int has_theta) {
  real lp;
  int pos=1;
  lp = -0.5 * dot_self(phi[node1] - phi[node2]);
  if (has_theta) {
    for (j in 1:k) {
      /* sum to zero constraint for each connected group; singletons zero out */
      lp += normal_lpdf(sum(phi[segment(group_idx, pos, group_size[j])]) | 0, 0.001 * group_size[j]);
      pos += group_size[j];
    }
  } else {
    /* does not have theta */
    for (j in 1:k) {
      if (group_size[j] > 1) {
    /* same as above for non-singletons: sum to zero constraint */
    lp += normal_lpdf(sum(phi[segment(group_idx, pos, group_size[j])]) | 0, 0.001 * group_size[j]);
      } else {
    /* its a singleton: independent Gaussian prior on phi */
    lp += normal_lpdf(phi[ segment(group_idx, pos, group_size[j]) ] | 0, spatial_scale);
      }      
      pos += group_size[j];
    }
  }
  return lp;
}

/**
 * Create phi from phi_tilde, inv_sqrt_scale_factor, and spatial_scale. 
 *
 * @param phi_tilde local component (spatially autocorrelated) 
 * @param phi_scale scale parameter for phi
 * @param rho proportion spatial (for ICAR and BYM models, this alwasy equals 1; for BYM2, it is a model parameter)
 * @param inv_sqrt_scale_factor The scaling factor for the ICAR variance (see scale_c R function, using R-INLA); 
 *                              transformed from 1/scale^2 --> scale. Or, a vector of ones.
 * @param n number of spatial units
 * @param k number of connected groups
 * @param group_size number of observational units in each group
 * @param group_idx index of observations in order of their group membership
 *
 * @return phi vector of spatially autocorrelated coefficients
 */
vector make_phi(vector phi_tilde, real phi_scale,
		real rho,
		vector inv_sqrt_scale_factor,
		int n, int k,
		int[] group_size, int[] group_idx
              ) {
  vector[n] phi;
  int pos=1;
  for (j in 1:k) {
    phi[ segment(group_idx, pos, group_size[j]) ] = phi_scale * sqrt(rho) * inv_sqrt_scale_factor[j] * phi_tilde[ segment(group_idx, pos, group_size[j]) ];
    pos += group_size[j];
  }
  return phi;
}


/**
 * Combine local and global partial-pooling components into the convolved BYM term.
 *
 * @param phi spatially autocorrelated component (not phi_tilde!)
 * @param theta global component (not theta_tilde!)
 * @param n number of spatial units
 * @param k number of connected groups
 * @param group_size number of observational units in each group
 * @param group_idx index of observations in order of their group membership
 *
 * @return BYM convolution vector
 */
vector convolve_bym(vector phi, vector theta,
              int n, int k,
              int[] group_size, int[] group_idx
              ) {
  vector[n] convolution;
  int pos=1;
  for (j in 1:k) {
     if (group_size[j] == 1) {
        convolution[ segment(group_idx, pos, group_size[j]) ] = theta[ segment(group_idx, pos, group_size[j]) ];
    } else {
    convolution[ segment(group_idx, pos, group_size[j]) ] =
      phi[ segment(group_idx, pos, group_size[j]) ] + theta[ segment(group_idx, pos, group_size[j]) ];
  }
      pos += group_size[j];
  }
  return convolution;
}

/**
 * Combine local and global partial-pooling components into the convolved BYM2 term.
 *
 * @param phi_tilde local (spatially autocorrelated) component
 * @param theta_tilde global component
 * @param spatial_scale scale parameter for the convolution term
 * @param n number of spatial units
 * @param k number of connected groups
 * @param group_size number of observational units in each group
 * @param group_idx index of observations in order of their group membership
 * @param rho proportion of convolution that is spatially autocorrelated
 * @param inv_sqrt_scale_factor The scaling factor for the ICAR variance (see scale_c R function, using R-INLA); 
 *                              transformed from 1/scale^2 --> scale. Or, a vector of ones.
 *
 * @return BYM2 convolution vector
 */
vector convolve_bym2(vector phi_tilde, vector theta_tilde,
          real spatial_scale,
		      int n, int k,
		      int[] group_size, int[] group_idx,
		      real rho, vector inv_sqrt_scale_factor
		      ) {
  vector[n] convolution;
  int pos=1;
  for (j in 1:k) {
    if (group_size[j] == 1) {
        convolution[ segment(group_idx, pos, group_size[j]) ] = spatial_scale * theta_tilde[ segment(group_idx, pos, group_size[j]) ];
    } else {
    convolution[ segment(group_idx, pos, group_size[j]) ] = spatial_scale * (
     sqrt(rho) * inv_sqrt_scale_factor[j] * phi_tilde[ segment(group_idx, pos, group_size[j]) ] +
     sqrt(1 - rho) * theta_tilde[ segment(group_idx, pos, group_size[j]) ]
      );
  }
  pos += group_size[j];
  }
  return convolution;
}


