##split up the table to store in a normalized database

library(tidyverse)
library(rvest)
library(XML)

source_dat <- read_csv("~/Projects/Election/Data/cleaned.csv")

### Create Party Table

Party_data <- source_dat %>%
  select(Pres_Party, Loser_Party) %>%
  gather(key = Candidate, value = abbreviation)
  
Party_data <- Party_data %>% select(abbreviation) %>%
  distinct()  #https://dplyr.tidyverse.org/reference/distinct.html

#https://dplyr.tidyverse.org/reference/tally.html
Party_data$party_id <- c(1:tally(Party_data)[[1]])
Party_data <- Party_data %>% mutate(abbreviation = replace(abbreviation, abbreviation == "Coalition", "C"))

## Scrape the party key from archives.gov

#https://www.archives.gov/federal-register/electoral-college/votes/index.html
#http://www.cse.chalmers.se/~chrdimi/downloads/web/getting_web_data_r4_parsing_xml_html.pdf
url = "https://www.archives.gov/federal-register/electoral-college/votes/index.html"
party_key <- htmlParse((read_html(url))) 

#https://stackoverflow.com/questions/14931499/xpath-expression-to-find-elements-whose-tag-name-contains-name
#https://stackoverflow.com/questions/43207454/extract-text-from-xml-nodeset
block <- getNodeSet(party_key, path='//*[contains(local-name(), "blockquote")]/text()')
#https://stackoverflow.com/questions/14957632/r-xpathapply-on-xmlnodeset-with-xml-package
party_list <- sapply(block, xmlValue)

party_list[9] <- unlist(str_split(party_list[7], pattern = " \\["))[2]
party_list[7] <- unlist(str_split(party_list[7], pattern = " \\["))[1]

party_list <- party_list %>% lapply(str_replace, pattern = "(\r)", "") %>%
  lapply(str_replace, pattern = "(\n)", "") %>%
  lapply(str_replace, pattern = "\\[", "") %>%
  lapply(str_replace, pattern = "\\]", "") %>%
  sapply(str_split, pattern = " =") %>%
  lapply(trimws)

#http://r.789695.n4.nabble.com/Convert-list-of-lists-lt-gt-data-frame-td860048.html
partyDF <- as.tibble(do.call(rbind, party_list))
names(partyDF) <- c("abbreviation", "party_name")
partyDF <- add_row(partyDF, abbreviation = "C", party_name = "Coalition")

Party <- merge(partyDF, Party_data, by = 'abbreviation') %>%
  arrange(party_id) %>%
  select(party_id, abbreviation, party_name)


### Create Candidates Table

Cand_data <- source_dat %>%
  select(President, Loser) %>%
  gather(key = result, value = candidate_name) %>%
  select(candidate_name) %>%
  distinct() %>%
  mutate(candidate_name=replace(candidate_name, is.na(candidate_name), "Horace Greeley")) #special case

Cand_data$candidate_id <- c(1:tally(Cand_data)[[1]])

Candidates <- select(Cand_data, candidate_id, candidate_name)


### Create Party_Election_Cand table
#https://www.reddit.com/r/SQL/comments/8mjrep/postgresqladvice_on_database_plan/
Pres <- source_dat %>%
  select(Election, candidate_name = President, party_name = Pres_Party, votes = Winning_Votes) %>%
  mutate(win = TRUE)
Lose <- source_dat %>%
  select(Election, candidate_name = Loser, party_name = Loser_Party, votes = Losing_Votes) %>%
  mutate(win = FALSE, candidate_name=replace(candidate_name, is.na(candidate_name), "Horace Greeley")) #special case

Party_Election_Cand <- rbind(Pres, Lose)
Party_Election_Cand$Election <- str_sub(Party_Election_Cand$Election, 1, 4)

### Create Election Table

Election <- source_dat %>%
  mutate(year = str_sub(Election, 1, 4), date = Election, total_votes = Total_Votes, 
         majority_votes = Majority_Needed) %>%
  select(year, date, total_votes, majority_votes)


write_csv(Candidates, '~/Projects/Election/Data/FilesToLoad/Candidates.csv')
write_csv(Election, '~/Projects/Election/Data/FilesToLoad/Election.csv')
write_csv(Party, '~/Projects/Election/Data/FilesToLoad/Party.csv')
write_csv(Party_Election_Cand, '~/Projects/Election/Data/FilesToLoad/Party_Election_Cand.csv')
                                       