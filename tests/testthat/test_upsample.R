context("Down sampling and up sampling")

.test_that <- function(nm, expr) NULL

.test_that("upSample2", {
  set.seed(123)
  k <- 3
  nbatch <- 3
  means <- matrix(c(-1.2, -1, -0.8, -0.2, 0, 0.2, 0.8, 1, 1.2),
      nbatch, k, byrow = FALSE)
  sds <- matrix(0.1, nbatch, k)
  N <- 1500

  truth <- simulateBatchData(N = N,
                             batch = rep(letters[1:3],
                                         length.out = N),
                             theta = means,
                             sds = sds,
                             p = c(1/5, 1/3, 1 - 1/3 - 1/5))

  ##
  ## Make a tibble:  required plate, plate.index, batch_orig
  ##
  full.data <- tibble(medians=y(truth),
                      plate=batch(truth),
                      batch_orig=as.character(batch(truth))) %>%
    mutate(plate.index=as.integer(factor(plate, levels=unique(plate))))


  ## Below, we down-sample to 500 observations
  ## Required:  batch_orig, batch_index
  partial.data <- downSample(full.data$medians,
                             batches=full.data$batch_orig,
                             size=500)
  expect_true(all(c("batch_orig", "batch_index") %in% colnames(partial.data)))

  ##
  ## Required:  a mapping from plate to batch
  ##
  summarize <- dplyr::summarize
  plate.mapping <- full.data %>%
    select(-medians) %>%
    left_join(select(partial.data, -medians), by="batch_orig") %>%
    group_by(plate.index) %>%
    summarize(plate=unique(plate),
              batch=unique(batch)) %>%
    mutate(batch_index=as.integer(factor(batch, levels=unique(batch))))

  ## Fit a model as per usual to the down-sampled data
  mp <- McmcParams(iter=200, burnin=10, )
  hp <- HyperparametersMultiBatch(k=3)
  model <- MultiBatchModel2(dat=partial.data$medians,
                            batches=partial.data$batch_index,
                            mp=mp,
                            hp=hp)
  model <- posteriorSimulation(model)

  ##
  ## Add the batching used for the down-sampled data to the full data
  ##
  full.data2 <- left_join(full.data, plate.mapping, by="plate")
  ##
  ## Estimate probabilities for each individual in the full data
  ##
  model.full <- upSample2(full.data2, model)

})