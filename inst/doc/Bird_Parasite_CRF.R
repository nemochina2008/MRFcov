## ---- message=FALSE, warning=FALSE---------------------------------------
library(MRFcov)
data("Bird.parasites")

## ----message=F, warning=FALSE, eval = FALSE------------------------------
#  #Not run
#  library(dplyr)
#  data.paras = data.frame(data.paras) %>%
#    group_by(Capturesession,Genus) %>%
#    summarise(count=n()) %>%
#    mutate(prop.zos = count / sum(count)) %>%
#    left_join(data.paras) %>%
#    ungroup() %>% filter(Genus=='Zosterops') %>%
#    mutate(scale.prop.zos = as.vector(scale(prop.zos)))
#  data.paras <- data.paras[,c(12:15,23)]

## ----eval=FALSE----------------------------------------------------------
#  help("Bird.parasites")
#  View(Bird.parasites)

## ----eval=FALSE----------------------------------------------------------
#  MRF_fit = MRFcov(data = Bird.parasites[,1:4], lambda1 = 0,
#                   n_nodes = 4, n_cores = 3)

## ----eval=FALSE----------------------------------------------------------
#  plotMRF_hm(MRF_mod = MRF_fit, main = 'Unregularized MRF',
#                               node_names = c('H. zosteropis', 'H. killangoi',
#                                              'Plasmodium', 'Microfilaria'))

## ----eval=FALSE----------------------------------------------------------
#  library(rosalia)
#  rosalia_fit <- rosalia(Bird.parasites[,1:4],
#                        prior = make_logistic_prior(scale = 2),
#                        trace = FALSE)
#  plotMRF_hm(MRF_mod = rosalia_fit, node_names = c('H. zosteropis', 'H. killangoi',
#                                             'Plasmodium', 'Microfilaria'),
#             main = 'rosalia interactions')

## ----eval=FALSE----------------------------------------------------------
#  comp_rosalia_MRF(MRF_mod = MRF_fit, rosalia_mod = rosalia_fit)

## ----eval=FALSE----------------------------------------------------------
#  MRF_mod <- MRFcov(data = Bird.parasites, n_nodes = 4, lambda1 = 0.5)

## ----eval=FALSE----------------------------------------------------------
#  plotMRF_hm(MRF_mod = MRF_mod)

## ----eval=FALSE----------------------------------------------------------
#  plotMRF_hm_cont(MRF_mod = MRF_mod, covariate = 'scale.prop.zos', data = Bird.parasites,
#                  main = 'Estimated interactions across host relative densities')

## ----eval=FALSE----------------------------------------------------------
#  cv_MRF_diag(data = Bird.parasites, min_lambda1 = 0.4, max_lambda1 = 2, by_lambda1 = 0.1, n_nodes = 4, n_cores = 3)

## ----eval=FALSE----------------------------------------------------------
#  booted_MRF <- bootstrap_MRF(data = Bird.parasites, n_nodes = 4, n_bootstraps = 50, min_lambda1 = 0.5, max_lambda1 = 1.5, by_lambda1 = 0.1, n_cores = 3)

## ----eval=FALSE----------------------------------------------------------
#  plotMRF_hm(MRF_mod = booted_MRF, plot_booted_coefs = TRUE)

## ----eval=FALSE----------------------------------------------------------
#  booted_MRF$mean_key_coefs$Hzosteropis

## ----eval=FALSE----------------------------------------------------------
#  booted_MRF$mean_key_coefs$Hkillangoi

## ----eval=FALSE----------------------------------------------------------
#  booted_MRF$mean_key_coefs$Plas

## ----eval=FALSE----------------------------------------------------------
#  booted_MRF$mean_key_coefs$Microfilaria

