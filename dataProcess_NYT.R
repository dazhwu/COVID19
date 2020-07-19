library(data.table)
system ("rm -r covid-19-data")
#system("git clone https://github.com/nytimes/covid-19-data")
system(paste("wget -q ","https://raw.githubusercontent.com/nytimes/covid-19-data/master/us-counties.csv"))
od<-fread('./covid-19-data/us-counties.csv', header = TRUE)
od<-od[!is.na(fips)]
system("rm -r covid-19-data")
od[,`:=`(date=as.Date(date,format = "%Y-%m-%d"))]
pd<-od[,c("date","fips","cases","deaths")]
pd[,`:=`(date=date+1)]
setnames(pd, c("cases","deaths"),c("pre_cases","pre_deaths"))
setkeyv(od, c("fips", "date"))
setkeyv(pd, c("fips", "date"))
cd<-od[pd,nomatch=0]
cd[,`:=`(new_cases=cases-pre_cases, new_deaths=deaths-pre_deaths)]
fwrite(cd,file="covid19.csv")
