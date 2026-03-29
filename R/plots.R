selection_palette <- function(n = 100L) {
  grDevices::colorRampPalette(c("#f7fbff", "#6baed6", "#08519c"))(n)
}

selection_colors <- function(values, zlim = range(values, na.rm = TRUE), palette = selection_palette()) {
  if (!all(is.finite(zlim))) {
    zlim <- c(0, 1)
  }
  if (diff(zlim) == 0) {
    zlim <- c(zlim[1], zlim[2] + 1e-8)
  }

  scaled <- (values - zlim[1]) / diff(zlim)
  scaled <- pmin(pmax(scaled, 0), 1)
  palette[pmax(1L, pmin(length(palette), floor(scaled * (length(palette) - 1L)) + 1L))]
}

draw_heatmap_legend <- function(zlim,
                                palette = selection_palette(),
                                title = "Value",
                                xleft,
                                xright,
                                ybottom,
                                ytop,
                                n_ticks = 3L,
                                digits = 2L,
                                cex = 0.75,
                                show = TRUE) {
  if (!isTRUE(show)) {
    return(invisible(NULL))
  }

  if (!all(is.finite(zlim))) {
    zlim <- c(0, 1)
  }
  if (diff(zlim) == 0) {
    zlim <- c(zlim[1], zlim[2] + 1e-8)
  }

  y_breaks <- seq(ybottom, ytop, length.out = length(palette) + 1L)
  for (i in seq_along(palette)) {
    graphics::rect(
      xleft = xleft,
      ybottom = y_breaks[i],
      xright = xright,
      ytop = y_breaks[i + 1L],
      col = palette[i],
      border = NA
    )
  }
  graphics::rect(xleft, ybottom, xright, ytop, border = "grey40")

  tick_values <- pretty(zlim, n = n_ticks)
  tick_values <- tick_values[tick_values >= zlim[1] & tick_values <= zlim[2]]
  if (length(tick_values) == 0L) {
    tick_values <- zlim
  }
  tick_pos <- ybottom + (tick_values - zlim[1]) / diff(zlim) * (ytop - ybottom)
  graphics::axis(
    side = 4,
    at = tick_pos,
    labels = formatC(tick_values, digits = digits, format = "fg"),
    las = 1,
    tick = FALSE,
    line = -0.2,
    cex.axis = cex
  )
  graphics::text(
    x = (xleft + xright) / 2,
    y = ytop + 0.08 * (ytop - ybottom),
    labels = title,
    cex = cex
  )
}

plot_selection_bars <- function(values,
                                labels,
                                main,
                                ylab,
                                cutoff = NULL,
                                col = "#2b8cbe",
                                border = NA,
                                ...) {
  if (length(labels) > 24L) {
    labels <- rep("", length(labels))
  }

  ylim <- c(0, max(values, cutoff %||% 0, na.rm = TRUE) * 1.05)
  positions <- graphics::barplot(
    height = values,
    names.arg = labels,
    las = 2,
    col = col,
    border = border,
    main = main,
    ylab = ylab,
    ylim = ylim,
    ...
  )

  if (!is.null(cutoff)) {
    graphics::abline(h = cutoff, lty = 2, col = "#cb181d")
  }

  invisible(positions)
}

plot_selection_heatmap <- function(map,
                                   row_var,
                                   col_var,
                                   value_var,
                                   palette = selection_palette(),
                                   show_legend = TRUE,
                                   legend_title = value_var,
                                   legend_n_ticks = 3L,
                                   legend_digits = 2L,
                                   legend_cex = 0.75,
                                   main,
                                   xlab,
                                   ylab) {
  rows <- unique(map[[row_var]])
  cols <- unique(map[[col_var]])
  row_index <- stats::setNames(seq_along(rows), rows)
  col_index <- stats::setNames(seq_along(cols), cols)
  values <- map[[value_var]]
  colors <- selection_colors(values, palette = palette)
  x_legend_left <- length(cols) + 0.9
  x_legend_right <- length(cols) + 1.2
  x_plot_max <- length(cols) + 1.8

  graphics::plot(
    x = c(0.5, x_plot_max),
    y = c(0.5, length(rows) + 0.5),
    type = "n",
    xaxt = "n",
    yaxt = "n",
    xlab = xlab,
    ylab = ylab,
    main = main
  )

  for (i in seq_len(nrow(map))) {
    x_pos <- col_index[[as.character(map[[col_var]][i])]]
    y_pos <- row_index[[as.character(map[[row_var]][i])]]
    graphics::rect(
      xleft = x_pos - 0.5,
      ybottom = y_pos - 0.5,
      xright = x_pos + 0.5,
      ytop = y_pos + 0.5,
      col = colors[i],
      border = "white"
    )
  }

  graphics::axis(1, at = seq_along(cols), labels = cols, las = 2)
  graphics::axis(
    2,
    at = seq_along(rows),
    labels = if (length(rows) <= 30L) rows else rep("", length(rows)),
    las = 2
  )
  draw_heatmap_legend(
    zlim = range(values, na.rm = TRUE),
    palette = palette,
    title = legend_title,
    xleft = x_legend_left,
    xright = x_legend_right,
    ybottom = 0.8,
    ytop = max(1.2, length(rows) - 0.2),
    n_ticks = legend_n_ticks,
    digits = legend_digits,
    cex = legend_cex,
    show = show_legend
  )
  graphics::box()
  invisible(map)
}

