library(data.table)
library(openxlsx)

trans <- function(data_file) {
    if (file.exists(data_file)) {
        file.remove(data_file)
    }
    repos = "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/"
    url = paste(repos, data_file, sep = "")
    download.file(url, data_file)
    
    #system(paste("wget -q ", repos, data_file, sep=""))
    
    od = fread(data_file, header = TRUE)
    file.remove(data_file)
    
    od <- od[!is.na(FIPS)]
    variables = c(
        "UID",
        "iso2",
        "iso3",
        "code3",
        "FIPS",
        "Admin2",
        "Province_State",
        "Country_Region",
        "Lat",
        "Long_",
        "Combined_Key"
    )
    m_dt <-
        melt(
            od,
            id.vars = variables,
            variable.name = "Date",
            value.name = "value"
        )
    m_dt[, `:=`(Date = as.Date(Date, format = "%m/%d/%y"))]
    setnames(m_dt, c("Long_"), c("Longitude"))
    
    prev_d <- m_dt[, c("Date", "FIPS", "value")]
    prev_d[, `:=`(Date = Date + 1)]
    setnames(prev_d, c("value"), c("pre_value"))
    setkeyv(m_dt, c("FIPS", "Date"))
    setkeyv(prev_d, c("FIPS", "Date"))
    cd <- m_dt[prev_d, nomatch = 0]
    cd[, `:=`(increment = value - pre_value)]
    cd[, pre_value := NULL]
    #fwrite(cd,file=csv_name)
    return(cd)
}
start_time <- Sys.time()
cases_dt = trans("time_series_covid19_confirmed_US.csv")
setnames(cases_dt, c("value", "increment"), c("cum_cases", "new_cases"))
deaths_dt = trans("time_series_covid19_deaths_US.csv")
setnames(deaths_dt,
         c("value", "increment"),
         c("cum_deaths", "new_deaths"))
deaths_dt = deaths_dt[, c("FIPS", "Date", "cum_deaths", "new_deaths")]
setkeyv(cases_dt, c("FIPS", "Date"))
setkeyv(deaths_dt, c("FIPS", "Date"))
cd = cases_dt[deaths_dt, nomatch = 0]
#fwrite(cd, file = "covid_usa.csv")

population_filename = "population.csv"
if (file.exists(population_filename)) {
    file.remove(population_filename)
}

population_url = "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/UID_ISO_FIPS_LookUp_Table.csv"
download.file(population_url, population_filename)
pop = fread(population_filename)
file.remove(population_filename)



wb = createWorkbook()
addWorksheet(wb = wb, sheetName = "covid19_USA")
writeData(wb = wb, sheet = 1, x = cd)
addWorksheet(wb = wb, sheetName = "population")
writeData(wb = wb, sheet = 2, x = pop)
saveWorkbook(wb, "covid_JHU.xlsx", overwrite = TRUE)
end_time <- Sys.time()
print(end_time-start_time)