# # Processes data download from tiger website
# https://www2.census.gov/geo/tiger/TIGER2020/ROADS/


# libraries
library(bea.R) # Using Data from Bureau of Economic Analyis
library(rvest)
library(tools)
library(sf) # zip and unzip files
library(fs) # file systems, allows the usage of file_create()
library("stringr") # allows the use of "left" and "right" string manipulations
library(tidyverse) # allows the usage of left_join


# Function name is 
get_county_list_road_data <- function(enable_data_proc) {
    if(!file.exists("get_county_list_road_data.csv")) {

      
      
      ### Most updated code change - retrieving data from 2019 data
      ### code that is run is only within this function for adhoc fix
        enable_data_proc = TRUE
        html <- read_html("https://www2.census.gov/geo/tiger/TIGER2014/ROADS/")
        # html <- read_html("https://www2.census.gov/geo/tiger/TIGER2019/ROADS/")
        # html <- read_html("https://www2.census.gov/geo/tiger/TIGER2020/ROADS/")

        tiger_county_list <- html %>% html_element("table") %>% html_table()

        print(nrow(tiger_county_list)) # 3235 rows

        df_output <- data.frame('fips', 'county_zip_file_name', 'roads_length_m', 'intersections')
        ## there is no data to be entered in the line below
        # df[ , empty_cols] <- NA
        print(head(tiger_county_list, 3))
        print(tail(tiger_county_list, 3))

        # for each row in tiger_county_list, add a new row for df
        # 4 to nrow(tiger_county_list)-1 filters out empty row entries
        # for(i in 3:6){
        # subtracting 89 more to account only 56000 and before aka 50 states of usa
        for(i in 3:(nrow(tiger_county_list) - 1 - 89)){
        # for(i in 3:4){

            # returns column of zip file names found in the US Census Tiger data
            print("tiger_county_list[i,2]")
            print(tiger_county_list[i,2])
            zip_file_name <- tiger_county_list[i,2]
            fips <- str_sub(zip_file_name, 9, 13)

            # Set up new class to handle populating road lengths and number of intersections
            print("zip_file_name")
            print(zip_file_name)
            print("enable_data_proc")
            print(enable_data_proc)
            temp <- get_county_road_data(zip_file_name, enable_data_proc)
            print("temp")
            print(temp)
            print("names(df_out)")
            print(names(df_output))

            # fips and file name stored into the rows
            df_output[nrow(df_output) + 1,] <- c(fips, zip_file_name, temp[1], temp[2])
        }
        
        # get rid of unnecessary first row
        df_output <- df_output[-1,] # removing unnecessary row

        # if bottom is TRUE, process downloaded zip files
        if(enable_data_proc) {
            # print(tail(df_out))
            colnames(df_output)  <- c("fips', 'county_zip_file_name', 'roads_length', 'intersections")
            write.csv(df_output,".\\get_county_list_road_data.csv", row.names = FALSE)
        }
  
        
        
        
        
        ### ADHOC FIX ENDS HERE
        
        return(df_output)

        
        # for(i in 3:3){
        #     a <- tiger_county_list[i,2] # returns column of zip file names found in the .  US Census Tiger data
        #     print(a)
        # }

        # for(i in 3235:3234){
        #   a <- tiger_county_list[i,2] # returns column of zip file names found in the US Census Tiger data
        #   print(a)
        # }

        # dataframe was considered in containin county id per each county. using out() instead if possible
        # df <- data.frame(first_column, second_column)
        
        # tiger_county_list <- data.frame("X.fips_county.", "X.county_zip_file_name.")
        # colnames(tiger_county_list)  <- c("fips_county", "county_zip_file_name")

        # print(tiger_county_list)
        
        # # get rid of unnecessary first row
        # df <- df[-1,] # removing unnecessary row
        # # write.csv(df,".\\get_list_of_county_from_tiger.csv", row.names = FALSE)

        # # add a column to df_lj to house total length and intersections
        # # df[ , 'roads_length', 'intersections'] <- NA
        # empty_cols <- c('roads_length', 'intersections')
        # ## there is no data to be entered in the line below
        # # df[ , empty_cols] <- NA


    }
    else {
        # read in cvs file to append additional columns
        df <- read.csv(".\\get_county_list_road_data.csv", header=TRUE, stringsAsFactors=FALSE)

        return(df)
    }
}