plot_interval_heatmap <- function(map,
                                  value_var,
                                  facet = c("none", "predictor"),
                                  palette = selection_palette(),
                                  show_legend = TRUE,
                                  legend_title = value_var,
                                  legend_n_ticks = 3L,
                                  legend_digits = 2L,
                                  legend_cex = 0.75,
                                  main = "Interval selection heatmap",
                                  xlab = "Position",
                                  ylab = "Predictor") {
  facet <- match.arg(facet)
  predictors <- unique(map$predictor)
  values <- map[[value_var]]
  colors <- selection_colors(values, palette = palette)

  if (identical(facet, "predictor") && length(predictors) > 1L) {
    old_par <- graphics::par(no.readonly = TRUE)
    on.exit(graphics::par(old_par), add = TRUE)
    graphics::par(
      mfrow = c(length(predictors), 1L),
      mar = c(3.2, 4.1, 2.1, 1.1),
      oma = c(0, 0, 1, 0)
    )

    for (predictor in predictors) {
      subset_map <- map[map$predictor == predictor, , drop = FALSE]
      plot_interval_heatmap(
        map = subset_map,
        value_var = value_var,
        facet = "none",
        palette = palette,
        show_legend = show_legend,
        legend_title = legend_title,
        legend_n_ticks = legend_n_ticks,
        legend_digits = legend_digits,
        legend_cex = legend_cex,
        main = paste(main, "-", predictor),
        xlab = xlab,
        ylab = ylab
      )
    }

    return(invisible(map))
  }

  y_index <- stats::setNames(seq_along(predictors), predictors)
  x_legend_left <- max(map$interval_end) + 0.9
  x_legend_right <- max(map$interval_end) + 1.2
  x_plot_max <- max(map$interval_end) + 1.8
  graphics::plot(
    x = c(min(map$interval_start) - 0.5, x_plot_max),
    y = c(0.5, length(predictors) + 0.5),
    type = "n",
    xaxt = "n",
    yaxt = "n",
    xlab = xlab,
    ylab = ylab,
    main = main
  )

  for (i in seq_len(nrow(map))) {
    y_pos <- y_index[[map$predictor[i]]]
    graphics::rect(
      xleft = map$interval_start[i] - 0.5,
      ybottom = y_pos - 0.4,
      xright = map$interval_end[i] + 0.5,
      ytop = y_pos + 0.4,
      col = colors[i],
      border = "white"
    )
  }

  graphics::axis(1)
  graphics::axis(2, at = seq_along(predictors), labels = predictors, las = 1)
  draw_heatmap_legend(
    zlim = range(values, na.rm = TRUE),
    palette = palette,
    title = legend_title,
    xleft = x_legend_left,
    xright = x_legend_right,
    ybottom = 0.8,
    ytop = max(1.2, length(predictors) - 0.2),
    n_ticks = legend_n_ticks,
    digits = legend_digits,
    cex = legend_cex,
    show = show_legend
  )
  graphics::box()
  invisible(map)
}

