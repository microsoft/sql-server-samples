####################################################################################################
## Title: Telco Customer Churn
## Description: Data Exploration and Visualization
## Author: Microsoft
####################################################################################################

library(shiny)
library(leaflet)
library(jsonlite)
library(dplyr)
library(ggplot2)

## Load data from SQL
# cdrDF <- rxImport(inData = cdrSQL)

## Load data from local
cdrFile <- file.path(wd, "Data", "edw_cdr.csv")
cdrDF <- read.csv(file = cdrFile, header = TRUE, sep = ",")

latlonFile <- file.path(wd, "Data", "state_latlon.csv")
latlonDF <- read.csv(file = latlonFile, header = TRUE, sep = ",")


data <- cdrDF %>%
        group_by(state) %>%
        summarise(complaintsbystate = sum(as.numeric(numberofcomplaints)),
                  churnbystate = sum(as.numeric(churn))) %>%
        mutate(lab = paste0("<center>", "state,", state, ": ", "<br>",
                            "complaintsbystate,", complaintsbystate, "<br>",
                            "churnbystate,", churnbystate, "</center>")) %>%
        left_join(cdrDF, by = "state") %>%
        left_join(latlonDF, by = "state")

ui <- fluidPage(
  tags$style(HTML("
                  @import url('https://fonts.googleapis.com/css?family=Poppins');

                  body {

                  font-family: 'Poppins', 'Lucida Grande', Verdana, Lucida, Helvetica, Arial, Calibri, sans-serif;
                  color: rgb(0,0,0);
                  background-color: #d2d2d2;
                  }
                  ")),

  titlePanel("Telco Customer Churn"),

  # Sidebar with a slider input for number of bins
  sidebarLayout(
    sidebarPanel(
      sliderInput("sc", "Scale size of circles (also redraws map to show only the last added state)",
                  min = 0.5, max = 5, value = 1, step = 0.1),
      p(),
      selectInput("state", "Select a state to add to the map",
                  choices = c("", data$state), selected = "",
                  size = , selectize = FALSE),
      actionButton("clear1", "Clear all states"),
      p(),
      p("Proportion of customer churn"),
      plotOutput("MyPlot1", height = "200px"),
      p(),
      p("Impact of education on churn"),
      plotOutput("MyPlot2", height = "200px"),
      p(),
      p("Impact of call failure rate on churn"),
      plotOutput("MyPlot3", height = "200px"),
      h2("About"),
      HTML("<p>Created by Fang Zhou with R and Shiny leaflet. R users can download the
           cleaned and tidy call detail record data from <a href = 'https://github.com/Microsoft/sql-server-samples/tree/master/samples/features/r-services/Telco%20Customer%20Churn'>
           https://github.com/Microsoft/sql-server-samples/tree/master/samples/features/r-services/Telco%20Customer%20Churn</a>.
           The latitute and longitute for each USA state can be found from <a href = 'http://dev.maxmind.com/geoip/legacy/codes/state_latlon/'>
           http://dev.maxmind.com/geoip/legacy/codes/state_latlon/</a>.")
      ),


    mainPanel(
      leafletOutput("MyMap", height = 1000)

    )
      )
    )

server <- function(input, output, session) {

    the_data_state <- reactive({
        tmp <- data %>%
      filter(state == input$state)

        if (input$state != "") {
            thecol <- data.frame(data)[data$state == input$state, "colour"]
        } else {
            tmp <- data[1,]
            thecol <- NULL

        }

        return(list(df = tmp, thecol = thecol))
    })

    output$MyMap <- renderLeaflet({
        leaflet() %>%
      addProviderTiles("Stamen.Watercolor") %>%
      addProviderTiles("Stamen.TonerLabels") %>%
      fitBounds(-120, 30, -60, 50)
    })

    observe({
        leafletProxy("MyMap", data = the_data_state()$df) %>%
      addCircleMarkers( ~ longitude,
                       ~ latitude,
                       color = the_data_state()$thecol,
                       radius = ~churnbystate * 0.1 * input$sc,
                       popup = ~lab)
    })

    observe({
        x <- input$clear1
        updateSelectInput(session, "state", selected = "")
        leafletProxy("MyMap") %>% clearMarkers()
    })

    observe({
        x <- input$sc
        leafletProxy("MyMap") %>% clearMarkers()
    })


    output$MyPlot1 <- renderPlot({
        cdrDF %>%
      ggplot(aes(x = factor(1), fill = factor(churn))) +
      geom_bar(width = 1) +
      coord_polar(theta = "y") +
      theme_minimal()
    })

    output$MyPlot2 <- renderPlot({
        cdrDF %>%
      group_by(month, education) %>%
      summarize(countofchurn = sum(as.numeric(churn))) %>%
      ggplot(aes(x = month, y = countofchurn,
                 group = education, fill = education)) +
      geom_bar(stat = "identity", position = position_dodge()) +
      labs(x = "month", y = "Counts of churn") +
      theme_minimal()
    })

    output$MyPlot3 <- renderPlot({
        data %>%
      group_by(month, callfailurerate) %>%
      summarize(countofchurn = sum(as.numeric(churn))) %>%
      ggplot(aes(x = month, y = countofchurn,
                 group = factor(callfailurerate), fill = factor(callfailurerate))) +
      geom_bar(stat = "identity", position = position_dodge()) +
      labs(x = "month", y = "Counts of churn") +
      theme_minimal()
    })
}

