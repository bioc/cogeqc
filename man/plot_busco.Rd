% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/genome_assembly.R
\name{plot_busco}
\alias{plot_busco}
\title{Plot BUSCO summary output}
\usage{
plot_busco(summary_df = NULL)
}
\arguments{
\item{summary_df}{Data frame with BUSCO summary output as returned
by \code{read_busco()}.}
}
\value{
A ggplot object with a barplot of BUSCOs in each class.
}
\description{
Plot BUSCO summary output
}
\examples{
# Single file
result_dir <- system.file("extdata", package = "cogeqc")
summary_df <- read_busco(result_dir)
# Batch mode
data(batch_summary)
plot_busco(summary_df)
plot_busco(batch_summary)
}