#' Plot FDA Selection Results
#'
#' Plots feature-, group-, interval-, and basis-level summaries derived from
#' [selection_map()]. The available views depend on the fitted object:
#'
#' - `fda_stability_selection` supports `type = "feature"`, `"group"`,
#'   `"interval"`, and `"basis"`.
#' - `selectboost_fda_result` supports `type = "feature"`, `"group"`, and
#'   `"basis"`.
#'
#' Heatmap-based views are used for interval summaries and for SelectBoost
#' summaries over multiple `c0` values. Bar-plot views are used otherwise.
#'
#' @param x An object returned by [stability_selection_fda()],
#'   [interval_stability_selection()], [fit_stability()], [selectboost_fda()],
#'   or [fit_selectboost()].
#' @param type Summary view to plot. Stability-selection fits support
#'   `"feature"`, `"group"`, `"interval"`, and `"basis"`. SelectBoost fits
#'   support `"feature"`, `"group"`, and `"basis"`.
#' @param value Quantity summarized in group, interval, and basis views.
#'   Stability-selection fits accept `"group"`, `"mean"`, and `"max"`.
#'   SelectBoost fits accept `"mean"` and `"max"`.
#' @param facet Faceting mode for interval heatmaps. Currently only
#'   `type = "interval"` uses this argument.
#' @param palette Vector of colors used for heatmaps.
#' @param show_legend Logical; should heatmap views draw a legend?
#' @param legend_title Optional legend title for heatmap views. By default an
#'   informative title is chosen from `type` and `value`.
#' @param legend_n_ticks Approximate number of tick marks used in the heatmap
#'   legend.
#' @param legend_digits Number of significant digits used for heatmap legend
#'   labels.
#' @param legend_cex Character expansion used for heatmap legend text.
#' @param cutoff Stability threshold. Only used for `fda_stability_selection`
#'   objects.
#' @param c0 Optional SelectBoost correlation threshold. When omitted,
#'   SelectBoost heatmaps are drawn across all available `c0` values.
#' @param ... Additional graphical parameters passed to bar-plot-based views.
#'
#' @returns Invisibly returns the helper output used to build the plot.
#'
#' @seealso [selection_map()]
#' @name plot.fda_selection

#' @export
#' @rdname plot.fda_selection
plot.fda_stability_selection <- function(x,
                                         type = c("feature", "group", "interval", "basis"),
                                         value = c("group", "mean", "max"),
                                         facet = c("none", "predictor"),
                                         palette = selection_palette(),
                                         show_legend = TRUE,
                                         legend_title = NULL,
                                         legend_n_ticks = 3L,
                                         legend_digits = 2L,
                                         legend_cex = 0.75,
                                         cutoff = x$cutoff,
                                         ...) {
  type <- match.arg(type)
  facet <- match.arg(facet)
  value <- match.arg(value)

  if (identical(type, "interval")) {
    map <- selection_map(x, level = "group", cutoff = cutoff)
    if (!all(c("interval_start", "interval_end") %in% names(map))) {
      stop("Interval metadata are only available for interval-based fits.", call. = FALSE)
    }

    value_var <- switch(
      value,
      group = "group_frequency",
      mean = "mean_feature_frequency",
      max = "max_feature_frequency"
    )
    title_prefix <- switch(
      value,
      group = "Group frequency",
      mean = "Mean feature frequency",
      max = "Max feature frequency"
    )
    legend_title <- legend_title %||% title_prefix

    return(plot_interval_heatmap(
      map = map,
      value_var = value_var,
      facet = facet,
      palette = palette,
      show_legend = show_legend,
      legend_title = legend_title,
      legend_n_ticks = legend_n_ticks,
      legend_digits = legend_digits,
      legend_cex = legend_cex,
      main = paste(title_prefix, "by interval"),
      xlab = "Grid position",
      ylab = "Predictor"
    ))
  }

  if (identical(type, "basis")) {
    if (identical(value, "group")) {
      stop("`value = \"group\"` is not available for basis plots.", call. = FALSE)
    }
    map <- selection_map(x, level = "basis", cutoff = cutoff)
    if (nrow(map) == 0L) {
      stop("No basis-expanded predictors are available in this fit.", call. = FALSE)
    }
    value_var <- if (identical(value, "mean")) "mean_feature_frequency" else "max_feature_frequency"
    ylab <- if (identical(value, "mean")) "Mean feature frequency" else "Max feature frequency"
    return(plot_selection_bars(
      values = map[[value_var]],
      labels = map$predictor,
      main = "Basis stability summary",
      ylab = ylab,
      cutoff = cutoff,
      ...
    ))
  }

  if (identical(type, "group")) {
    map <- selection_map(x, level = "group", cutoff = cutoff)
    value_var <- switch(
      value,
      group = "group_frequency",
      mean = "mean_feature_frequency",
      max = "max_feature_frequency"
    )
    ylab <- switch(
      value,
      group = "Group frequency",
      mean = "Mean feature frequency",
      max = "Max feature frequency"
    )
    labels <- if ("interval_label" %in% names(map) && all(!is.na(map$interval_label))) {
      map$interval_label
    } else {
      map$group
    }
    return(plot_selection_bars(
      values = map[[value_var]],
      labels = labels,
      main = "Group stability selection",
      ylab = ylab,
      cutoff = cutoff,
      ...
    ))
  }

  map <- selection_map(x, level = "feature", cutoff = cutoff)
  plot_selection_bars(
    values = map$feature_frequency,
    labels = map$feature,
    main = "Feature stability selection",
    ylab = "Feature frequency",
    cutoff = cutoff,
    ...
  )
}

