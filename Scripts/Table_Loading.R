## create tables
library(RPostgreSQL)
library(tidyverse)
library(DBI)


#https://stackoverflow.com/questions/42428190/rpostgresql-loading-multiple-csv-files-into-an-postgresql-table
#https://claudiavitolo.com/2012/07/05/writing-tables-into-a-postgresql-database-using-r/

Files <- list.files("/home/jason/Projects/Election/Data/FilesToLoad", pattern = "*.csv", full.names = TRUE)

CSVs <- lapply(Files, read.csv, stringsAsFactors = FALSE)


psql.connection <- dbConnect(PostgreSQL(), 
                             dbname="election", 
                             host="10.0.0.13",
                             port="5432",
                             user = "election", 
                             password="prox100")

table_names <- c("candidates", "election", "party", "party_election_cand")



tab_stat <-   'CREATE TABLE "election" (
  "year" VARCHAR(4),
  "date" date,
  "total_votes" int4,
  "majority_votes" int4,
  PRIMARY KEY ("year")
);

CREATE TABLE "party_election_cand" (
  "party_id" int2,
  "candidate_id" int2,
  "year" VARCHAR(4),
  "votes" int4,
  "win" bool
);

CREATE INDEX "FK, PK" ON  "party_election_cand" ("party_id", "candidate_id", "year");

CREATE TABLE "candidates" (
  "candidate_id" int2,
  "candidate_name" VARCHAR(50),
  PRIMARY KEY ("candidate_id")
);

CREATE TABLE "party" (
  "party_id" int2,
  "abbreviation" VARCHAR(5),
  "party_name" VARCHAR(50),
  PRIMARY KEY ("party_id")
);'

dbGetQuery(psql.connection, tab_stat)



## Testing ---- 

#postgresqlBuildTableDefinition(psql.connection, "cand", CSVs[[1]], row.names = FALSE)

for(i in 1:length(Files)){
  print(paste("reading table", i))

  if(dbExistsTable(psql.connection,table_names[i])) {dbRemoveTable(psql.connection,table_names[i])}

  dbWriteTable(psql.connection
               # schema and table
               , table_names[i]
               , CSVs[[i]] # to unpack the list correctly
               , append = TRUE # add row to bottom
               , row.names = FALSE
  )

}


