#Load required libraries
rm(list = ls())

lib_vec <- c("stringr", "httr", "jsonlite", "xml2","svDialogs", "readxl","openxlsx", "httr", "rio")

for(lib in lib_vec){
  if(!require(lib, character.only = T)){
    install.packages(lib)
  }
  library(lib, character.only = T)
}

#Kobo Info api
kobo_data_api <- "https://kf.kobotoolbox.org/assets"

user_name <- dlg_input(message =  "Enter Kobo User Name:")$res
user_password <- dlg_input(message =  "Enter Kobo User Password:")$res

#Pull infor
data_inf  <- GET(kobo_data_api, authenticate(user =  user_name,password =  user_password,type = "basic"))

#Extract Content
data_content_txt <- httr::content(data_inf, as = "text")
data_content_json <- fromJSON(data_content_txt, flatten = TRUE)

form_id_string <-  data_content_json$results$deployment__identifier
form_id_string <- form_id_string[!is.na(form_id_string)]
form_id_pattern = "(?<=/)[A-Za-z0-9_]{2,50}$"

#Extract form IDs and save them in a character vector
form_id_vec <- str_extract(form_id_string, pattern = form_id_pattern )


base_url = "https://kc.kobotoolbox.org/"
username = paste0(user_name, "/reports/")
export = "/export.xlsx"

url_vectors <- c()
for(form in form_id_vec){
  url_vectors <- c(url_vectors, paste0(base_url, username, form, export))
}

###############################################################################################################################################
main_df_list <- list()
for(proj in url_vectors){
  tryCatch({
    
    assign(proj, httr::GET(proj, write_disk(paste0(str_extract(proj, pattern = form_id_pattern ),".xlsx"), overwrite = TRUE)))
    
    main_df_list[[str_extract(proj, pattern = "(?<=/)[A-Za-z0-9_]{2,50}(?=/export\\.xlsx$)")]] <- import_list(paste0(str_extract(proj, pattern = form_id_pattern ),".xlsx"))
  },
  error= function(cond){
    print("Data is yet to be submitted")
    return(NULL)
  }
  
  
  )
  
}


#This is list of lists of dataframes based on the number of projects
main_df_list


# Saving into google drive