#' @export
#' @rdname plot.fda_selection
plot.selectboost_fda_result <- function(x,
                                        type = c("feature", "group", "basis"),
                                        value = c("max", "mean"),
                                        palette = selection_palette(),
                                        show_legend = TRUE,
                                        legend_title = NULL,
                                        legend_n_ticks = 3L,
                                        legend_digits = 2L,
                                        legend_cex = 0.75,
                                        c0 = NULL,
                                        ...) {
  type <- match.arg(type)
  value <- match.arg(value)

  if (identical(type, "basis")) {
    map <- selection_map(x, level = "basis", c0 = c0)
    if (nrow(map) == 0L) {
      stop("No basis-expanded predictors are available in this fit.", call. = FALSE)
    }
    value_var <- if (identical(value, "mean")) "mean_selection" else "max_selection"
    ylab <- if (identical(value, "mean")) "Mean selection proportion" else "Max selection proportion"
    legend_title <- legend_title %||% ylab
    if (is.null(c0) && "c0" %in% names(map)) {
      return(plot_selection_heatmap(
        map = map,
        row_var = "predictor",
        col_var = "c0",
        value_var = value_var,
        palette = palette,
        show_legend = show_legend,
        legend_title = legend_title,
        legend_n_ticks = legend_n_ticks,
        legend_digits = legend_digits,
        legend_cex = legend_cex,
        main = "Basis selection by c0",
        xlab = "c0",
        ylab = "Predictor"
      ))
    }
    return(plot_selection_bars(
      values = map[[value_var]],
      labels = map$predictor,
      main = paste("Basis SelectBoost summary", if (!is.null(c0)) paste0("(", c0, ")")),
      ylab = ylab,
      ...
    ))
  }

  if (identical(type, "group")) {
    map <- selection_map(x, level = "group", c0 = c0)
    value_var <- if (identical(value, "mean")) "mean_selection" else "max_selection"
    ylab <- if (identical(value, "mean")) "Mean selection proportion" else "Max selection proportion"
    legend_title <- legend_title %||% ylab
    if (is.null(c0) && "c0" %in% names(map)) {
      return(plot_selection_heatmap(
        map = map,
        row_var = "group",
        col_var = "c0",
        value_var = value_var,
        palette = palette,
        show_legend = show_legend,
        legend_title = legend_title,
        legend_n_ticks = legend_n_ticks,
        legend_digits = legend_digits,
        legend_cex = legend_cex,
        main = "Group selection by c0",
        xlab = "c0",
        ylab = "Group"
      ))
    }
    labels <- if ("interval_label" %in% names(map) && all(!is.na(map$interval_label))) {
      map$interval_label
    } else {
      map$group
    }
    return(plot_selection_bars(
      values = map[[value_var]],
      labels = labels,
      main = paste("Group SelectBoost summary", if (!is.null(c0)) paste0("(", c0, ")")),
      ylab = ylab,
      ...
    ))
  }

  map <- selection_map(x, level = "feature", c0 = c0)
  if (is.null(c0) && "c0" %in% names(map)) {
    legend_title <- legend_title %||% "Selection proportion"
    return(plot_selection_heatmap(
      map = map,
      row_var = "feature",
      col_var = "c0",
      value_var = "selection",
      palette = palette,
      show_legend = show_legend,
      legend_title = legend_title,
      legend_n_ticks = legend_n_ticks,
      legend_digits = legend_digits,
      legend_cex = legend_cex,
      main = "Feature selection by c0",
      xlab = "c0",
      ylab = "Feature"
    ))
  }

  plot_selection_bars(
    values = map$selection,
    labels = map$feature,
    main = paste("Feature SelectBoost summary", if (!is.null(c0)) paste0("(", c0, ")")),
    ylab = "Selection proportion",
    ...
  )
}
