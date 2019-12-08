
#include /chunks/license.stan

functions {
#include /chunks/stationary_functions.stan
#include /chunks/calc_rlnorm_gp.stan
#include /chunks/r_in.stan
#include /chunks/map_rect.stan
}

data {
  int N; // total number of observations
  int N_int; // if outcome is an integer
  int N_cont; // if outcome is continuous
  int T; // number of time points
  int Y_int[N_int]; // integer outcome
  int within_chain; // whether to use map_rect
  real Y_cont[N_cont]; // continuous outcome
  int y_int_miss; // missing value for integers
  real y_cont_miss; // missing value for continuous data
  int S; // number of shards
  int S_int; // shard length for integers
  int S_cont; // shard length for reals
  int S_type; // whether shards are based on persons or items
  int int_shards[S,S_int]; // integer shards
  int cont_shards[S,S_cont]; // real shards
  int LX; // legislator/person covariates
  int SRX; // observed item predictors
  int SAX; // missing item predictors
  int<lower=1> num_legis;
  int<lower=1> num_bills;
  int ll[N]; // persons/legislators id
  int bb[N]; // items/bills id
  int time[N]; // time point id
  int mm[N]; // model counter id
  matrix[N,LX] legis_pred;
  matrix[N,SRX] srx_pred;
  matrix[N,SAX] sax_pred;
  int mod_count; // total number of models
  int tot_cats; // total number of possible ordinal outcomes
  int n_cats[tot_cats]; // how many outcomes per outcome size int he data
  int order_cats[N_int]; // indicator for whether an observation comes from a certain ordinal model
  real discrim_reg_sd;
  real discrim_abs_sd;
  real legis_sd;
  real diff_abs_sd;
  real diff_reg_sd;
  real restrict_sd;
  real time_sd;
  real ar_sd;
  //int restrict_var;
  //real restrict_var_high;
  int time_proc;
  real time_ind[T]; // the actual indices/values of time points, used for Gaussian processes
  int zeroes; // whether to use traditional zero-inflation for bernoulli and poisson models
  real gp_sd_par; // residual variation in GP
  real num_diff; // number of time points used to calculate GP length-scale prior
  real m_sd_par; // the marginal standard deviation of the GP
  int min_length; // the minimum threshold for GP length-scale prior
}

transformed data {
	int m;                         // missing value
	int m_step; // number of ordinal categories
	int absence[N]; // need to create absence indicator
	int Y_new[N];
	real m_cont;
	int num_var_restrict;
	int num_var_free;
	int num_bills_grm;
	int num_ls; // extra person params for latent space
	int gp_N; // use for creating zero-length arrays if gp not used
	int gp_N_fix;
	int gp_1; // zero-length gp-related scalars
	int gp_nT; // used to make L_tp1 go to model block if GPs are used
	int gp_oT; // used to make L_tp1 go to model block if GPs are used
	vector[1] gp_length; 
	
	// set mean of log-normal distribution for GP length-scale prior
	if(time_proc==4) {
	  gp_length = gp_prior_mean(time_ind,num_diff,min_length);
	} else {
	  gp_length = [0.0]';
	}
	
	
	//reset these values to use GP-specific parameters
	if(time_proc!=4) {
	  gp_N=0;
	  gp_N_fix=0;
	  gp_1=0;
	  gp_oT=T;
	  gp_nT=0;
	} else {
	  gp_N=num_legis;
	  gp_N_fix=num_legis-1;
	  gp_1=1;
	  gp_nT=T;
	  gp_oT=0;
	}
	
	// need to assign a type of outcome to Y based on the model (discrete or continuous)
	// to do this we need to trick Stan into assigning to an integer. 
	
	// we're going to either do this data processing step before running the model
	// or we'll do it in the model calculation itself
	
//#include /chunks/change_outcome.stan

// determine whether to restrict variance or not

// if(restrict_var==1) {
//   num_var_restrict=num_legis;
//   num_var_free=0;
// } else {
//   num_var_restrict=0;
//   num_var_free=num_legis;
// }
  
  // do we have a latent space model?
  if(r_in(13,mm)==1 || r_in(14,mm)==1) {
    num_ls=num_legis;
  } else {
    num_ls=0;
  }
  
  // check if there are GRM models
  
  if(r_in(5,mm)==1 || r_in(6,mm)==1) {
    num_bills_grm = num_bills;
    } else {
      num_bills_grm = 0;
    }

}

