#' @title Dot plot/chart for labeled numeric data.
#' @name ggdotplotstats
#'
#' @description
#'
#' A dot chart (as described by William S. Cleveland) with statistical details
#' from one-sample test details.
#'
#' @param ... Currently ignored.
#' @param y Label or grouping variable.
#' @param point.args A list of additional aesthetic arguments passed to
#'   `geom_point`.
#' @inheritParams gghistostats
#' @inheritParams ggcoefstats
#'
#' @importFrom dplyr row_number percent_rank pull
#' @importFrom statsExpressions one_sample_test
#'
#' @details For more details, see:
#' \url{https://indrajeetpatil.github.io/ggstatsplot/articles/web_only/ggdotplotstats.html}
#'
#' @seealso \code{\link{grouped_gghistostats}}, \code{\link{gghistostats}},
#'  \code{\link{grouped_ggdotplotstats}}
#'
#' @examples
#' \donttest{
#' # for reproducibility
#' set.seed(123)
#'
#' # plot
#' ggdotplotstats(
#'   data = ggplot2::mpg,
#'   x = cty,
#'   y = manufacturer,
#'   title = "Fuel economy data",
#'   xlab = "city miles per gallon",
#'   caption = substitute(
#'     paste(italic("Source"), ": EPA dataset on http://fueleconomy.gov")
#'   )
#' )
#' }
#' @export

# function body
ggdotplotstats <- function(data,
                           x,
                           y,
                           xlab = NULL,
                           ylab = NULL,
                           title = NULL,
                           subtitle = NULL,
                           caption = NULL,
                           type = "parametric",
                           test.value = 0,
                           bf.prior = 0.707,
                           bf.message = TRUE,
                           effsize.type = "g",
                           conf.level = 0.95,
                           tr = 0.2,
                           k = 2L,
                           results.subtitle = TRUE,
                           point.args = list(
                             color = "black",
                             size = 3,
                             shape = 16
                           ),
                           centrality.plotting = TRUE,
                           centrality.type = type,
                           centrality.line.args = list(
                             color = "blue",
                             size = 1,
                             linetype = "dashed"
                           ),
                           ggplot.component = NULL,
                           ggtheme = ggstatsplot::theme_ggstatsplot(),
                           output = "plot",
                           ...) {

  # convert entered stats type to a standard notation
  type <- ipmisc::stats_type_switch(type)

  # ensure the variables work quoted or unquoted
  c(x, y) %<-% c(rlang::ensym(x), rlang::ensym(y))

  # --------------------------- data preparation ----------------------------

  # creating a dataframe
  data %<>%
    dplyr::select({{ x }}, {{ y }}) %>%
    tidyr::drop_na(.) %>%
    dplyr::mutate({{ y }} := droplevels(as.factor({{ y }}))) %>%
    dplyr::group_by({{ y }}) %>%
    dplyr::summarise({{ x }} := mean({{ x }})) %>%
    dplyr::ungroup(.) %>%
    # rank ordering the data
    dplyr::arrange({{ x }}) %>%
    dplyr::mutate(
      percent_rank = dplyr::percent_rank({{ x }}),
      rank = dplyr::row_number()
    )

  # ================ stats labels ==========================================

  if (isTRUE(results.subtitle)) {
    # preparing the BF message for NULL
    if (isTRUE(bf.message) && type == "parametric") {
      caption_df <- tryCatch(
        statsExpressions::one_sample_test(
          data = data,
          x = {{ x }},
          type = "bayes",
          test.value = test.value,
          bf.prior = bf.prior,
          top.text = caption,
          k = k
        ),
        error = function(e) NULL
      )

      caption <- if (!is.null(caption_df)) caption_df$expression[[1]]
    }

    # preparing the subtitle with statistical results
    subtitle_df <- tryCatch(
      statsExpressions::one_sample_test(
        data = data,
        x = {{ x }},
        type = type,
        test.value = test.value,
        bf.prior = bf.prior,
        effsize.type = effsize.type,
        conf.level = conf.level,
        tr = tr,
        k = k
      ),
      error = function(e) NULL
    )

    subtitle <- if (!is.null(subtitle_df)) subtitle_df$expression[[1]]
  }

  # return early if anything other than plot
  if (output != "plot") {
    return(switch(output,
      "caption" = caption,
      subtitle
    ))
  }

  # ------------------------------ basic plot ----------------------------

  # creating the basic plot
  plot <- ggplot2::ggplot(data, mapping = ggplot2::aes({{ x }}, y = rank)) +
    rlang::exec(ggplot2::geom_point, !!!point.args) +
    ggplot2::scale_y_continuous(
      name = ylab,
      labels = data %>% dplyr::pull({{ y }}),
      breaks = data$rank,
      sec.axis = ggplot2::dup_axis(
        name = "percentile",
        breaks = seq(1, nrow(data), (nrow(data) - 1) / 4),
        labels = 25 * 0:4
      )
    )
  # ---------------- centrality tagging -------------------------------------

  # using custom function for adding labels
  if (isTRUE(centrality.plotting)) {
    plot <- histo_labeller(
      plot,
      x = data %>% dplyr::pull({{ x }}),
      type = ipmisc::stats_type_switch(centrality.type),
      tr = tr,
      k = k,
      centrality.line.args = centrality.line.args
    )
  }

  # ------------------------ annotations and themes -------------------------

  # specifying theme and labels for the final plot
  plot +
    ggplot2::labs(
      x = xlab %||% rlang::as_name(x),
      y = ylab %||% rlang::as_name(y),
      title = title,
      subtitle = subtitle,
      caption = caption
    ) +
    ggtheme +
    ggplot.component
}
