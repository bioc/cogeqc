
#' Correct orthogroup scores for overclustering
#'
#' @param homogeneity_df A 2-column data frame with
#' variables \strong{Orthogroup} and \strong{Score} as returned
#' by \code{calculate_H().}
#' @param orthogroup_df Data frame with orthogroups and their associated genes
#' and annotation. The columns \strong{Gene}, \strong{Orthogroup}, and
#' \strong{Annotation} are mandatory, and they must represent Gene ID,
#' Orthogroup ID, and Annotation ID (e.g., Interpro/PFAM), respectively.
#' @param update_score Logical indicating whether to replace scores with
#' corrected scores or not. If FALSE, the dispersal term and corrected scores
#' are returned as separate variables in the output data frame.
#'
#' @return A data frame with the following variables:
#' \describe{
#'   \item{Orthogroup}{Character, orthogroup ID.}
#'   \item{Score}{Numeric, orthogroup scores.}
#'   \item{Dispersal}{Numeric, dispersal term. Only present
#'         if \strong{update_score = FALSE}.}
#'   \item{Score_c}{Numeric, corrected orthogroup scores. Only present if
#'         \strong{update_score = FALSE}.}
#' }
#'
#' @noRd
overclustering_correction <- function(
        homogeneity_df, orthogroup_df, update_score = TRUE
) {

    # Calculate % of domains present in 2+ OGs
    dispersal <- split(orthogroup_df, orthogroup_df$Annotation)
    dispersal <- unlist(lapply(dispersal, function(x) {
        return(length(unique(x$Orthogroup)))
    }))

    dispersal_freq <- (sum(dispersal > 1) / length(dispersal))

    if(update_score) {
        homogeneity_df$Score <- homogeneity_df$Score / dispersal_freq
    } else {
        homogeneity_df$Dispersal <- dispersal_freq
        homogeneity_df$Score_c <- homogeneity_df$Score - dispersal_freq
    }

    return(homogeneity_df)
}


#' Calculate homogeneity scores for orthogroups
#'
#' @param orthogroup_df Data frame with orthogroups and their associated genes
#' and annotation. The columns \strong{Gene}, \strong{Orthogroup}, and
#' \strong{Annotation} are mandatory, and they must represent Gene ID,
#' Orthogroup ID, and Annotation ID (e.g., Interpro/PFAM), respectively.
#' @param correct_overclustering Logical indicating whether to correct
#' for overclustering in orthogroups. Default: TRUE.
#' @param max_size Numeric indicating the maximum orthogroup size to consider.
#' If orthogroups are too large, calculating Sorensen-Dice indices for all
#' pairwise combinations could take a long time, so setting a limit prevents
#' that. Default: 200.
#' @param update_score Logical indicating whether to replace scores with
#' corrected scores or not. If FALSE, the dispersal term and corrected scores
#' are returned as separate variables in the output data frame.
#'
#' @details
#' Homogeneity is calculated based on pairwise Sorensen-Dice similarity
#' indices between gene pairs in an orthogroup, and they range
#' from 0 to 1. Thus, if all genes in an
#' orthogroup share the same domain, the orthogroup will have a homogeneity
#' score of 1. On the other hand, if genes in an orthogroup do not have any
#' domain in common, the orthogroup will have a homogeneity score of 0.
#' The percentage of orthogroups with size greater
#' than \strong{max_size} will be subtracted from the homogeneity scores, since
#' too large orthogroups typically have very low scores.
#' Additionally, users can correct for overclustering by penalizing
#' protein domains that appear in multiple orthogroups (default).
#'
#' @return A 2-column data frame with the variables \strong{Orthogroup}
#' and \strong{Score}, corresponding to orthogroup ID and orthogroup score,
#' respectively. If \strong{update_score = FALSE}, additional columns
#' named \strong{Dispersal} and \strong{Score_c} are added, which correspond
#' to the dispersal term and corrected scores, respectively.
#'
#' @export
#' @rdname calculate_H
#' @examples
#' data(og)
#' data(interpro_ath)
#' orthogroup_df <- merge(og[og$Species == "Ath", ], interpro_ath)
#' # Filter data to reduce run time
#' orthogroup_df <- orthogroup_df[1:10000, ]
#' H <- calculate_H(orthogroup_df)
calculate_H <- function(orthogroup_df, correct_overclustering = TRUE,
                        max_size = 200, update_score = TRUE) {

    by_og <- split(orthogroup_df, orthogroup_df$Orthogroup)

    # Calculate OG sizes
    og_sizes <- vapply(by_og, function(x) {
        return(length(unique(x$Gene)))
    }, numeric(1))
    perc_excluded <- (sum(og_sizes >= max_size) / length(og_sizes)) * 100

    # Calculate homogeneity scores
    sdice <- Reduce(rbind, lapply(by_og, function(x) {

        ngenes <- length(unique(x$Gene))
        og <- unique(x$Orthogroup)

        x <- x[!is.na(x$Annotation), ]
        annot_genes <- unique(x$Gene)

        scores_df <- NULL
        if(length(annot_genes) > 1 & ngenes <= max_size) {

            # Calculate Sorensen-Dice indices for all pairwise combinations
            combinations <- utils::combn(annot_genes, 2, simplify = FALSE)
            scores <- lapply(combinations, function(y) {
                d1 <- x$Annotation[x$Gene == y[1]]
                d2 <- x$Annotation[x$Gene == y[2]]

                numerator <- 2 * length(intersect(d1, d2))
                denominator <- length(d1) + length(d2)
                s <- round(numerator / denominator, 2)
                return(s)
            })
            scores <- unlist(scores) - perc_excluded * 0.1
            scores <- mean(scores)

            scores_df <- data.frame(
                Orthogroup = og,
                Score = scores
            )
        }
        return(scores_df)
    }))

    # Account for overclustering
    if(correct_overclustering) {
        sdice <- overclustering_correction(sdice, orthogroup_df, update_score)
    }

    return(sdice)
}



