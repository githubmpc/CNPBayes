set_param_names <- function(x, nm){
  K <- seq_len(ncol(x))
  set_colnames(x, paste0(nm, K))
}

mcmcList <- function(model.list){
  if(!is(model.list, "list")){
    model.list <- list(model.list)
  }
  ch.list <- map(model.list, chains)
  theta.list <- map(ch.list, theta) %>%
    map(set_param_names, "theta")
  sigma.list <- map(ch.list, sigma) %>%
    map(set_param_names, "sigma")
  p.list <- map(ch.list, p) %>%
    map(set_param_names, "p")
  nu0.list <- map(ch.list, nu.0) %>%
    map(as.matrix) %>%
    map(set_param_names, "nu.0")
  s20.list <- map(ch.list, sigma2.0) %>%
    map(as.matrix) %>%
    map(set_param_names, "sigma2.0")
  mu.list <- map(ch.list, mu) %>%
    map(as.matrix) %>%
    map(set_param_names, "mu")
  tau2.list <- map(ch.list, tau2) %>%
    map(as.matrix) %>%
    map(set_param_names, "tau2")
  loglik <- map(ch.list, log_lik) %>%
    map(as.matrix) %>%
    map(set_param_names, "log_lik")
  half <- floor(nrow(theta.list[[1]])/2)
  first_half <- function(x, half){
    x[seq_len(half), , drop=FALSE]
  }
  last_half <- function(x, half){
    i <- (half + 1):(half*2)
    x <- x[i, , drop=FALSE]
    x
  }
  theta.list <- c(map(theta.list, first_half, half),
                  map(theta.list, last_half, half))
  sigma.list <- c(map(sigma.list, first_half, half),
                  map(sigma.list, last_half, half))
  p.list <- c(map(p.list, first_half, half),
              map(p.list, last_half, half))
  nu0.list <- c(map(nu0.list, first_half, half),
                map(nu0.list, last_half, half))
  s20.list <- c(map(s20.list, first_half, half),
                map(s20.list, last_half, half))
  mu.list <- c(map(mu.list, first_half, half),
               map(mu.list, last_half, half))
  tau2.list <- c(map(tau2.list, first_half, half),
                map(tau2.list, last_half, half))
  vars.list <- vector("list", length(p.list))
  for(i in seq_along(vars.list)){
    vars.list[[i]] <- cbind(theta.list[[i]],
                            sigma.list[[i]],
                            p.list[[i]],
                            nu0.list[[i]],
                            s20.list[[i]],
                            mu.list[[i]],
                            tau2.list[[i]])
  }
  vars.list <- map(vars.list, mcmc)
  ##loglik2 <- mcmc(do.call(rbind, loglik))
  mlist <- mcmc.list(vars.list)
  if(k(model.list[[1]]) == 1){
    ## there is no p chain
    dropP <- function(x) x[, -match("p1", colnames(x))]
    mlist <- map(mlist, dropP)
  }
  mlist
}


diagnostics <- function(model.list){
  mlist <- mcmcList(model.list)
  neff <- effectiveSize(mlist)
  r <- gelman_rubin(mlist, hyperParams(model.list[[1]]))
  list(neff=neff, r=r)
}

