library(data.table)
system ("rm -r time_series_covid19_confirmed_US.csv")
system("wget -q https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_confirmed_US.csv")
od<-fread('./time_series_covid19_confirmed_US.csv', header = TRUE)
od<-od[!is.na(FIPS)]
m_dt <- melt(od, id.vars=c("UID","iso2","iso3","code3",  "FIPS",  "Admin2", "Province_State", "Country_Region",
                           "Lat",  "Long_",          "Combined_Key"  ), variable.name='Date', value.name = "cases")
m_dt[,`:=`(Date=as.Date(Date,format = "%m/%d/%y"))]
system("rm -r covid-19-data")

prev_d<-m_dt[,c("Date","FIPS","cases")]
prev_d[,`:=`(Date=Date+1)]
setnames(prev_d, c("cases"),c("pre_cases"))
setkeyv(m_dt, c("FIPS", "Date"))
setkeyv(prev_d, c("FIPS", "Date"))
cd<-m_dt[prev_d,nomatch=0]
cd[,`:=`(new_cases=cases-pre_cases)]
fwrite(cd,file="covid19.csv")