parameters {
  vector[num_bills] sigma_abs_free;
  vector[num_legis] L_full;
  vector[num_ls] ls_int; // extra intercepts for non-inflated latent space
  vector[num_legis] L_tp1_var[T-1]; // non-centered variance
  vector[num_legis] L_tp2[gp_nT]; // additional L_tp1 for GPs only
  vector<lower=-0.99,upper=0.99>[num_legis] L_AR1; // AR-1 parameters for AR-1 model
  vector[num_bills] sigma_reg_free;
  vector[LX] legis_x;
  vector[SRX] sigma_reg_x;
  vector[SAX] sigma_abs_x;
  ordered[n_cats[1]-1] steps_votes3;
  ordered[n_cats[2]-1] steps_votes4;
  ordered[n_cats[3]-1] steps_votes5;
  ordered[n_cats[4]-1] steps_votes6;
  ordered[n_cats[5]-1] steps_votes7;
  ordered[n_cats[6]-1] steps_votes8;
  ordered[n_cats[7]-1] steps_votes9;
  ordered[n_cats[8]-1] steps_votes10;
  ordered[n_cats[1]-1] steps_votes_grm3[num_bills_grm];
  ordered[n_cats[2]-1] steps_votes_grm4[num_bills_grm];
  ordered[n_cats[3]-1] steps_votes_grm5[num_bills_grm];
  ordered[n_cats[4]-1] steps_votes_grm6[num_bills_grm];
  ordered[n_cats[5]-1] steps_votes_grm7[num_bills_grm];
  ordered[n_cats[6]-1] steps_votes_grm8[num_bills_grm];
  ordered[n_cats[7]-1] steps_votes_grm9[num_bills_grm];
  ordered[n_cats[8]-1] steps_votes_grm10[num_bills_grm];
  vector[num_bills] B_int_free;
  vector[num_bills] A_int_free;
  vector<lower=0>[gp_N_fix] m_sd_free; // marginal standard deviation for GPs
  vector<lower=0>[gp_N_fix] gp_sd_free; //additional residual variation in Y for GPs
  real<lower=0> extra_sd;
  vector[gp_N_fix] time_var_gp_free; // variance for time series processes. constrained if GP
  vector<lower=0>[num_legis-1] time_var_free; // optional restricted variance
}

transformed parameters {
  
  vector[num_legis] time_var_full;
  vector[gp_N] time_var_gp_full;
  vector[gp_N] m_sd_full;
  vector[gp_N] gp_sd_full;
  vector[num_legis] L_tp1[T]; // all other params can float
  
  
  time_var_full = append_row([time_sd]',time_var_free);
  
  
  if(T>1) {
    if(time_proc==3) {
      // in AR model, intercepts are constant over time
#include /chunks/l_hier_ar1_prior.stan

    } else if(time_proc==2) {
      // in RW model, intercepts are used for first time period
#include /chunks/l_hier_prior.stan
    } else if(time_proc==4) {
      L_tp1 = L_tp2; // just copy over the variables, saves code if costs a bit of extra memory
                      // should be manageable memory loss
      m_sd_full = append_row([m_sd_par]',
                              m_sd_free);
      gp_sd_full = append_row([gp_sd_par]',
                              gp_sd_free);
      time_var_gp_full = append_row(gp_length,
                                      time_var_gp_free);
  } else {
    L_tp1[1] = L_full;
  }

  } else {
    L_tp1[1] = L_full;
  }
}

model {


  L_full ~ normal(0,legis_sd);
  
  if(time_proc==4) {
    {
    matrix[T, T] cov[gp_N]; // zero-length if not a GP model
    matrix[T, T] L_cov[gp_N];// zero-length if not a GP model
// chunk giving a GP prior to legislators/persons

for(n in 1:num_legis) {
  
  //create covariance matrices given current values of hiearchical parameters
  
  cov[n] =   cov_exp_quad(time_ind, m_sd_full[n], time_var_full[n])
      + diag_matrix(rep_vector(square(gp_sd_full[n]),T));
  L_cov[n] = cholesky_decompose(cov[n]);

  to_vector(L_tp2[,n]) ~ multi_normal_cholesky(rep_vector(0,T), L_cov[n]); 
  
    
}
    }
  }
  
  for(t in 1:(T-1)) {
    L_tp1_var[t] ~ normal(0,1);
  }


  sigma_abs_free ~ normal(0,discrim_abs_sd);
  sigma_reg_free ~ normal(0,discrim_reg_sd);
  legis_x ~ normal(0,5);
  sigma_reg_x ~ normal(srx_pred[num_bills, ] * sigma_reg_x,5);
  sigma_abs_x ~ normal(sax_pred[num_bills, ] * sigma_abs_x,5);
  L_AR1 ~ normal(0,ar_sd); // these parameters shouldn't get too big
  ls_int ~ normal(0,legis_sd);
  extra_sd ~ exponential(1);
  time_var_gp_free ~ normal(0,1);
  gp_sd_free ~ normal(0,1);
  m_sd_free ~ normal(0,1); // tight prior on GP marginal standard deviation

#include /chunks/ord_steps_calc.stan  

  B_int_free ~ normal(0,diff_reg_sd);
  A_int_free ~ normal(0,diff_abs_sd);

  
  time_var_free ~ normal(0,1);

  
  //model

#include /chunks/model_types_mm.stan

}

