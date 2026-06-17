#' Report Summary Table
#'
#' Returns compact rows describing the main scientific reporting workflow components.
#'
#' @returns A data frame with stable columns for reports.
#' @export
report_summary_table <- function() {
  data.frame(
    Component = c(
      "Row subsampling",
      "Column perturbation",
      "Functional grouping",
      "Selection surface",
      "Path diagnostics",
      "Benchmark evidence"
    ),
    Role = c(
      "Estimate stability frequencies at the subject level",
      "Perturb correlated features through SelectBoost groups",
      "Respect curve blocks, intervals, basis blocks, or FPCA components",
      "Track selection over subsampling rate and perturbation strength",
      "Summarize monotonicity and precision-recall trade-offs",
      "Compare FDA-aware SelectBoost with plain SelectBoost and stability baselines"
    ),
    Output = c(
      "q-indexed frequencies",
      "c0-indexed proportions",
      "feature, group, interval, and basis maps",
      "(q, c0) selection data frame",
      "diagnostic and threshold-path tables",
      "mean F1, Jaccard, recall, precision, and win-rate summaries"
    ),
    stringsAsFactors = FALSE
  )
}

#' Report Method Table
#'
#' Returns method-comparison rows for scientific reports.
#'
#' @returns A data frame with method, perturbation, group structure, output,
#'   and best-use columns.
#' @export
report_method_table <- function() {
  data.frame(
    Method = c(
      "Grouped stability selection",
      "Interval stability selection",
      "FDA-aware SelectBoost",
      "Plain SelectBoost",
      "FDboost stability selection"
    ),
    Perturbation = c(
      "Subject subsampling",
      "Subject subsampling",
      "Subject subsampling plus correlation-aware column perturbation",
      "Correlation-aware column perturbation",
      "Model-native subsampling"
    ),
    `Group structure` = c(
      "Functional blocks or supplied groups",
      "Domain intervals",
      "Correlation, neighborhood, hybrid, or interval groups",
      "Correlation-driven groups on the flattened matrix",
      "Functional model effects"
    ),
    Output = c(
      "Feature and group frequencies",
      "Interval frequencies",
      "Feature, group, basis, and interval selection surfaces",
      "Feature and group selection proportions",
      "Functional-effect stability frequencies"
    ),
    `Best suited for` = c(
      "General grouped FDA recovery",
      "Interpretable selected time or wavelength regions",
      "Dense functional correlation and confounded blocks",
      "Finite-dimensional baseline comparisons",
      "Already specified FDboost regression models"
    ),
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
}

default_benchmark_path <- function() {
  system.file(
    "extdata",
    "benchmarks",
    "selectboost_sensitivity_top_settings.csv",
    package = "SelectBoost.FDA"
  )
}

#' Report Benchmark Table
#'
#' Extracts a compact benchmark comparison table for FDA-aware versus plain
#' SelectBoost.
#'
#' @param x Optional benchmark object or data frame. When omitted, the shipped
#'   saved sensitivity-study table is used if available.
#' @param top_n Number of rows to return.
#'
#' @returns A data frame with scenario, association, mean F1 values, delta, and
#'   win rate.
#' @export
report_benchmark_table <- function(x = NULL, top_n = 6L) {
  if (is.null(x)) {
    path <- default_benchmark_path()
    if (!nzchar(path) || !file.exists(path)) {
      return(data.frame(
        Scenario = character(), Association = character(), Bandwidth = numeric(),
        `F1 FDA-aware` = numeric(), `F1 plain` = numeric(), Delta = numeric(),
        `Win rate` = numeric(), check.names = FALSE
      ))
    }
    data <- utils::read.csv(path, stringsAsFactors = FALSE)
  } else if (inherits(x, c("fda_benchmark", "fda_simulation_study"))) {
    advantage <- summarise_benchmark_advantage(
      x,
      target = "selectboost",
      reference = "plain_selectboost",
      level = "feature",
      metric = "f1"
    )
    performance <- summarise_benchmark_performance(
      x,
      level = "feature",
      metric = "f1"
    )
    setting_cols <- intersect(
      c("scenario", "association_method", "bandwidth"),
      names(advantage)
    )
    fda <- performance[performance$method == "selectboost", c(setting_cols, "f1_mean"), drop = FALSE]
    plain <- performance[performance$method == "plain_selectboost", c(setting_cols, "f1_mean"), drop = FALSE]
    names(fda)[names(fda) == "f1_mean"] <- "selectboost_f1_mean"
    names(plain)[names(plain) == "f1_mean"] <- "plain_selectboost_f1_mean"
    data <- merge(advantage, fda, by = setting_cols, all.x = TRUE, sort = FALSE)
    data <- merge(data, plain, by = setting_cols, all.x = TRUE, sort = FALSE)
  } else {
    data <- as.data.frame(x, stringsAsFactors = FALSE)
  }

  data <- data[order(-(data$delta_mean %||% data$Delta %||% 0)), , drop = FALSE]
  data <- utils::head(data, as.integer(top_n))
  data.frame(
    Scenario = data$scenario %||% data$Scenario %||% NA_character_,
    Association = data$association_method %||% data$Association %||% NA_character_,
    Bandwidth = data$bandwidth %||% data$Bandwidth %||% NA_real_,
    `F1 FDA-aware` = data$selectboost_f1_mean %||% data$`F1 FDA-aware` %||% NA_real_,
    `F1 plain` = data$plain_selectboost_f1_mean %||% data$`F1 plain` %||% NA_real_,
    Delta = data$delta_mean %||% data$Delta %||% NA_real_,
    `Win rate` = data$win_rate %||% data$`Win rate` %||% NA_real_,
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
}

#' Report Formula Blocks
#'
#' Returns named LaTeX formula strings used in report material.
#'
#' @returns A named list of character strings.
#' @export
report_formula_blocks <- function() {
  list(
    finite_representation = "X_i(t) \\approx \\sum_{k=1}^{p_b} x_{ik}\\phi_k(t)",
    row_subsampling = "\\widehat{\\Pi}_j(q)=B^{-1}\\sum_{b=1}^B \\mathbf{1}\\{j\\in \\widehat S_q^{(b)}\\}",
    column_perturbation = "\\mathcal G_j(c_0)=\\{k: A_{jk}\\ge c_0\\},\\quad A_{jk}\\in[0,1]",
    selection_surface = "(q,c_0)\\longmapsto \\widehat{\\Pi}_j(q,c_0)",
    group_penalty = "\\frac{1}{2n}\\|y-X\\theta\\|_2^2+\\lambda\\sum_{g\\in\\mathcal G}w_g\\|\\theta_g\\|_2",
    precision_recall = "\\mathrm{Precision}=\\frac{|\\widehat S\\cap S^\\star|}{|\\widehat S|},\\quad \\mathrm{Recall}=\\frac{|\\widehat S\\cap S^\\star|}{|S^\\star|}"
  )
}
