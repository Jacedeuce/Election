library(tidyverse)


#https://stackoverflow.com/questions/22647591/table-of-contents-index-inside-r-file
# 1 http://r.789695.n4.nabble.com/multiple-values-in-one-column-td4537588.html
# 2 https://stackoverflow.com/questions/34437534/nested-apply-function
#https://stat.ethz.ch/R-manual/R-devel/library/base/html/trimws.html
#https://stackoverflow.com/questions/43662457/convert-list-of-vectors-to-data-frame/43662485

dat <- read_csv("~/Projects/Election/Data/table.csv")

dat <- dat %>%
  remove_missing()


# 1 -----------------------------------------------------------------------
get_party <- function(cell){
  x<-unlist(strsplit(str_replace(cell, "\\]", ""), "\\["))
  return(c(x[1], x[2]))
}

get_winner <- function(cell){
  x<-unlist(strsplit(as.character(cell), ","))
  return(x[1]) 
}

get_loser <- function(cell){
  x<-unlist(strsplit(as.character(cell), ","))
  return(x[2]) 
}

get_win_votes <- function(cell){
  x<-unlist(strsplit(as.character(cell), ","))
  return(x[3]) 
}

get_lose_votes <- function(cell){
  x<-unlist(strsplit(as.character(cell), ","))
  return(x[4]) 
}

get_total_votes <- function(cell){
  x<-unlist(strsplit(as.character(cell), ","))
  return(x[5]) 
}

strip_votes <- function(cell, num = TRUE){
  x<-unlist(strsplit(cell, ":"))
  if (num == TRUE){
    return(as.numeric(str_trim(x[2], "both")))
  }
  else
    return(x[2])
}

date_converter <- function(cell){
  x <- paste0(as.character(cell), "-11-06")
  return(x)
}

# 2 -----------------------------------------------------------------------
win <- lapply(unlist(lapply(dat$data, get_winner)), get_party)
dfw <- as.data.frame(do.call(rbind, win))
names(dfw) <- c("President", "Pres_Party")

lose <- lapply(unlist(lapply(dat$data, get_loser)), get_party)
dfl <- as.data.frame(do.call(rbind, lose))
names(dfl) <- c("Loser", "Loser_Party")

win_votes <- lapply(unlist(lapply(dat$data, get_win_votes)), strip_votes)
dfwv <- as.data.frame(do.call(rbind, win_votes))
names(dfwv) <- "Winning_Votes"

lose_votes <- lapply(unlist(lapply(dat$data, get_lose_votes)), strip_votes)
dflv <- as.data.frame(do.call(rbind, lose_votes))
names(dflv) <- "Losing_Votes"

total_votes <- lapply(unlist(lapply(dat$data, get_total_votes)), strip_votes, num = FALSE)
tot_votes <- lapply(strsplit(unlist(total_votes), "/"), str_trim, "both")
dftv <- as.data.frame(do.call(rbind, tot_votes))
dftv <- data.frame(apply(dftv, 2, as.numeric)) # https://stackoverflow.com/questions/18503177/r-apply-function-on-specific-dataframe-columns
names(dftv) <- c("Total_Votes", "Majority_Needed")

Election <- as.data.frame(as.Date(date_converter(dat$year)))
names(Election) <- "Election"
df <- cbind(Election, dfw, dfwv, dfl, dflv, dftv)

# special case ----------------------------------------------------------
#http://www.u-s-history.com/pages/h215.html
df[df$Election == "1872-11-06", "Loser"] <- "Thomas A. Hendricks"
df[df$Election == "1872-11-06", "Losing_Votes"] <- 42

write_csv(df, '~/Projects/Election/Data/cleaned.csv')


## HOVERTEXT : https://stackoverflow.com/questions/27965931/tooltip-when-you-mouseover-a-ggplot-on-shiny
p <- ggplot(df %>% 
              mutate(win_perc = Winning_Votes/Total_Votes, 
                     lose_perc = Losing_Votes/Total_Votes), 
            aes(x = Election, y = win_perc)) + 
  geom_point() + 
  geom_line()
#geom_line(aes(x = Election, y = lose_perc)) + 
scale_x_date(date_breaks = "4 years", date_labels = "%Y", limits = c(as.Date("1788-01-01"), as.Date("1996-01-01")))
p
