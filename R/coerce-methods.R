setAs("HyperparametersBatch", "HyperparametersMultiBatch", function(from, to){
  new("HyperparametersMultiBatch",
      k=k(from),
      mu.0=mu.0(from),
      tau2.0=tau2.0(from),
      eta.0=eta.0(from),
      m2.0=m2.0(from),
      alpha=alpha(from),
      beta=from@beta,
      a=a(from),
      b=b(from))
})

##setAs("BatchModel", "MultiBatchModel", function(from, to){
##  hypp <- as(hyperParams(from), "HyperparametersMultiBatch")
##  new("MultiBatchModel",
##      k=k(from),
##      hyperparams=hypp,
##      theta=theta(from),
##      batch=batch(from),
##      sigma2=sigma2(from),
##      nu.0=nu.0(from),
##      sigma2.0=sigma2.0(from),
##      pi=p(from),
##      mu=mu(from),
##      tau2=tau2(from),
##      data=y(from),
##      data.mean=from@data.mean,
##      data.prec=from@data.prec,
##      z=z(from),
##      zfreq=zFreq(from),
##      probz=probz(from),
##      logprior=logPrior(from),
##      loglik=log_lik(from),
##      mcmc.chains=chains(from),
##      mcmc.params=mcmcParams(from),
##      label_switch=label_switch(from),
##      marginal_lik=marginal_lik(from),
##      .internal.constraint=from@.internal.constraint,
##      .internal.counter=from@.internal.counter)
##})

##setAs("MarginalModel", "SingleBatchModel", function(from, to){
##  ##hypp <- as(hyperParams(from), "Hyperparameters")
##  hypp <- hyperParams(from)
##  new("SingleBatchModel",
##      k=k(from),
##      hyperparams=hypp,
##      theta=theta(from),
##      batch=batch(from),
##      sigma2=sigma2(from),
##      nu.0=nu.0(from),
##      sigma2.0=sigma2.0(from),
##      pi=p(from),
##      mu=mu(from),
##      tau2=tau2(from),
##      data=y(from),
##      data.mean=from@data.mean,
##      data.prec=from@data.prec,
##      z=z(from),
##      zfreq=zFreq(from),
##      probz=probz(from),
##      logprior=logPrior(from),
##      loglik=log_lik(from),
##      mcmc.chains=chains(from),
##      mcmc.params=mcmcParams(from),
##      label_switch=label_switch(from),
##      marginal_lik=marginal_lik(from),
##      .internal.constraint=from@.internal.constraint,
##      .internal.counter=from@.internal.counter)
##})


setAs("SingleBatchPooled", "SingleBatchCopyNumber", function(from, to){
  ##hypp <- as(hyperParams(from), "Hyperparameters")
  hypp <- hyperParams(from)
  new("SingleBatchCopyNumber",
      k=k(from),
      hyperparams=hypp,
      theta=theta(from),
      batch=batch(from),
      sigma2=sigma2(from),
      nu.0=nu.0(from),
      sigma2.0=sigma2.0(from),
      pi=p(from),
      mu=mu(from),
      tau2=tau2(from),
      data=y(from),
      u=u(from),
      data.mean=from@data.mean,
      data.prec=from@data.prec,
      z=z(from),
      zfreq=zFreq(from),
      probz=from@probz,
      logprior=logPrior(from),
      loglik=log_lik(from),
      mcmc.chains=chains(from),
      mcmc.params=mcmcParams(from),
      label_switch=label_switch(from),
      marginal_lik=marginal_lik(from),
      modes=modes(from),
      .internal.constraint=from@.internal.constraint,
      .internal.counter=from@.internal.counter,
      mapping=as.character(seq_len(k(from))))
})

setAs("MultiBatchPooled", "MultiBatchCopyNumberPooled", function(from, to){
  ##hypp <- as(hyperParams(from), "Hyperparameters")
  hypp <- hyperParams(from)
  ub <- unique(batch(from))
  nbatch <- setNames(as.integer(table(batch(from))), ub)
  new("MultiBatchCopyNumberPooled",
      k=k(from),
      hyperparams=hypp,
      theta=theta(from),
      batch=batch(from),
      batchElements=nbatch,
      sigma2=sigma2(from),
      nu.0=nu.0(from),
      sigma2.0=sigma2.0(from),
      pi=p(from),
      mu=mu(from),
      tau2=tau2(from),
      data=y(from),
      u=u(from),
      data.mean=from@data.mean,
      data.prec=from@data.prec,
      z=z(from),
      zfreq=zFreq(from),
      probz=from@probz,
      logprior=logPrior(from),
      loglik=log_lik(from),
      mcmc.chains=chains(from),
      mcmc.params=mcmcParams(from),
      label_switch=label_switch(from),
      marginal_lik=marginal_lik(from),
      .internal.constraint=from@.internal.constraint,
      .internal.counter=from@.internal.counter,
      mapping=as.character(seq_len(k(from))),
      modes=modes(from))
})



