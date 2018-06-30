library(RPostgreSQL)
library(plotly)
library(pool)
library(DT)
library(DBI)


#https://www.cybertec-postgresql.com/en/visualizing-data-in-postgresql-with-r-shiny/
#https://shiny.rstudio.com/articles/pool-basics.html

pool <- dbPool(
  drv = dbDriver("PostgreSQL", max.con = 100),
  dbname="election", 
  host="10.0.0.13",
  port="5432",
  user = "election", 
  password="prox100",
  idleTimeout = 3600000
)


query <- "SELECT year FROM election"
choices <- dbGetQuery(pool, query)