#' Assess orthogroup inference based on functional annotation
#'
#'
#' @param orthogroups A 3-column data frame with columns \strong{Orthogroup},
#' \strong{Species}, and \strong{Gene}. This data frame can be created from
#' the 'Orthogroups.tsv' file generated by OrthoFinder with the function
#' \code{read_orthogroups()}.
#' @param annotation A list of 2-column data frames with columns
#' \strong{Gene} (gene ID) and \strong{Annotation} (annotation ID).
#' The names of list elements must correspond to species names as
#' in the second column of \emph{orthogroups}. For instance, if there are
#' two species in the \emph{orthogroups} data frame named
#' "SpeciesA" and "SpeciesB", \emph{annotation} must be a
#' list of 2 data frames, and each list element must be named
#' "SpeciesA" and "SpeciesB".
#' @param correct_overclustering Logical indicating whether to correct
#' for overclustering in orthogroups. Default: TRUE.
#'
#' @return A data frame.
#' @rdname assess_orthogroups
#' @export
#' @importFrom stats median
#' @examples
#' data(og)
#' data(interpro_ath)
#' data(interpro_bol)
#' # Subsetting annotation for demonstration purposes.
#' annotation <- list(Ath = interpro_ath[1:1000,], Bol = interpro_bol[1:1000,])
#' assess <- assess_orthogroups(og, annotation)
assess_orthogroups <- function(orthogroups = NULL, annotation = NULL,
                               correct_overclustering = TRUE) {

    og_list <- split(orthogroups, orthogroups$Species)
    og_list <- lapply(seq_along(og_list), function(x) {
        species <- names(og_list)[x]
        idx <- which(names(annotation) == species)
        merged <- merge(og_list[[x]], annotation[[idx]])
        names(merged)[4] <- "Annotation"
        H <- calculate_H(
            merged,
            correct_overclustering = correct_overclustering
        )
        names(H) <- c("Orthogroups", paste0(species, "_score"))
        return(H)
    })

    merge_func <- function(x, y) {
        merge(x, y, by = "Orthogroups", all = TRUE)
    }
    final_df <- Reduce(merge_func, og_list)
    means <- apply(final_df[, -1], 1, mean, na.rm = TRUE)
    medians <- apply(final_df[, -1], 1, median, na.rm = TRUE)

    final_df$Mean_score <- means
    final_df$Median_score <- medians
    return(final_df)
}


#' Compare inferred orthogroups to a reference set
#'
#' @param ref_orthogroups Reference orthogroups in a 3-column data frame
#' with columns \strong{Orthogroup}, \strong{Species}, and \strong{Gene}.
#' This data frame can be created from the 'Orthogroups.tsv' file
#' generated by OrthoFinder with the function \code{read_orthogroups()}.
#' @param test_orthogroups Test orthogroups that will be compared
#' to \emph{ref_orthogroups} in the same 3-column data frame format.
#'
#' @details This function compares a test set of orthogroups to a reference set
#' and returns which orthogroups in the reference set are fully preserved
#' in the test set (i.e., identical gene repertoire) and which are not. Species
#' names (column 2) must be the same between reference and test set. If some
#' species are not shared between reference and test sets, they will not be
#' considered for the comparison.
#'
#' @return A 2-column data frame with the following variables:
#' \describe{
#'   \item{Orthogroup}{Character of orthogroup IDs.}
#'   \item{Preserved}{A logical vector of preservation status. It is TRUE if
#'   the orthogroup in the reference set is fully preserved in the test set,
#'   and FALSE otherwise.}
#' }
#' @export
#' @rdname compare_orthogroups
#' @examples
#' set.seed(123)
#' data(og)
#' og <- og[1:5000, ]
#' ref <- og
#' # Shuffle genes to simulate a different set
#' test <- data.frame(
#'     Orthogroup = sample(og$Orthogroup, nrow(og), replace = FALSE),
#'     Species = og$Species,
#'     Gene = og$Gene
#' )
#' comparison <- compare_orthogroups(ref, test)
#'
#' # Calculating percentage of preservation
#' sum(comparison$Preserved) / length(comparison$Preserved)
compare_orthogroups <- function(ref_orthogroups = NULL,
                                test_orthogroups = NULL) {

    # Get only species that are present in both sets
    species <- intersect(
        unique(ref_orthogroups$Species), unique(test_orthogroups$Species)
    )
    if(length(species) == 0) {
        stop("There are no species in common between both sets.")
    }
    ref <- ref_orthogroups[ref_orthogroups$Species %in% species, ]
    test <- test_orthogroups[test_orthogroups$Species %in% species, ]

    # Compare sets
    ref_list <- split(ref, ref$Orthogroup)
    comp <- Reduce(rbind, lapply(ref_list, function(x) {
        ## Get all genes in orthogroup x
        genes_ref <- x$Gene

        ## Check if `genes_ref` are in a single orthogroup in the test set
        og_test <- unique(test[test$Gene %in% genes_ref, "Orthogroup"])
        n_ogs <- length(og_test)

        preserved <- FALSE
        if(n_ogs == 1) {
            ## Check if number of genes in OGs is the same for ref and test
            genes_test <- test[test$Orthogroup %in% og_test, "Gene"]
            if(identical(length(genes_test), length(genes_ref))) {
                preserved <- TRUE
            }
        }

        df <- data.frame(Orthogroup = unique(x$Orthogroup),
                         Preserved = preserved)
        return(df)
    }))
    return(comp)
}