combine_batch <- function(model.list, batches){
  . <- NULL
  ch.list <- map(model.list, chains)
  th <- map(ch.list, theta) %>% do.call(rbind, .)
  s2 <- map(ch.list, sigma2) %>% do.call(rbind, .)
  ll <- map(ch.list, log_lik) %>% unlist
  pp <- map(ch.list, p) %>% do.call(rbind, .)
  n0 <- map(ch.list, nu.0) %>% unlist
  s2.0 <- map(ch.list, sigma2.0) %>% unlist
  logp <- map(ch.list, logPrior) %>% unlist
  .mu <- map(ch.list, mu) %>% do.call(rbind, .)
  .tau2 <- map(ch.list, tau2) %>% do.call(rbind, .)
  zfreq <- map(ch.list, zFreq) %>% do.call(rbind, .)
  mc <- new("McmcChains",
            theta=th,
            sigma2=s2,
            pi=pp,
            mu=.mu,
            tau2=.tau2,
            nu.0=n0,
            sigma2.0=s2.0,
            zfreq=zfreq,
            logprior=logp,
            loglik=ll)
  hp <- hyperParams(model.list[[1]])
  mp <- mcmcParams(model.list[[1]])
  iter(mp) <- nrow(th)
  B <- length(unique(batches))
  K <- k(model.list[[1]])
  pm.th <- matrix(colMeans(th), B, K)
  pm.s2 <- matrix(colMeans(s2), B, K)
  pm.p <- colMeans(pp)
  pm.n0 <- median(n0)
  pm.mu <- colMeans(.mu)
  pm.tau2 <- colMeans(.tau2)
  pm.s20 <- mean(s2.0)
  pz <- map(model.list, probz) %>% Reduce("+", .)
  pz <- pz/length(model.list)
  ## the accessor divides by number of iterations, so rescale
  pz <- pz * (iter(mp) - 1)
  zz <- max.col(pz)
  yy <- y(model.list[[1]])
  y_mns <- as.numeric(tapply(yy, zz, mean))
  y_prec <- as.numeric(1/tapply(yy, zz, var))
  zfreq <- as.integer(table(zz))
  any_label_swap <- any(map_lgl(model.list, label_switch))
  ## use mean marginal likelihood in combined model,
  ## or NA if marginal likelihood has not been estimated
  ml <- map_dbl(model.list, marginal_lik)
  if(all(is.na(ml))) {
    ml <- as.numeric(NA)
  } else ml <- mean(ml, na.rm=TRUE)
  nbatch <- as.integer(table(batch(model.list[[1]])))
  model <- new(class(model.list[[1]]),
               k=k(hp),
               hyperparams=hp,
               theta=pm.th,
               sigma2=pm.s2,
               mu=pm.mu,
               tau2=pm.tau2,
               nu.0=pm.n0,
               sigma2.0=pm.s20,
               pi=pm.p,
               data=y(model.list[[1]]),
               u=u(model.list[[1]]),
               data.mean=y_mns,
               data.prec=y_prec,
               z=zz,
               zfreq=zfreq,
               probz=pz,
               logprior=numeric(1),
               loglik=numeric(1),
               mcmc.chains=mc,
               batch=batch(model.list[[1]]),
               batchElements=nbatch,
               modes=list(),
               mcmc.params=mp,
               label_switch=any_label_swap,
               marginal_lik=ml,
               .internal.constraint=5e-4,
               .internal.counter=0L)
  modes(model) <- computeModes(model)
  log_lik(model) <- computeLoglik(model)
  logPrior(model) <- computePrior(model)
  model
}

selectModels <- function(model.list){
  ll <- sapply(model.list, log_lik)
  cl <- tryCatch(kmeans(ll, centers=2)$cluster, error=function(e) NULL)
  if(is.null(cl)){
    return(rep(TRUE, length(model.list)))
  }
  mean.ll <- sort(map_dbl(split(ll, cl), mean))
  keep <- cl == names(mean.ll)[2]
  if(sum(keep) < 2){
    ## keep all models
    keep <- rep(TRUE, length(model.list))
  }
  keep
}

