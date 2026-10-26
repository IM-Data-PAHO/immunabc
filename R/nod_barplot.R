#' (No)minal (D)ropout Bar Plot
#'
#' @param data Dataframe formatted from the output of the \code{immunabc::nod_dropout} function.
#' @param within_ADM1 When analyzing data at the "ADM2" level, this optional character vector lets you specify one or several "ADM1" to filter. Default is \code{NULL}, which means no filtering by "ADM1".
#' @param order Organizes the bars based on three options: "alpha", "desc" or "asc", default is "alpha"
#'
#' @return A ggplot object representing the bar plot.
#'
#' @import dplyr
#' @import lubridate
#' @import tidyr
#' @import ggplot2
#' @export
nod_barplot <- function(data, order = "alpha", within_ADM1 = NULL) {

  # TODO: validate dataframe

  .validate_character(within_ADM1, "within_ADM1", min_len = 1)
  .validate_character(order, "order", exp_len = 1)

  # This function produces a dropout plot so we filter the completeness data
  nominal_dropout_data <- data %>%
    filter(indicator == "dropout")

  # detect geo level
  ADM_detected <- .detect_geo_level(data)
  geo_column <- paste0("ADM", ADM_detected, "_residence")

  # Selects the name of the x axis depending on the level of disgregation in data
  if(ADM_detected == 2){
    x_var <- geo_column
  } else if (ADM_detected == 1){
    x_var <- geo_column
  } else {
    x_var <- "dropout"
    nominal_dropout_data <- nominal_dropout_data %>%
      mutate(indicator = ifelse(indicator == "dropout", "country", indicator))
  }
  # Converts xvar into a symbol
  x_var <- sym(x_var)

  # prepare dataframe for plot filtering WITHIN_ADM1
  nominal_dropout_data <- nominal_dropout_data %>%
    filter(if(!is.null(within_ADM1)) {ADM1 %in% within_ADM1} else {TRUE})

  # Organizes the plot based on alpha asc or desc
  if(order == "alpha") {
    order_vector <- nominal_dropout_data %>%
      arrange(!!x_var) %>%
      pull(!!x_var)
  } else if(order == "asc"){
    order_vector <- nominal_dropout_data %>%
      arrange(percent) %>%
      pull(!!x_var)
  } else if(order == "desc"){
    order_vector <- nominal_dropout_data %>%
      arrange(desc(percent)) %>%
      pull(!!x_var)
  }

  #completes the order in the df
  nominal_dropout_data <- nominal_dropout_data %>%
    mutate(x_label = factor(!!x_var, levels=order_vector))

  "Sets title for x axis and y axis"
  plot_title <- ifelse(x_var == "dropout", "Dropout plot, country", paste0("Dropout plot by ", x_var, ", country"))
  plot_x <- ifelse(x_var == "dropout", "", x_var)

  #Does simple plot
  nod_barplot <- ggplot(data =  nominal_dropout_data, aes(x=x_label, y = percent))+
    geom_bar(stat="identity", position="dodge")+
    coord_flip()+
    labs(title=plot_title, y="Dropout rate (%)", x= plot_x)+
    theme_classic()+
    # Modifies the fill of the bar to a single color
    aes(fill = "your_color") +
    scale_fill_manual(values = c("your_color" = "#fee090")) +
    guides(fill = "none") +
    # Adds a horizontal line at 5% to show what an arbitrary maximum should be
    geom_hline(yintercept = 5, color = "#b35806", linetype = "dashed", linewidth = 1) +
    # Adds a label for the horizontal line
    annotate("text", x = Inf, y = 5, label = "(5%)",
             vjust = -1, hjust = 1.1, color = "#b35806") +
    # Modifies the labels and adds a title
    labs(title = "Nominal dropout rate") +
    # Modifies the y axis to be fixed to 0-100 to show a clearer scale for dropout
    scale_y_continuous(limits=c(0,100))


  # Returns the dropout bar plot
  return(nod_barplot)
}

