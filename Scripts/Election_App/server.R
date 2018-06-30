function(input, output, session) {
  output$table <- DT::renderDataTable({
    query <- sqlInterpolate(ANSI(), 'SELECT * FROM party_election_cand WHERE "party_election_cand"."Election" = ?year;',
                            year = input$year)
    outp <- dbGetQuery(pool, query)
    ret <- DT::datatable(outp)
    return(ret)
  })
  dat <- reactive({
    query <- sqlInterpolate(ANSI(), 'SELECT * FROM party_election_cand WHERE "party_election_cand"."Election" = ?year;',
                            year = input$year)
    dbGetQuery(pool, query)
  })
  output$plot <- renderPlot({
    
    ggplot(dat(), aes(x = candidate_name, y = votes)) + geom_col(fill = "lightblue") +
      labs(title = "Votes for Top Candidates in Election") + xlab(label = "Candidate") + ylab(label = "Votes")
  })
}