gelman_rubin <- function(mcmc_list, hp){
  anyNA <- function(x){
    any(is.na(x))
  }
  any_nas <- map_lgl(mcmc_list, anyNA)
  mcmc_list <- mcmc_list[ !any_nas ]
  if(length(mcmc_list) < 2 ) stop("Need at least two MCMC chains")
  r <- tryCatch(gelman.diag(mcmc_list, autoburnin=FALSE), error=function(e) NULL)
  if(is.null(r)){
    ## gelman rubin can fail if p is not positive definite
    ## check also for any parameters that were not updated
    no_updates <- apply(mcmc_list[[1]], 2, var) == 0
    pcolumn <- c(which(paste0("p", k(hp)) == colnames(mcmc_list[[1]])),
                 which(no_updates))
    if(length(pcolumn) == 0) stop("Gelman Rubin not available. Check chain for anomolies")
    f <- function(x, pcolumn){
      x[, -pcolumn]
    }
    mcmc_list <- map(mcmc_list, f, pcolumn) %>%
      as.mcmc.list
    r <- gelman.diag(mcmc_list, autoburnin=FALSE)
    if(FALSE){
      mc <- do.call(rbind, mcmc_list) %>%
        as.tibble
      mc$iter <- rep(seq_len(nrow(mcmc_list[[1]])), length(mcmc_list))
      dat <- gather(mc, key="parameter", value="chain", -iter)
      ggplot(dat, aes(iter, chain)) + geom_line() +
        facet_wrap(~parameter, scales="free_y")
    }
  }
  r
}

harmonizeU <- function(model.list){
  uu <- u(model.list[[1]])
  for(i in seq_along(model.list)){
    if(i == 1) next()
    m <- model.list[[i]]
    m@u <- uu
    model.list[[i]] <- m
  }
  model.list
}

compute_marginal_lik <- function(model, params){
  ##
  ## evaluate marginal likelihood. Relax default conditions
  ##
  if(missing(params)){
    params <- mlParams(root=1/2,
                       reject.threshold=exp(-100),
                       prop.threshold=0.5,
                       prop.effective.size=0)
  }
  ml <- tryCatch(marginalLikelihood(model, params), warning=function(w) NULL)
  if(!is.null(ml)){
    marginal_lik(model) <- ml
    message("     marginal likelihood: ", round(marginal_lik(model), 2))
  } else {
    ##warning("Unable to compute marginal likelihood")
    message("Unable to compute marginal likelihood")
  }
  model
}

gibbs_batch <- function(hp, mp, dat, max_burnin=32000, batches, min_effsize=500){
  nchains <- nStarts(mp)
  nStarts(mp) <- 1L ## because posteriorsimulation uses nStarts in a different way
  if(iter(mp) < 500){
    warning("Require at least 500 Monte Carlo simulations")
    MIN_EFF <- ceiling(iter(mp) * 0.5)
  } else MIN_EFF <- min_effsize
  MIN_CHAINS <- 3
  MIN_GR <- 1.2
  neff <- 0; r <- 2
  while(burnin(mp) < max_burnin && thin(mp) < 100){
    message("  k: ", k(hp), ", burnin: ", burnin(mp), ", thin: ", thin(mp))
    mod.list <- replicate(nchains, MultiBatchModel2(dat=dat,
                                                    hp=hp,
                                                    mp=mp,
                                                    batches=batches))
    mod.list <- suppressWarnings(map(mod.list, posteriorSimulation))
    no_label_swap <- !map_lgl(mod.list, label_switch)
    if(sum(no_label_swap) < MIN_CHAINS){
      burnin(mp) <- as.integer(burnin(mp) * 2)
      mp@thin <- as.integer(thin(mp) + 2)
      nStarts(mp) <- nStarts(mp) + 1
      next()
    }
    mod.list <- mod.list[ no_label_swap ]
    mod.list <- mod.list[ selectModels(mod.list) ]
    mlist <- mcmcList(mod.list)
    neff <- tryCatch(effectiveSize(mlist), error=function(e) NULL)
    if(is.null(neff)) neff <- 0
    r <- gelman_rubin(mlist, hp)
    message("     Gelman-Rubin: ", round(r$mpsrf, 2))
    message("     eff size (median): ", round(min(neff), 1))
    message("     eff size (mean): ", round(mean(neff), 1))
    if((mean(neff) > min_effsize) && r$mpsrf < MIN_GR) break()
    burnin(mp) <- as.integer(burnin(mp) * 2)
    mp@thin <- as.integer(thin(mp) + 2)
    nStarts(mp) <- nStarts(mp) + 1
    ##mp@thin <- as.integer(thin(mp) * 2)
  }
  model <- combine_batch(mod.list, batches)
  meets_conditions <- (mean(neff) > min_effsize) &&
    r$mpsrf < MIN_GR &&
    !label_switch(model)
  if(meets_conditions){
    model <- compute_marginal_lik(model)
  }
  model
}

