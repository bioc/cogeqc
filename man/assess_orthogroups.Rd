% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/homology_detection.R
\name{assess_orthogroups}
\alias{assess_orthogroups}
\title{Assess orthogroup inference based on functional annotation}
\usage{
assess_orthogroups(
  orthogroups = NULL,
  annotation = NULL,
  correct_overclustering = TRUE
)
}
\arguments{
\item{orthogroups}{A 3-column data frame with columns \strong{Orthogroup},
\strong{Species}, and \strong{Gene}. This data frame can be created from
the 'Orthogroups.tsv' file generated by OrthoFinder with the function
\code{read_orthogroups()}.}

\item{annotation}{A list of 2-column data frames with columns
\strong{Gene} (gene ID) and \strong{Annotation} (annotation ID).
The names of list elements must correspond to species names as
in the second column of \emph{orthogroups}. For instance, if there are
two species in the \emph{orthogroups} data frame named
"SpeciesA" and "SpeciesB", \emph{annotation} must be a
list of 2 data frames, and each list element must be named
"SpeciesA" and "SpeciesB".}

\item{correct_overclustering}{Logical indicating whether to correct
for overclustering in orthogroups. Default: TRUE.}
}
\value{
A data frame.
}
\description{
Assess orthogroup inference based on functional annotation
}
\examples{
data(og)
data(interpro_ath)
data(interpro_bol)
# Subsetting annotation for demonstration purposes.
annotation <- list(Ath = interpro_ath[1:1000,], Bol = interpro_bol[1:1000,])
assess <- assess_orthogroups(og, annotation)
}
