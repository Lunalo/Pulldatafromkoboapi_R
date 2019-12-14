#Load required libraries
rm(list = ls())

lib_vec <- c("stringr", "httr", "jsonlite", "xml2","svDialogs", "readxl","openxlsx", "httr", "rio","DataExplorer")

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


base_url = "https://kc.kobotoolbox.org/"
form_id_string <-  data_content_json$results$url
form_id_string <- form_id_string[!is.na(form_id_string)]
form_id_pattern = "(?<=/assets/)[A-Za-z0-9_]{2,50}"

#Extract form IDs and save them in a character vector
form_id_vec <- str_extract(form_id_string, pattern = form_id_pattern )
form_names <- data_content_json$results$name
form_df <- data.frame(form_names=form_names, form_id = form_id_vec)
username = paste0(user_name, "/reports/")
export = "/export.xlsx"

url_vectors <- c()
for(form in form_id_vec){
  url_vectors <- c(url_vectors, paste0(base_url, username, form, export))
}

###############################################################################################################################################
main_data_list <- list()

for(proj in url_vectors){
  tryCatch({
    
    assign(proj, httr::GET(proj, write_disk(paste0(str_extract(proj, pattern = form_id_pattern ),".xlsx"), overwrite = TRUE)))
    
    main_data_list[[ str_replace_all(as.character(form_df[ form_df$form_id == str_extract(proj, pattern = "(?<=/)[A-Za-z0-9_\\-,]{2,50}(?=/export\\.xlsx$)"), "form_names"]), pattern = " ", "_")]] <- import_list(paste0(str_extract(proj, pattern = form_id_pattern ),".xlsx"))
  },
  error= function(cond){
    print("Data is yet to be submitted")
    return(NULL)
  }
  
  
  )
  
}

kobo_content_list <- list()

#Remember to add checks
kobo_content_list[["main_data_list"]] <- main_data_list
kobo_content_list[["general_content"]] <- data_content_json$results



#Extract number of Forms with Data
number_of_forms_with_data <- function(form_list=NULL){
  tryCatch( {num <- length(form_list)},
            error= function(cond){
              print("use get_data_from_kobo function to pull data before running this function")
            },
            finally = {
              
              if(num==0){
                return("The form_list is blank")
              }else{
                return(num)
              }
              
            }
  )
  
}

extract_forms_online(form_list = kobo_content_list[["main_data_list"]])
extract_forms_online()


#Extract names of Forms with Data
names_of_forms_with_data <- function(form_list=NULL){
  tryCatch( {num <- names(form_list)},
            error= function(cond){
              print("use get_data_from_kobo function to pull data before running this function")
              
            },
            finally = {
              
              if(is.null(num)){
                return("The form_list is blank")
              }else{
                return(num)
              }
              
            }
  )
  
}


names_of_forms_with_data(form_list = kobo_content_list[["main_data_list"]])
names_of_forms_with_data()


#pull user names
kobo_user_name <- function(kobo_content=NULL){
  tryCatch( {usnam <- unique(kobo_content["owner__username"])},
            
            
            error= function(cond){
              print("use get_data_from_kobo function to pull data before running this function")
              return(NULL)
            },
            finally = {
              
              if(is.null(usnam)){
                return("The content Dataframe is blank")
              }else{
                return(usnam)
              }
              
            }
  )
  
}

kobo_user_name(kobo_content = kobo_content_list$general_content)
kobo_user_name()

#Number of surveys per Country
surveys_per_country <- function(kobo_content=NULL){
  library(dplyr)
  country_names <- unlist(kobo_content[,"settings.country"])[names(unlist(kobo_content[,"settings.country"])) %in%c("label")]

  if(is.null(country_names)){
    return("The content Dataframe is blank")
  }else{
    return(table(country_names[names(country_names)%in% c("label")]))
  }
  
}


surveys_per_country(kobo_content = kobo_content_list$general_content)
surveys_per_country()


#Dates when submitted project were created
project_deployment_dates <- function(kobo_content=NULL){
  library(dplyr)
  df_proj <- unique(kobo_content[kobo_content$deployment__active==TRUE, c("name", "date_created")])
  if(is.null(df_proj)){
    return("The content Dataframe is blank")
  }else{
    names(df_proj) <- c("Project Name", "Deployment Date")
    return(df_proj)
  }
  
}

project_deployment_dates(kobo_content_list$general_content)
project_deployment_dates()


#Projects Modification Dates
project_modification_dates <- function(kobo_content=NULL){
  library(dplyr)
  df_proj <- unique(kobo_content[kobo_content$deployment__active==TRUE, c("name", "date_modified")])
  if(is.null(df_proj)){
    return("The content Dataframe is blank")
  }else{
    names(df_proj) <- c("Project Name", "Modification Date")
    return(df_proj)
  }
  
}

project_modification_dates(kobo_content_list$general_content)
project_modification_dates()

#Project Name by ID
project_IDs <- function(kobo_content=NULL){
  form_id_pattern = "(?<=/assets/)[A-Za-z0-9_]{2,50}"
  df_proj <- unique(kobo_content[kobo_content$deployment__active==TRUE, c("name", "url")])
  df_proj[, "url"]<- str_extract(df_proj[, "url"], pattern = form_id_pattern )
  if(is.null(df_proj)){
    return("The content Dataframe is blank")
  }else{
    names(df_proj) <- c("Project Name", "Project ID")
    return(df_proj)
  }
  
}

project_IDs(kobo_content_list$general_content)
project_IDs()

#Number of Repeat groups per form
number_of_rpt_groups_per_form <- function(form_list = NULL){
  rp_groups <- unlist(lapply(form_list,FUN = length))
  
  if(is.null(rp_groups)){
    return("The content Dataframe is blank")
  }else{
    return(ifelse(rp_groups<1, rp_groups,rp_groups-1))
  }
  
}
number_of_rpt_groups_per_form()
number_of_rpt_groups_per_form(form_list = kobo_content_list$main_data_list)


#Names of Repeat groups per form
names_of_rpt_groups_per_form <- function(form_list = NULL){
  frm_list <- lapply(form_list, FUN = names)
  
  lst_rpt <- list()
  for(nam in names(frm_list)){
    if(length(frm_list[[nam]])>1){
      lst_rpt[[nam]] <- frm_list[[nam]]
    }
    
  }
  if(length(lst_rpt)>0){
    return(lst_rpt)
    
  }else{
    return("Data list is empty")
  }
}

names_of_rpt_groups_per_form()
names_of_rpt_groups_per_form(form_list = kobo_content_list$main_data_list)





