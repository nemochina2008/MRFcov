#' Dipping surveys for mosquitos and aquatic species.
#'
#' A dataset containing binary occurrences of four mosquito species and
#' 12 other fauna types at specific dipping points in the North Kent Marshes,
#' UK 2010-2011. Continuous covariates have been scaled, and factor covariates
#' have been converted to model matrix forma (i.e. the base contrast level for each factor
#' is not shown; see the \code{Prepping datasets for CRF models} vignette for a
#' tutorial on how this was accomplished). This data coincides with the manuscript:
#' Golding, N., Nunn, M.A. & Purse, B.V. (2015).
#' Identifying biotic interactions which drive the spatial distribution of a mosquito community.
#' Parasites & Vectors, 8, 367.
#'
#' @format A data frame with 555 rows and 33 variables:
#' \describe{
#'   \item{Culex_pipiens_sl}{binary occurrence of \emph{Culex pipiens}}
#'   \item{Culex_modestus}{binary occurrence of \emph{Culex modestus}}
#'   \item{Culiseta_annulata}{binary occurrence of \emph{Culiseta annulata}}
#'   \item{Anopholes maculipennis_sl}{binary occurrence of \emph{Anopholes maculipennis}}
#'   \item{waterboatmen__Corixidae}{binary occurrence of \emph{Corixidae} species}
#'   \item{diving_beetles__Dysticidae}{binary occurrence of \emph{CDysticidae} species}
#'   \item{damselflies__Zygoptera}{binary occurrence of \emph{Zygoptera} species}
#'   \item{swimming_beetles__Haliplidae}{binary occurrence of \emph{Haliplidae} species}
#'   \item{opossum_shrimps__Mysidae}{binary occurrence of \emph{Mysidae} species}
#'   \item{ditch_shrimp__Gammarus}{binary occurrence of \emph{Gammarus} species}
#'   \item{beetle_larvae__Coleoptera}{binary occurrence of \emph{Coleoptera} species}
#'   \item{dragonflies__Anisoptera}{binary occurrence of \emph{Anisoptera} species}
#'   \item{mayflies__Ephemeroptera}{binary occurrence of \emph{Ephemeroptera} species}
#'   \item{newts__Pleurodelinae}{binary occurrence of \emph{Pleurodelinae} species}
#'   \item{fish}{binary occurrence of fish species}
#'   \item{saucer_bugs__Ilyocoris}{binary occurrence of \emph{Ilyocoris} species}
#'   \item{depth__cm}{scaled numeric variable representing water depth}
#'   \item{temperature__C}{scaled numeric variable representing water temperature}
#'   \item{oxidation_reduction_potential__Mv}{scaled numeric variable representing water
#'   oxidation reduction potential}
#'   \item{salinity__ppt}{scaled numeric variable representing water salinity}
#'   \item{water_crowfoot__Ranunculus}{binary occurrence of \emph{Ranunculus} species}
#'   \item{rushes__Juncus_or_Scirpus}{binary occurrence of \emph{Juncus / Scirpus} species}
#'   \item{filamentous_algae}{binary occurrence of filamentous algae}
#'   \item{emergent_grass}{binary occurrence of emergent grass}
#'   \item{ivy_leafed_duckweed__Lemna_trisulca}{binary occurrence of \emph{Lemna trisulca}}
#'   \item{bulrushes__Typha}{binary occurrence of \emph{Typha} species}
#'   \item{reeds_Phragmites}{binary occurrence of \emph{Phragmites} species}
#'   \item{marestail__Hippuris}{binary occurrence of \emph{Hippuris} species}
#'   \item{common_duckweed__Lemna_minor}{binary occurrence of \emph{Lemna minor}}
#'   \item{field_site1}{model matrix variable for the factor \emph{field site}, site E. The
#'   base contrast level for this variable is site C}
#'   \item{dipping_round3}{model matrix variable for the factor \emph{dipping_round}, round 3. The
#'   base contrast level for this variable is round 2}
#'   \item{dipping_round5}{model matrix variable for the factor \emph{dipping_round}, round 5. The
#'   base contrast level for this variable is round 2}
#'   \item{dipping_round6}{model matrix variable for the factor \emph{dipping_round}, round 6. The
#'   base contrast level for this variable is round 2}
#' }
#' @references Golding, N., Nunn, M.A. & Purse, B.V. (2015) Identifying biotic interactions
#' which drive the spatial distribution of a mosquito community. Parasites & Vectors, 8, 367
#' @source \url{https://doi.org/10.6084/m9.figshare.1420528.v1}
"Dipping.survey"
