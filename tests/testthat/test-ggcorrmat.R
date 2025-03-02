
# pearson's r without NAs ------------------------------------------------

test_that(
  desc = "checking ggcorrmat - without NAs - pearson's r",
  code = {
    skip_if_not_installed("ggcorrplot")

    # creating the plot
    set.seed(123)
    p <-
      ggcorrmat(
        data = iris,
        cor.vars.names = "x",
        type = "p",
        title = "Iris dataset",
        subtitle = "By Edgar Anderson",
        sig.level = 0.001,
        matrix.type = "full",
        p.adjust.method = "fdr",
        colors = NULL,
        k = 4,
        ggcorrplot.args = list(
          lab_col = "white",
          pch.col = "white"
        )
      )

    # checking legend title
    pb <- ggplot2::ggplot_build(p)
    p_legend_title <- pb$plot$plot_env$legend.title

    # check data
    set.seed(123)
    expect_snapshot(pb$data)
    expect_snapshot(list(p$labels, pb$plot$plot_env$legend.title))
  }
)

# robust r without NAs ---------------------------------------------------

test_that(
  desc = "checking ggcorrmat - without NAs - robust r",
  code = {
    skip_if_not_installed("ggcorrplot")

    # creating the plot
    set.seed(123)
    p <-
      ggcorrmat(
        data = anscombe,
        type = "r",
        partial = TRUE,
        cor.vars.names = names(anscombe)
      )

    pb <- ggplot2::ggplot_build(p)

    # check data
    set.seed(123)
    expect_snapshot(pb$data)
    expect_snapshot(list(p$labels, pb$plot$plot_env$legend.title))
  }
)

# robust r with NAs ---------------------------------------------------

test_that(
  desc = "checking ggcorrmat - with NAs - robust r - partial",
  code = {
    skip_if_not_installed("ggcorrplot")
    skip_on_ci()

    # creating the plot
    set.seed(123)
    p <-
      ggcorrmat(
        data = ggplot2::msleep,
        type = "r",
        sig.level = 0.01,
        partial = TRUE,
        p.adjust.method = "hommel",
        matrix.type = "upper"
      ) +
      labs(caption = NULL)

    # checking legend title
    pb <- ggplot2::ggplot_build(p)

    # check data
    set.seed(123)
    expect_snapshot(pb$data)
    expect_snapshot(list(p$labels, pb$plot$plot_env$legend.title))
  }
)

# spearman's rho with NAs ---------------------------------------------------

test_that(
  desc = "checking ggcorrmat - with NAs - spearman's rho",
  code = {
    skip_if_not_installed("ggcorrplot")

    # creating the plot
    set.seed(123)
    p <-
      suppressWarnings(ggcorrmat(
        data = ggplot2::msleep,
        cor.vars = sleep_total:awake,
        cor.vars.names = "sleep_total",
        type = "np",
        sig.level = 0.01,
        matrix.type = "full",
        p.adjust.method = "hommel",
        caption.default = FALSE,
        colors = NULL,
        package = "wesanderson",
        palette = "Rushmore1"
      ))

    # checking legend title
    pb <- ggplot2::ggplot_build(p)

    # check data
    set.seed(123)
    expect_snapshot(pb$data)
    expect_snapshot(list(p$labels, pb$plot$plot_env$legend.title))
  }
)

# Bayesian pearson (with NA) ---------------------------------------------------

test_that(
  desc = "checking Bayesian pearson (with NA)",
  code = {
    skip_if_not_installed("ggcorrplot")

    set.seed(123)
    p <- suppressWarnings(ggcorrmat(dplyr::select(ggplot2::msleep, brainwt, bodywt),
      type = "bayes"
    ))
    pb <- ggplot2::ggplot_build(p)

    # check data
    set.seed(123)
    # expect_snapshot(pb$data)
    expect_snapshot(list(p$labels, pb$plot$plot_env$legend.title))
  }
)

# checking all dataframe outputs -------------------------------------------

test_that(
  desc = "checking all dataframe outputs",
  code = {
    skip_on_os("windows")
    skip_on_cran()
    options(tibble.width = Inf)
    skip_on_ci()
    skip_on_travis()

    set.seed(123)
    expect_snapshot(suppressWarnings(purrr::pmap(
      .l = list(
        data = list(dplyr::select(ggplot2::msleep, brainwt, sleep_rem, bodywt)),
        type = list("p", "p", "np", "np", "r", "r", "bf", "bayes"),
        output = list("dataframe"),
        partial = list(TRUE, FALSE, TRUE, FALSE, TRUE, FALSE, TRUE, FALSE)
      ),
      .f = ggcorrmat
    )))
  }
)
