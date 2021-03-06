#'Markov Random Fields with covariates
#'
#'
#'This function is the workhorse of the \code{MRFcov} package, running
#'separate penalized logistic regressions for each node to estimate parameters of
#'Markov Random Fields (MRF) graphs. Covariates can be included
#'(a class of models known as Conditional Random Fields; CRF), to estimate
#'how interactions between nodes vary across covariate magnitudes.
#'
#'@importFrom parallel makePSOCKcluster setDefaultCluster clusterExport stopCluster clusterEvalQ parLapply
#'@import penalized glmnet
#'
#'@param data Dataframe. The input data where the \code{n_nodes}
#'left-most variables are variables that are to be represented by nodes in the graph
#'@param lambda1 Positve numeric. If \code{fixed_lambda = TRUE}, this value is used as the
#'l1−regularization parameter for all node-specific regressions. If \code{fixed_lambda = FALSE},
#'this value is ignored and penalization parameters are optimized automatially, using
#'coordinated gradient descent to minimize cross-validated error.
#'See \code{\link[glmnet]{cv.glmnet}} for further details of \code{lambda1} optimisation
#'@param symmetrise The method to use for symmetrising corresponding parameter estimates
#'(which are taken from separate regressions). Options are \code{min} (take the coefficient with the
#'smallest absolute value), \code{max} (take the coefficient with the largest absolute value)
#'or \code{mean} (take the mean of the two coefficients). Default is \code{mean}
#'@param prep_covariates Logical. If \code{TRUE}, covariate columns will be cross-multiplied
#'with nodes to prep the dataset for MRF models. Note this is only useful when additional
#'covariates are provided. Therefore, if \code{n_nodes < ncol(data)},
#'default is \code{TRUE}. Otherwise, default is \code{FALSE}. See
#'\code{\link{prep_MRF_covariates}} for more information
#'@param n_nodes Positive integer. The index of the last column in \code{data}
#'which is represented by a node in the final graph. Columns with index
#'greater than n_nodes are taken as covariates. Default is the number of
#'columns in \code{data}, corresponding to no additional covariates
#'@param n_cores Positive integer. The number of cores to spread the job across using
#'\code{\link[parallel]{makePSOCKcluster}}. Default is 1 (no parallelisation)
#'@param n_covariates Positive integer. The number of covariates in \code{data}, before cross-multiplication.
#'Default is \code{ncol(data) - n_nodes}
#'@param family The response type. Responses can be quantitative continuous (\code{family = "gaussian"}),
#'non-negative counts (\code{family = "poisson"}) or binomial 1s and 0s (\code{family = "binomial"})
#'@param fixed_lambda Logical. If \code{FALSE}, node-specific regressions are optimized using the
#'cross-validation procedure in \code{\link[glmnet]{cv.glmnet}} to find the \code{lambda1} value
#'that minimises mean cross-validated error. If \code{TRUE}, each regression is run
#'at a single \code{lambda1} value (the same \code{lambda1} value is used for each separate
#'regression). Default is \code{FALSE}
#'@param bootstrap Logical. Used by \code{\link{bootstrap_MRF}} to reduce memory usage
#'
#'@return A \code{list} containing:
#'\itemize{
#'    \item \code{graph}: Estimated parameter matrix of interaction effects
#'    \item \code{intercepts}: Estimated parameter vector of node intercepts
#'    \item \code{indirect_coefs}: \code{list} containing matrices of indirect effects of
#'    each covariate on node interactions
#'    \item \code{direct_coefs}: \code{matrix} of direct covariate effects on
#'    node occurrence probabilities
#'    \item \code{param_names}: Character string of covariate parameter names
#'    \item \code{mod_type}: A character stating the type of model that was fit
#'    (used in other functions)
#'    \item \code{mod_family}: A character stating the family of model that was fit
#'    (used in other functions)
#'    \item \code{poiss_sc_factors}: A vector of the square-root mean scaling factors
#'    used to standardise \code{poisson} variables (only returned if \code{family = "poisson"})
#'    }
#'
#'
#'@references Ising, E. (1925). Beitrag zur Theorie des Ferromagnetismus.
#'Zeitschrift für Physik A Hadrons and Nuclei, 31, 253-258.\cr\cr
#'Cheng, J., Levina, E., Wang, P. & Zhu, J. (2014).
#'A sparse Ising model with covariates. (2012). Biometrics, 70, 943-953.\cr\cr
#'Clark, NJ, Wells, K and Lindberg, O.
#'Unravelling changing interspecific interactions across environmental gradients
#'using Markov random fields. (2018). Ecology doi: 10.1002/ecy.2221.\cr\cr
#'Sutton C, McCallum A. An introduction to conditional random fields.
#'Foundations and Trends in Machine Learning 4, 267-373.
#'
#'@seealso \href{https://www.doria.fi/bitstream/handle/10024/124199/ThesisOscarLindberg.pdf?sequence=2}{Lindberg (2016)}
#'and \href{http://homepages.inf.ed.ac.uk/csutton/publications/crftut-fnt.pdf}{Sutton & McCallum (2012)}
#'for overviews of Conditional Random Fields, \code{\link[penalized]{penalized}} for
#'details of penalized regressions at a fixed lambda, and \code{\link[glmnet]{cv.glmnet}} for
#'details of cross-validated lambda optimization
#'
#'@details Separate penalized regressions are used to approximate
#'MRF parameters, where the regression for species \code{j} includes an
#'intercept and beta coefficients for the abundance (families \code{gaussian} or \code{poisson})
#'or presence-absence (family \code{binomial}) of all other
#'species (\code{/j}) in \code{data}. If covariates are included, beta coefficients
#'are also estimated for the effect of the covariate on \code{j} and the
#'effects of the covariate on interactions between \code{j} and all other species
#'(\code{/j}). Note that coefficients must be estimated on the same scale in order
#'for the resulting models to be unified in a Markov Random Field. Counts for \code{poisson}
#'variables will be therefore standardised using the square root mean transformation
#'\code{x = x / sqrt(mean(x ^ 2))} so that they are on similar ranges. These transformed counts
#'will then be used in a \code{(family = "gaussian")} model and their respective scaling factors
#'will be returned so that coefficients can be unscaled before interpretation (this unscaling is
#'performed automatatically by other functions including \code{\link{predict_MRF}}
#'and \code{\link{cv_MRF_diag}}). Gaussian variables are not automatically transformed, so
#'if they cover quite different ranges and scales, then it is recommended to scale them prior to fitting
#'models.
#'\cr
#'\cr
#'Note that since the number of parameters quickly increases with increasing
#'numbers of species and covariates, LASSO penalization is used to regularize
#'regressions based on values of the regularization parameter \code{lambda1}.
#'This can be done either by minimising the cross-validated
#'mean error for each node separately (using \code{\link[glmnet]{cv.glmnet}}) or by
#'running all regressions at a single \code{lambda1} value. The latter approach may be
#'useful for optimising all nodes as part of a joint graphical model, while the former
#'is likely to be more appropriate for maximising the log-likelihood of each node
#'separately before unifying the nodes into a graph. See \code{\link[penalized]{penalized}}
#'and \code{\link[glmnet]{cv.glmnet}} for further details.
#'
#'@examples
#'\dontrun{
#'data("Bird.parasites")
#'CRFmod <- MRFcov(data = Bird.parasites, n_nodes = 4, family = 'binomial')}
#'
#'@export
#'
MRFcov <- function(data, lambda1, symmetrise,
                   prep_covariates, n_nodes, n_cores, n_covariates,
                   family, fixed_lambda, bootstrap = FALSE) {

  #### Specify default parameter values and initiate warnings ####
  if(!(family %in% c('gaussian', 'poisson', 'binomial')))
    stop('Please select one of the three family options:
         "gaussian", "poisson", "binomial"')

  if(any(is.na(data))){
    stop('NAs detected. Consider removing, replacing or using the bootstrap_mrf function to impute NAs')
  }

  if(any(!is.finite(as.matrix(data)))){
    stop('No infinite values permitted')
  }

  if(missing(symmetrise)){
    symmetrise <- 'mean'
  }

  if(!(symmetrise %in% c('min', 'max', 'mean')))
    stop('Please select one of the three options for symmetrising coefficients:
         "min", "max", "mean"')

  if(missing(fixed_lambda)){
    warning('fixed_lambda not provided. Cross-validated optimisation will commence by default,
            ignoring lambda1')
    fixed_lambda <- FALSE
  }

  if(!fixed_lambda){
    lambda1 <- 1
  }

  if(missing(lambda1)) {
    warning('lambda1 not provided, using cross-validation to optimise each regression')
    fixed_lambda <- FALSE
    lambda1 <- 1
  } else {
    if(lambda1 < 0){
      stop('Please provide a non-negative numeric value for lambda1')
    }
  }

  if(missing(n_cores)) {
    n_cores <- 1
  } else {
    if(sign(n_cores) != 1){
      stop('Please provide a positive integer for n_cores')
    } else{
      if(sfsmisc::is.whole(n_cores) == FALSE){
        stop('Please provide a positive integer for n_cores')
      }
    }
  }

  #### Basic checks on data arguments ####
  if(missing(n_nodes)) {
    warning('n_nodes not specified. using ncol(data) as default, assuming no covariates',
            call. = FALSE)
    n_nodes <- ncol(data)
    n_covariates <- 0
  } else {
    if(sign(n_nodes) != 1){
      stop('Please provide a positive integer for n_nodes')
    } else {
      if(sfsmisc::is.whole(n_nodes) == FALSE){
        stop('Please provide a positive integer for n_nodes')
      }
    }
  }

  if(n_nodes < 2){
    stop('Cannot generate a graphical model with less than 2 nodes')
  }

  if(missing(prep_covariates) & n_nodes < ncol(data)){
    prep_covariates <- TRUE
  }

  if(missing(prep_covariates) & n_nodes == ncol(data)){
    prep_covariates <- FALSE
  }

  if(missing(n_covariates) & prep_covariates == FALSE){
    n_covariates <- (ncol(data) - n_nodes) / (n_nodes + 1)
  }

  if(missing(n_covariates) & prep_covariates == TRUE){
    n_covariates <- ncol(data) - n_nodes
  }

  # Specify number of folds for cv.glmnet based on data size
    if(nrow(data) < 150){
      # If less than 50 observations, use leave one out cv
      n_folds <- nrow(data)
    } else {
      # If > 150 but < 250 observations, use 15-fold cv
      if(nrow(data) < 250){
        n_folds <- 15
      } else {
        # else use the default for cv.glmnet (10-fold cv)
        n_folds <- 10
      }
    }

  #### Use sqrt mean transformation for Poisson variables ####
  if(family == 'poisson'){
    warning('Poisson variables will be standardised by their square root means. Please
            refer to the "poiss_sc_factors" for coefficient interpretations')
    square_root_mean = function(x) {sqrt(mean(x ^ 2))}
    poiss_sc_factors <- apply(data[, 1:n_nodes], 2, square_root_mean)
    data[, 1:n_nodes] <- apply(data[, 1:n_nodes], 2,
                               function(x) x / square_root_mean(x))
    family <- 'gaussian'
    return_poisson <- TRUE

    } else {
    return_poisson <- FALSE
  }

  #### Prep the dataset by cross-multiplication of covariates if necessary ####
  if(prep_covariates){
    prepped_mrf_data <- prep_MRF_covariates(data = data, n_nodes = n_nodes)
    mrf_data <- as.matrix(prepped_mrf_data)
    rm(prepped_mrf_data, data)
  } else {
    mrf_data <- as.matrix(data)
    rm(data)
  }

  #### Extract sds of variables for later back-conversion of coefficients ####
  mrf_sds <- as.vector(t(data.frame(mrf_data) %>%
                            dplyr::summarise_all(dplyr::funs(sd(.)))))

  if(range(mrf_sds)[2] > 1.5){
    mrf_sds <- rep(1, length(mrf_sds))
  } else {
    mrf_sds[mrf_sds < 1] <- 1
  }

  #### Gather parameter values needed for indexing and naming output objects ####
  #Gather node variable (i.e. species) names
  node_names <- colnames(mrf_data[, 1:n_nodes])

  #Gather covariate names
  if(n_covariates > 0){
    cov_names <- colnames(mrf_data)[(n_nodes + 1):ncol(mrf_data)]
  } else {
    cov_names <- NULL
  }

  #### If n_cores > 1, check for parallel loading before initiating parallel clusters ####
  if(n_cores > 1){
    #Initiate the n_cores parallel clusters
    cl <- makePSOCKcluster(n_cores)
    setDefaultCluster(cl)

    #### Check for errors when directly loading a necessary library on each cluster ####
    test_load1 <- try(clusterEvalQ(cl, library(penalized)), silent = TRUE)

    #If errors produced, iterate through other options for library loading
    if(class(test_load1) == "try-error") {

      #Try finding unique library paths using system.file()
      pkgLibs <- unique(c(sub("/penalized$", "", system.file(package = "penalized"))))
      clusterExport(NULL, c('pkgLibs'), envir = environment())
      clusterEvalQ(cl, .libPaths(pkgLibs))

      #Check again for errors loading libraries
      test_load2 <- try(clusterEvalQ(cl, library(penalized)), silent = TRUE)

      if(class(test_load2) == "try-error"){

        #Try loading the user's .libPath() directly
        clusterEvalQ(cl,.libPaths(as.character(.libPaths())))
        test_load3 <- try(clusterEvalQ(cl, library(penalized)), silent = TRUE)

        if(class(test_load3) == "try-error"){

          #Give up and use lapply instead!
          parallel_compliant <- FALSE
          stopCluster(cl)

        } else {
          parallel_compliant <- TRUE
        }

      } else {
        parallel_compliant <- TRUE
      }

    } else {
      parallel_compliant <- TRUE
    }
  } else {
    parallel_compliant <- FALSE
  }

  if(parallel_compliant){
    clusterExport(NULL, c('mrf_data',
                          'lambda1','n_nodes','family','fixed_lambda',
                          'n_folds'),
                  envir = environment())

    #### If not using cross-validation, use function 'penalized' from package penalized for
    #separate regressions with LASSO penalty for each covariate (except intercept) ####
    if(fixed_lambda){
      #Specify family name in penalized syntax
      if(family == 'binomial') fam = 'logistic'
      if(family == 'gaussian') fam = 'linear'

      #Export the necessary library
      clusterEvalQ(cl, library(penalized))

      #Fit the node-wise penalized regressions
      mrf_mods <- parLapply(NULL, seq_len(n_nodes), function(i) {
        penalized(response = mrf_data[,i],
                  penalized = mrf_data[, -which(grepl(colnames(mrf_data)[i], colnames(mrf_data)) == T)],
                  lambda1 = lambda1, steps = 1,
                  model = fam, standardize = TRUE, trace = F, maxiter = 25000)
      })

    } else {
      #Use function 'cv.glmnet' from package glmnet if cross-validation is specified
      #Each node-wise regression will be optimised separately using cv, reducing user-bias
      clusterEvalQ(cl, library(glmnet))
      mrf_mods <- parLapply(NULL, seq_len(n_nodes), function(i) {
        cv.glmnet(x = mrf_data[, -which(grepl(colnames(mrf_data)[i], colnames(mrf_data)) == T)],
                  y = mrf_data[,i], family = family, alpha = 1,
                  nfolds = n_folds, weights = rep(1, nrow(mrf_data)),
                  #lambda = rev(seq(0.0001, 1, length.out = 100)),
                  intercept = TRUE, standardize = TRUE, maxit = 25000)

      })
    }
    stopCluster(cl)

  } else {

    #If parallel is not supported or n_cores = 1, use lapply instead
    if(fixed_lambda){
      if(family == 'binomial') fam <- 'logistic'
      if(family == 'gaussian') fam <- 'linear'

      mrf_mods <- lapply(seq_len(n_nodes), function(i) {
        penalized(response = mrf_data[,i],
                  penalized = mrf_data[, -which(grepl(colnames(mrf_data)[i], colnames(mrf_data)) == T)],
                  lambda1 = lambda1, steps = 1,
                  model = fam, standardize = TRUE, trace = F, maxiter = 25000)
      })

    } else {
      mrf_mods <- lapply(seq_len(n_nodes), function(i) {
        cv.glmnet(x = mrf_data[, -which(grepl(colnames(mrf_data)[i], colnames(mrf_data)) == T)],
                  y = mrf_data[,i], family = family, alpha = 1,
                  nfolds = n_folds, weights = rep(1, nrow(mrf_data)),
                  #lambda = rev(seq(0.0001, 1, length.out = 100)),
                  intercept = TRUE, standardize = TRUE, maxit = 25000)
      })
    }
  }

  #### Gather coefficient parameters from penalized regressions ####
  if(fixed_lambda){
    mrf_coefs <- lapply(mrf_mods, coef, 'all')
    cov_coefs <- NULL

  } else {
    mrf_coefs <- lapply(mrf_mods, function(x){
      coefs <- as.vector(t(as.matrix(coef(x, s = 'lambda.min'))))
      names(coefs) <- dimnames(t(as.matrix(coef(x, s = 'lambda.min'))))[[2]]
      coefs
    })
  }
  rm(mrf_mods)

  #If covariates are included, extract their coefficients from each model
  if(n_covariates > 0){

    #Store each model's coefficients in a dataframe
    direct_coefs <- lapply(mrf_coefs, function(i){
      direct_coefs <- data.frame(t(data.frame(i)))
    })

    #Store coefficients in a list as well for later matrix creation
    cov_coefs <- lapply(mrf_coefs, function(i){
      i[(n_nodes + 1):length(i)]
    })
    names(cov_coefs) <- node_names

    #Gather estimated intercepts and interaction coefficients for node parameters ####
    mrf_coefs <- lapply(mrf_coefs, function(i){
      head(i, n_nodes)
    })

    #Store all direct coefficients in a single dataframe for cleaner results
    direct_coefs <- plyr::rbind.fill(direct_coefs)
    direct_coefs[is.na(direct_coefs)] <- 0

    #Re-order columns to match input data and give clearer names
    column_order <- c('X.Intercept.', colnames(mrf_data))
    direct_coefs <- direct_coefs[, column_order]
    colnames(direct_coefs) <- c('Intercept', colnames(mrf_data))
    rownames(direct_coefs) <- node_names
    rm(column_order)
  } else {

    #If no covariates included, return an empty list for direct_coefs
    direct_coefs = list()
  }

  #### Function to symmetrize corresponding coefficients ####
  symmetr <- function(coef_matrix, check_directs = FALSE, direct_upper = NULL){
    coef_matrix_upper <- coef_matrix[upper.tri(coef_matrix)]
    coef_matrix.lower <- t(coef_matrix)[upper.tri(coef_matrix)]

    if(symmetrise == 'min'){
      # If min, keep the coefficient with the smaller absolute value
      coef_matrix_upper_new <- ifelse(abs(coef_matrix_upper) < abs(coef_matrix.lower),
                                      coef_matrix_upper, coef_matrix.lower)
    }

    if(symmetrise == 'mean'){
      # If mean, take the mean of the two coefficients
      coef_matrix_upper_new <- (coef_matrix_upper + coef_matrix.lower) / 2
    }

    if(symmetrise == 'max'){
      # If max, keep the coefficient with the larger absolute value
      coef_matrix_upper_new <- ifelse(abs(coef_matrix_upper) > abs(coef_matrix.lower),
                                      coef_matrix_upper, coef_matrix.lower)
      }

     if(check_directs){
     # For indirect interactions, conditional relationships can only occur if
     # a direct interaction is found
       direct_upper <- direct_upper[upper.tri(direct_upper)]
       direct_upper[direct_upper > 0] <- 1
       coef_matrix_upper_new <- coef_matrix_upper_new * direct_upper
       }

    coef_matrix_sym <- matrix(0, n_nodes, n_nodes)
    intercepts <- diag(coef_matrix)
    coef_matrix_sym[upper.tri(coef_matrix_sym)] <- coef_matrix_upper_new
    coef_matrix_sym <- t(coef_matrix_sym)
    coef_matrix_sym[upper.tri(coef_matrix_sym)] <- coef_matrix_upper_new
    list(coef_matrix_sym, intercepts)
  }

  #### Create matrices of symmetric interaction coefficient estimates ####
  interaction_matrix <- matrix(0, n_nodes, n_nodes)

  for(i in seq_len(n_nodes)){
    interaction_matrix[i, -i] <- mrf_coefs[[i]][-1]
    interaction_matrix[i, i] <- mrf_coefs[[i]][1]
  }

  #Symmetrize corresponding node interaction coefficients
  interaction_matrix_sym <- symmetr(interaction_matrix)
  dimnames(interaction_matrix_sym[[1]])[[1]] <- node_names
  dimnames(interaction_matrix_sym[[1]])[[2]] <- node_names

  #If covariates are included, create covariate coefficient matrices
  if(n_covariates > 0){
    covariate_matrices <- lapply(seq_len(n_covariates), function(x){
      cov_matrix <- matrix(0, n_nodes, n_nodes)
      for(i in seq_len(n_nodes)){
        cov_names_match <- grepl(paste(cov_names[x], '_', sep = ''), names(cov_coefs[[i]]))
        cov_matrix[i,-i] <- cov_coefs[[i]][cov_names_match]
        cov_matrix[i,i] <- cov_coefs[[i]][x]
        cov_matrix[is.na(cov_matrix)] <- 0
      }
      cov_matrix
    })

    #Symmetrize corresponding interaction coefficients
    indirect_coefs <- lapply(seq_along(covariate_matrices), function(x){
      matrix_to_sym <- covariate_matrices[[x]]
      sym_matrix <- symmetr(matrix_to_sym, check_directs = TRUE,
                            direct_upper = interaction_matrix_sym[[1]])
      dimnames(sym_matrix[[1]])[[1]] <- node_names
      colnames(sym_matrix[[1]]) <- node_names
      list(sym_matrix[[1]])
    })
    names(indirect_coefs) <- cov_names[1:n_covariates]

    #Replace unsymmetric direct interaction coefficients with the symmetric version
    direct_coefs[, 2:(n_nodes + 1)] <- interaction_matrix_sym[[1]]

    #Replace unsymmetric indirect interaction coefficients with symmetric versions
    covs_to_sym <- ncol(direct_coefs) - (1 + n_nodes + n_covariates)
    covs_to_sym_end <- seq(n_nodes, covs_to_sym,
                           by = n_nodes) + (1 + n_nodes + n_covariates)
    covs_to_sym_beg <- covs_to_sym_end - (n_nodes - 1)

    for(i in seq_len(n_covariates)){
      direct_coefs[, covs_to_sym_beg[i] :
                     covs_to_sym_end[i]] <- data.frame(indirect_coefs[[i]])
    }
  } else {

    #If no covariates included, return an empty list for indirect_coefs
    #and return the graph of interaction coefficients as direct_coefs
    indirect_coefs <- list()
    direct_coefs <- matrix(NA, n_nodes, n_nodes + 1)
    direct_coefs[, 2:(n_nodes + 1)] <- interaction_matrix_sym[[1]]
    direct_coefs[, 1] <- interaction_matrix_sym[[2]]
    colnames(direct_coefs) <- c('Intercept', colnames(mrf_data))
    rownames(direct_coefs) <- node_names
  }

  #### Calculate relative importances of coefficients by scaling each coef
  #by the input variable's standard deviation ####
  if(!bootstrap){
  scaled_direct_coefs <- sweep(as.matrix(direct_coefs[, 2 : ncol(direct_coefs)]),
                               MARGIN = 2, mrf_sds, `/`)
  coef_rel_importances <- t(apply(scaled_direct_coefs, 1, function(i) (i^2) / sum(i^2)))
  mean_key_coefs <- lapply(seq_len(n_nodes), function(x){
    if(length(which(coef_rel_importances[x, ] > 0.01)) == 1){
      node_coefs <- data.frame(Variable = names(which((coef_rel_importances[x, ] > 0.01) == T)),
                               Rel_importance = coef_rel_importances[x, which(coef_rel_importances[x, ] > 0.01)],
                               Standardised_coef = scaled_direct_coefs[x, which(coef_rel_importances[x, ] > 0.01)],
                               Raw_coef = direct_coefs[x, 1 + which(coef_rel_importances[x, ] > 0.01)])
    } else {
      node_coefs <- data.frame(Variable = names(coef_rel_importances[x, which(coef_rel_importances[x, ] > 0.01)]),
                               Rel_importance = coef_rel_importances[x, which(coef_rel_importances[x, ] > 0.01)],
                               Standardised_coef = as.vector(t(scaled_direct_coefs[x, which(coef_rel_importances[x, ] > 0.01)])),
                               Raw_coef = as.vector(t(direct_coefs[x, 1 + which(coef_rel_importances[x, ] > 0.01)])))
    }

    rownames(node_coefs) <- NULL

    node_coefs <- node_coefs[order(-node_coefs[, 2]), ]
  })
  names(mean_key_coefs) <- rownames(direct_coefs)
  }

#### Return as a list ####
if(!bootstrap){
if(return_poisson){
  return(list(graph = interaction_matrix_sym[[1]],
              intercepts = interaction_matrix_sym[[2]],
              direct_coefs = direct_coefs,
              indirect_coefs = indirect_coefs,
              param_names = colnames(mrf_data),
              key_coefs = mean_key_coefs,
              mod_type = 'MRFcov',
              mod_family = 'poisson',
              poiss_sc_factors = poiss_sc_factors))
}  else {
  return(list(graph = interaction_matrix_sym[[1]],
              intercepts = interaction_matrix_sym[[2]],
              direct_coefs = direct_coefs,
              indirect_coefs = indirect_coefs,
              param_names = colnames(mrf_data),
              key_coefs = mean_key_coefs,
              mod_type = 'MRFcov',
              mod_family = family))

}
} else {
  #If bootstrap function is called, only return necessary parameters to save memory
  return(list(direct_coefs = direct_coefs,
              indirect_coefs = indirect_coefs))
}
}
