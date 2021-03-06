#load libraries
library(dplyr)
library(tidyr)

#read in season4 trait data tall format
season4tall <- read.csv(file = "~/phenophasebbn/season_4_tall_2020-05-08T203345.csv")

# read in season6 trait data in tall format
# this will need to be transfered via iRODS
# Future code should have a shell script to
# pull data from cyverse data store into container
# this could be accomplished by making data public
# and using wget.

season6tall <- read.csv(file = "~/phenophasebbn/season_6_2020-06-25T204820.csv")

#convert to tibble
season4tall <- as_tibble(season4tall)

season6tall <- as_tibble(season6tall)

# make wide format
s4wide <- season4tall %>%
  mutate(row = row_number()) %>%
  pivot_wider(id_cols = c(row, lat, lon, date,
    range, column, cultivar, treatment),
  names_from = trait, values_from = value) %>%
  select(-row)

# find drought treatments
drought <- as.vector(unique(s4wide$treatment)[2:3])

# filter s4wide data frame with not in

s6wide <- season6tall %>%
mutate(row = row_number()) %>%
pivot_wider(id_cols = c(row, lat, lon, date, range, column,
  cultivar, treatment),
names_from = trait, values_from = value) %>%
  select(-row)



# ================================================================
# Further data Cleaning Starts Here
# ================================================================


# ================================================================
# 1) cut traits and environmental variables
# ================================================================

#make a vector of colnames to remove; lodging_present has no values, drop it
data2cut <- c("sitename", "treatment", "trait_description", "method_name",
"units", "year", "station_number", "surface_temperature", "lodging_present")

#Note: future network versions should include time in a dynamic BBN

#subset data with columns removed
s4_df <- as.data.frame(s4wide[, !(colnames(s4wide) %in% data2cut)])

#subset data with columns removed
s6_df <- as.data.frame(s6wide[, !(colnames(s6wide) %in% data2cut)])


# ================================================================
# 2) filter by cultivars in all data sets (including genomic)
# ================================================================
all_cult <- read.csv(file = "~/phenophasebbn/cultivar_look_up_2020-05-22.csv")

# convert to dataframe
cult_df <- as.data.frame(all_cult)

# first column is a character vector of all cultivars present across all seasons
# (0 = not in season, 1 = in season; therefore rowsum = 4 is in all)
cultivars4net <- cult_df[rowSums(cult_df[, 2:5]) == 4, 1]

#filter season4 dataset by cultivars in all datasets
s4filtered <- as.data.frame(s4_df[s4_df$cultivar %in% cultivars4net, ])
s6filtered <- as.data.frame(s6_df[s6_df$cultivar %in% cultivars4net, ])
#remove all na canopy heights
s4_df2 <- s4filtered[!is.na(s4filtered$canopy_height), ]
s6_df2 <- s6filtered[!is.na(s6filtered$canopy_height), ]
#convert season 4 dataframe to tibble
s4_tib <- as_tibble(s4_df2)
s6_tib <- as_tibble(s6_df2)
# ================================================================
# 3) Join with weather data
# ================================================================

#read in weather data
season4weather <- read.csv("~/phenophasebbn/season_4_weather_gdd2020-05-08T203153.csv")
season6weather <- read.csv("~/phenophasebbn/weather_station_gdd_season_6_2020-06-25T205200.csv")

#left join weather and
s4combined <- as.data.frame(left_join(s4_tib, season4weather, by = "date"))
s6combined <- as.data.frame(left_join(s6_tib, season6weather, by = "date"))


#write out tsv file
write.table(s4combined, file = "~/phenophasebbn/s4combined.txt",
  quote = FALSE, sep = "\t")

write.table(s6combined, file = "~/phenophasebbn/s6combined.txt",
  quote = FALSE, sep = "\t")
