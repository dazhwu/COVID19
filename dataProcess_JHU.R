library(data.table)

trans <- function(data_file, csv_name) {

    repos="https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/"
    
    system(paste("wget -q ", repos, data_file, sep=""))

    od<-fread(data_file, header = TRUE)
    od<-od[!is.na(FIPS)]
    variables=c("UID","iso2","iso3","code3",  "FIPS",  
        "Admin2", "Province_State", "Country_Region",
                           "Lat",  "Long_",   "Combined_Key"  )
    m_dt <- melt(od, id.vars=variables, variable.name="Date", value.name = "value")
    m_dt[,`:=`(Date=as.Date(Date,format = "%m/%d/%y"))]
    
    prev_d<-m_dt[,c("Date","FIPS","value")]
    prev_d[,`:=`(Date=Date+1)]
    setnames(prev_d, c("value"),c("pre_value"))
    setkeyv(m_dt, c("FIPS", "Date"))
    setkeyv(prev_d, c("FIPS", "Date"))
    cd<-m_dt[prev_d,nomatch=0]
    cd[,`:=`(increment=value-pre_value)]
    cd[,pre_value:=NULL]
    #fwrite(cd,file=csv_name)
    return(cd)
}
system ("rm -r *.csv")
cases_dt=trans("time_series_covid19_confirmed_US.csv", "new_cases.csv")
setnames(cases_dt, c("value","increment"),c("cum_cases","new_cases"))
deaths_dt=trans("time_series_covid19_deaths_US.csv", "new_deaths.csv")
setnames(deaths_dt, c("value","increment"),c("cum_deaths","new_deaths"))
deaths_dt=deaths_dt[,c("FIPS", "Date","cum_deaths","new_deaths")]
setkeyv(cases_dt, c("FIPS", "Date"))
setkeyv(deaths_dt, c("FIPS", "Date"))
cd<-cases_dt[deaths_dt,nomatch=0]
fwrite(cd,file="covid_us.csv")