# Function name is 
get_county_road_data <- function(zip_file_name, enable_data_proc) {
    
    # Set naming string variables
  shapefile_website_text <- "https://www2.census.gov/geo/tiger/TIGER2014/ROADS/"
  # shapefile_website_text <- "https://www2.census.gov/geo/tiger/TIGER2019/ROADS/"
  # shapefile_website_text <- "https://www2.census.gov/geo/tiger/TIGER2020/ROADS/"
    origin_website_zip_file_link <- paste(shapefile_website_text, zip_file_name, sep = "")
    zip_file_name_converted_to_shp <- paste(file_path_sans_ext(zip_file_name), ".shp", sep="") # shp and shx files must be used in tandem
    zip_file_name_converted_to_shx <- paste(file_path_sans_ext(zip_file_name), ".shx", sep="") # file_path_sans_ext(a) removes extensions from file names
    zip_file_name_converted_to_dbf <- paste(file_path_sans_ext(zip_file_name), ".dbf", sep="") # file_path_sans_ext(a) removes extensions from file names

    # If file doesn't already exist then bring in & create file
    if(!file.exists(zip_file_name_converted_to_shp)) {
        # destination_zip_file_directory <-  paste(download_directory, a, sep = "")
        # Extrapolate file level directory information for each row found from US Census Tiger data
        temp <- tempfile()
        download.file(origin_website_zip_file_link, destfile = temp)

        shp_file_from_zip <- unzip(temp, zip_file_name_converted_to_shp, list = FALSE)
        shx_file_from_zip <- unzip(temp, zip_file_name_converted_to_shx, list = FALSE)
        dbf_file_from_zip <- unzip(temp, zip_file_name_converted_to_dbf, list = FALSE)

        shp_file <- file_create(shp_file_from_zip)
        file_create(shx_file_from_zip)
        file_create(dbf_file_from_zip)
    }


    # if bottom is TRUE, process downloaded zip files
    if(enable_data_proc) {
        ### Retrieve the shp_file that was saved above and read that into boundary variable
        # I have no idea why the naming standard has the users use the term "HARV" but here we are
        # road_boundary_HARV <- st_read(shp_file)

        # additional documentation on st_read found in the link below
        ## https://rdrr.io/cran/tigris/src/R/helpers.R
        # road_boundary_HARV <- st_read(zip_file_name_converted_to_shp, quiet = TRUE, stringsAsFactors = FALSE)
        road_boundary_HARV <- st_read(zip_file_name_converted_to_shp)

        # filtering out items that are national and state highways
        ## https://www.statology.org/dplyr-filter-not-in/
        # MFTCC Codes are found in the link below
        ## https://www2.census.gov/geo/pdfs/reference/mtfccs2022.pdf
        # road_boundary_HARV = road_boundary_HARV %>% filter(!MTFCC %in% c('S1100', 'S1200'))
        #### instead of filtering out national and state highways, filtering only for local and footpath roads
        road_boundary_HARV = road_boundary_HARV %>% filter(MTFCC %in% c('S1400', 'S1710'))
    
        sd = st_sfc(geometry=road_boundary_HARV$geometry, crs="+proj=longlat +datum=NAD83 +no_defs")

        # sd = st_sfc(geometry=road_boundary_HARV$geometry, crs=4326)

        # http://walker-data.com/umich-workshop/spatial-analysis/slides/#29
        ## fl_projected <- st_transform(fl_counties, crs = 3086)

        
        # # Verify the calculation of lengths and intersections within the shapefile
        # st_area(sd) # this returns only 0 because shapefile only includes the vectors of the roads
        attributes(sd)
        # st_intersects(sd) # shows number of intersects

        # # https://cengel.github.io/R-spatial/spatialops.html
        # todo: have a 2d dataframe to iterate through in order to gather information
        stint <- st_intersects(sd)

        total_intersects = 0
        for(i in 1:nrow(stint)) {
            for(j in 1:lengths(stint[i])) {
                # if the intersection occurs with a road already considered, skip
                # if the intersections occurs with new roads, increment total_intersects
                if (stint[[i]][j] > i){
                    total_intersects = total_intersects + 1
                }
            }
        }
        roads_length <- sum(st_length(sd)) # - shows distance in meters
        intersections <- total_intersects

        return(c(as.numeric(roads_length), intersections))

    }
}