updateK <- function(ncomp, h) {
  k(h) <- ncomp
  h
}

gibbs_batch_K <- function(hp,
                          mp,
                          k_range=c(1, 4),
                          dat,
                          batches,
                          max_burnin=32000,
                          reduce_size=TRUE,
                          min_effsize=500){
  K <- seq(k_range[1], k_range[2])
  hp.list <- map(K, updateK, hp)
  model.list <- map(hp.list,
                    gibbs_batch,
                    mp=mp,
                    dat=dat,
                    batches=batches,
                    max_burnin=max_burnin,
                    min_effsize=min_effsize)
  names(model.list) <- paste0("MB", map_dbl(model.list, k))
  ## sort by marginal likelihood
  ##
  ## if(reduce_size) TODO:  remove z chain, keep y in one object
  ##
  ix <- order(map_dbl(model.list, marginal_lik), decreasing=TRUE)
  models <- model.list[ix]
}


#' Run a Gibbs sampler on one or multiple types of Bayesian Gaussian mixture models
#'
#' Model types:
#' SB (SingleBatchModel):  hierarchical model with mixture component-specific means and variances;
#' MB (MultiBatchModel): hierarchical model with mixture component- and batch-specific means and variances;
#' SBP (SingleBatchPooled):  similar to SB model but with a pooled
#estimate of the variance across all mixture components;
#' MBP (MultiBatchPooled):  similar to MB model but with a pooled estimate of the variance (across mixture components) for each batch.
#'
#' @param model a character vector indicating which models to fit (any combination of 'SB', 'MB', 'SBP', and 'MBP')
#' @param dat numeric vector of the summary copy number data for each sample at a single CNP (e.g., the median log R ratio for each sample)
#' @param hp.list  a list of hyperparameters for each of the different models.  If missing, this list will be generated automatically with default hyperparameters that work well for copy number data
#' @param mp an object of class \code{McmcParams}
#' @param batches  an integer vector of the same length as \code{dat} indicating the batch in which the sample was processed
#' @param k_range a length-two numeric vector providing the minimum and maximum number of components to model.  For example, c(1, 3) will fit mixture models with 1, 2, and 3 components.
#' @param max_burnin the maximum number of burnin iterations. See
#'   details.
#' @param top a length-one numeric vector indicating how many of the top
#'   models to return.
#'
#' @details For each model specified, a Gibbs sampler will be initiated
#for \code{nStarts} independently simulated starting values (we suggest
#\code{nStarts > 2}).  The burnin, number of iterations after burnin,
#and the thin parameters are specified in the \code{mp} argument.    If
#the effective number of independent MCMC draws for any of the parameter
#chains is less than 500 or if the multivariate Gelman Rubin convergence
#diagnostic is less than 1.2, the thin and the burnin will be doubled
#and we start over -- new chains are initalized independently and the
#Gibbs sampler is restarted. This process is repeated until the
#effective sample size is greater than 500 and the Gelman Rubin
#convergence diagnostic is less than 1.2.
#'
#' The number of mixture models fit depends on \code{k_range} and
#\code{model}. For example, if \code{model=c("SBP", "MBP")} and
#\code{k_range=c(1, 4)}, the number of mixture models evaluated will be
#2 x 4, or 8. The fitted models will be sorted by the marginal likelihood (when
#estimable) and only the top models will be returned.
#'
#' @return A list of models of length \code{top} sorted by decreasing
#values of the marginal likelihood.
#'
#' @examples
#'   set.seed(100)
#'   nbatch <- 3
#'   k <- 3
#'   means <- matrix(c(-2.1, -2, -1.95, -0.41, -0.4, -0.395, -0.1,
#'       0, 0.05), nbatch, k, byrow = FALSE)
#'   sds <- matrix(0.15, nbatch, k)
#'   sds[, 1] <- 0.3
#'   N <- 1000
#'   truth <- simulateBatchData(N = N, batch = rep(letters[1:3],
#'                                                 length.out = N),
#'                              p = c(1/10, 1/5, 1 - 0.1 - 0.2),
#'                              theta = means,
#'                              sds = sds)
#'   \dontrun{
#'     gibbs(model=c("SB", "SBP", "MB", "MBP"),
#'           dat=y(truth),
#'           mp=mcmcParams(),
#'           batches=batch(truth),
#'           k_range=c(1, 4),
#'           max_burnin=10000,
#'           top=2,
#'           df=100)
#'   }
#'
#' @seealso \code{\link[coda]{gelman.diag}}
#'   \code{\link[coda]{effectiveSize}} \code{\link{marginalLikelihood}}
#' @export
gibbs <- function(model=c("SB", "MB", "SBP", "MBP"),
                  dat,
                  mp,
                  hp.list,
                  batches,
                  k_range=c(1, 4),
                  max_burnin=32e3,
                  top=2,
                  df=100,
                  min_effsize=500){
  if(any(!model %in% c("SB", "MB", "SBP", "MBP")))
    stop("model must be a character vector with elements `SB`, `MB`, `SBP`, `MBP`")
  model <- unique(model)
  max_burnin <- max(max_burnin, burnin(mp)) + 1
  if(("MB" %in% model || "MBP" %in% model) && missing(batches)){
    stop("batches is missing.  Must specify batches for MB and MBP models")
  }
  model <- unique(model)
  if(missing(hp.list)){
    hp.list <- hpList(df=df)
  }
  if("SB" %in% model){
    message("Fitting SB models")
    sb <- gibbs_batch_K(hp.list[["MB"]],
                        k_range=k_range,
                        mp=mp,
                        dat=dat,
                        batches=rep(1L, length(dat)),
                        max_burnin=max_burnin,
                        min_effsize=min_effsize)
  } else sb <- NULL
  if("MB" %in% model){
    message("Fitting MB models")
    mb <- gibbs_batch_K(hp.list[["MB"]],
                        k_range=k_range,
                        mp=mp,
                        dat=dat,
                        batches=batches,
                        max_burnin=max_burnin,
                        min_effsize=min_effsize)
  } else mb <- NULL
  if("SBP" %in% model){
    message("Fitting SBP models")
    sbp <- gibbsMultiBatchPooled(hp.list[["MBP"]],
                                 k_range=k_range,
                                 mp=mp,
                                 dat=dat,
                                 batches=rep(1L, length(dat)),
                                 max_burnin=max_burnin,
                                 min_effsize=min_effsize)
  } else sbp <- NULL
  if("MBP" %in% model){
    message("Fitting MBP models")
    mbp <- gibbsMultiBatchPooled(hp.list[["MBP"]],
                                 k_range=k_range,
                                 mp=mp,
                                 dat=dat,
                                 batches=batches,
                                 max_burnin=max_burnin,
                                 min_effsize=min_effsize)
  } else mbp <- NULL
  models <- c(sb, mb, sbp, mbp)
  ## order models by marginal likelihood
  ml <- map_dbl(models, marginal_lik)
  top <- min(top, length(models))
  ix <- head(order(ml, decreasing=TRUE), top)
  models <- models[ix]
  names(models) <- sapply(models, modelName)
  models
}