setAs("SingleBatchModel", "SingleBatchPooled", function(from, to){
  ##hypp <- as(hyperParams(from), "Hyperparameters")
  hypp <- hyperParams(from)
  ##
  ## chains slot for sigma should be different
  ##
  ch <- chains(from)
  ch@sigma2 <- matrix(NA, iter(from), 1)
  if(length(y(from)) > 0){
    w <- table(z(from))
    sigma_pooled <- sum(w*sigma(from))/sum(w)
  } else sigma_pooled <- numeric(1)
  new("SingleBatchPooled",
      k=k(from),
      hyperparams=hypp,
      theta=theta(from),
      batch=batch(from),
      sigma2=sigma_pooled^2,
      nu.0=nu.0(from),
      sigma2.0=sigma2.0(from),
      pi=p(from),
      mu=mu(from),
      tau2=tau2(from),
      data=y(from),
      u=u(from),
      data.mean=from@data.mean,
      data.prec=from@data.prec,
      z=z(from),
      zfreq=zFreq(from),
      probz=from@probz,
      logprior=logPrior(from),
      loglik=log_lik(from),
      mcmc.chains=ch,
      mcmc.params=mcmcParams(from),
      label_switch=label_switch(from),
      marginal_lik=marginal_lik(from),
      .internal.constraint=from@.internal.constraint,
      .internal.counter=from@.internal.counter)
})

setAs("MultiBatchModel", "MultiBatchPooled", function(from, to){
  hp <- hyperParams(from)
  ##
  ## chains slot for sigma should be different
  ##
  ch <- chains(from)
  nb <- length(unique(batch(from)))
  ch@sigma2 <- matrix(NA, iter(from), nb)
  if(length(y(from)) > 0){
    sigma_pooled <- rowMeans(sigma(from))
    ##w <- table(z(from))
    ##sigma_pooled <- sum(w*sigma(from))/sum(w)
  } else sigma_pooled <- numeric(nb)
  new("MultiBatchPooled",
      k=k(from),
      hyperparams=hp,
      theta=theta(from),
      batch=batch(from),
      sigma2=sigma_pooled^2,
      nu.0=nu.0(from),
      sigma2.0=sigma2.0(from),
      pi=p(from),
      mu=mu(from),
      tau2=tau2(from),
      data=y(from),
      u=u(from),
      data.mean=from@data.mean,
      data.prec=from@data.prec,
      z=z(from),
      zfreq=zFreq(from),
      probz=from@probz,
      logprior=logPrior(from),
      loglik=log_lik(from),
      mcmc.chains=ch,
      mcmc.params=mcmcParams(from),
      label_switch=label_switch(from),
      marginal_lik=marginal_lik(from),
      .internal.constraint=from@.internal.constraint,
      .internal.counter=from@.internal.counter)
})

setAs("SingleBatchModel", "MultiBatchModel", function(from, to){
  hp <- hyperParams(from)
  ##
  ## chains slot for sigma should be different
  ##
  ch <- chains(from)
  nb <- 1L
  ch@sigma2 <- matrix(NA, iter(from), nb)
  new("MultiBatchModel",
      k=k(from),
      hyperparams=hp,
      theta=matrix(from@theta, nrow=1),
      batch=rep(1L, length(y(from))),
      sigma2=matrix(from@sigma2, nrow=1),
      nu.0=nu.0(from),
      sigma2.0=sigma2.0(from),
      pi=p(from),
      mu=from@mu,
      tau2=tau2(from),
      data=y(from),
      u=u(from),
      data.mean=matrix(from@data.mean, nrow=1),
      data.prec=matrix(from@data.prec, nrow=1),
      z=z(from),
      zfreq=zFreq(from),
      probz=from@probz,
      logprior=logPrior(from),
      loglik=log_lik(from),
      mcmc.chains=ch,
      mcmc.params=mcmcParams(from),
      label_switch=label_switch(from),
      marginal_lik=marginal_lik(from),
      .internal.constraint=from@.internal.constraint,
      .internal.counter=from@.internal.counter)
})

setAs("SingleBatchPooled", "MultiBatchPooled", function(from, to){
  hp <- hyperParams(from)
  ##
  ## chains slot for sigma should be different
  ##
  ch <- chains(from)
  nb <- 1L
  ch@sigma2 <- matrix(NA, iter(from), nb)
  new("MultiBatchPooled",
      k=k(from),
      hyperparams=hp,
      theta=matrix(theta(from), nrow=1),
      batch=rep(1L, length(y(from))),
      sigma2=matrix(sigma2(from), nrow=1),
      nu.0=nu.0(from),
      sigma2.0=sigma2.0(from),
      pi=p(from),
      mu=from@mu,
      tau2=tau2(from),
      data=y(from),
      u=u(from),
      data.mean=matrix(from@data.mean, nrow=1),
      data.prec=matrix(from@data.prec, nrow=1),
      z=z(from),
      zfreq=zFreq(from),
      probz=from@probz,
      logprior=logPrior(from),
      loglik=log_lik(from),
      mcmc.chains=ch,
      mcmc.params=mcmcParams(from),
      label_switch=label_switch(from),
      marginal_lik=marginal_lik(from),
      .internal.constraint=from@.internal.constraint,
      .internal.counter=from@.internal.counter)
})
