fluidPage(
  sidebarLayout(
    sidebarPanel(
      selectInput("year", "Year:",
                  choices = choices
                  )
    ),
    mainPanel(
      DT::dataTableOutput("table"),
      plotOutput("plot")
    )
  )
)