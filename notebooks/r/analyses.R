##
## Script used by analyses notebook
##
## These are the objects created by this script
##   - df_all: All actual/historical data in one dataframe
##   - df_carbon: Historical daily spot carbon prices
##   - df_gas: Historical daily spot gas prices
##   - df_gen: Actual hourly generation
##   - df_power: Historical hourly day ahead power price
##   - df_tgu: Gas-fired generating unit's attributes
##   - df_util_daily: Daily periods
##   - df_util_hourly: Hourly periods
##   - plt_single_ts: Plot one time series
##   - Pyxidr color palettes

# Load the various packages required to run this script
require(RSQLite)
require(tidyverse)
require(lubridate)
require(xts)
require(dygraphs)

## Defination of some color palettes
BluePyxidr <- "#086DB0"
MagentaPyxidr <- "#EB008A"
GreenPyxidr <- "#00D58A"
DarkGreyPyxidr <- "#52636E"
LightGreyPyxidr <- "#ECF0F1"
PyxidrTwoColours_palette <- c(BluePyxidr, MagentaPyxidr)
PyxidrColours_palette <- c(BluePyxidr, MagentaPyxidr, DarkGreyPyxidr, GreenPyxidr, LightGreyPyxidr)

## Subroutines
resize_and_interpolate_daily_prices <- function(df, df_util, sd, ed) {
    # Resizes daily prices df and interpolates the missing values
    df2 <- right_join(df, filter(select(df_util, date), date >= sd & date <= ed), by = "date") 
    if (any(is.na(df2$price))) {
        # Fill the missing values by interpolating
        if (is.na(df2$price[1])) {
            day <- 2
            while (is.na(df2$price[day])) day <- day + 1
            df2$price[1] <- df2$price[day]
        }
        df2$price[is.na(df2$price)] <- with(df2, approx(date, price, xout = date)$y)[is.na(df2$price)]
    }
    return(df2)
}

resize_and_interpolate_hourly_prices <- function(df, df_util, sdh, edh) {
    # Resizes hourly prices df and interpolates the missing values
    df2 <- right_join(df, filter(select(df_util, datehour), datehour >= sdh & datehour <= edh), by = "datehour") 
    if (any(is.na(df2$price))) {
        # Fill the missing values by interpolating
        if (is.na(df2$price[1])) {
            hour <- 2
            while (is.na(df2$price[hour])) hour <- hour + 1
            df2$price[1] <- df2$price[hour]
        }
        df2$price[is.na(df2$price)] <- with(df2, approx(datehour, price, xout = datehour)$y)[is.na(df2$price)]
    }
    return(df2)
}

plt_single_ts <- function(ts, title = "", xlabel = "", ylabel = "") {
    # Plots one time series where ts is an xts object
    dygraph(ts, main = title) %>%
        dyOptions(fillGraph = TRUE, fillAlpha = 0.3, colors = BluePyxidr) %>% 
        dyRangeSelector() %>%
        dyAxis("x", label = xlabel) %>%
        dyAxis("y", label = ylabel)
}

# Connection to the database -- database is a string that the user needs
# to define prior sourcing this script
conn <- dbConnect(dbDriver("SQLite"), dbname = database)

## Gas-fired generating unit's attributes
df_tgu <- tbl_df(dbGetQuery(conn, paste0("select * from tbl_ref_power_plants where name = '", gen_unit_name, "'")))

## Daily and hourly periods
df_util_daily <- tbl_df(dbGetQuery(conn, "select * from tbl_util_daily_periods order by date;"))
df_util_daily$date <- as.Date(df_util_daily$date)

df_util_hourly <- tbl_df(dbGetQuery(conn, "select * from tbl_util_hourly_periods order by date;"))
df_util_hourly$datehour <- as.POSIXct(strptime(df_util_hourly$datehour, "%Y-%m-%d %H:%M:%S"), tz = "US/Pacific")
df_util_hourly$date <- as.Date(df_util_hourly$date)

## Historical data

# Actual generation
df_gen <- tbl_df(dbGetQuery(conn, paste0(
    "select gen.datehour, gu.name as gu, sum(gen.generation) as generation 
     from tbl_ref_power_plants gu, tbl_hist_generation gen
     where gu.name = '", gen_unit_name, "' and gen.plant_id = gu.id
     group by gen.datehour order by gen.datehour;")))
df_gen$datehour <- as.POSIXct(strptime(df_gen$datehour, "%Y-%m-%d %H:%M:%S"), tz = "US/Pacific")
df_gen$generation[is.na(df_gen$generation)] <- 0

# Historical spot gas prices
df_gas <- tbl_df(dbGetQuery(conn,
    "select prices.date, (prices.ask + prices.bid) / 2.0 as price
     from tbl_ref_price_products prod, tbl_hist_dailyprices prices
     where prod.product = 'Z1' and prices.product_id = prod.id
     order by prices.date;"))
df_gas$date <- as.Date(df_gas$date)

# Historical spot carbon prices
df_carbon <- tbl_df(dbGetQuery(conn, 
    "select prices.date, (prices.ask + prices.bid) / 2.0 as price
     from tbl_ref_price_products prod, tbl_hist_dailyprices prices
     where prod.product = 'Carbon' and prices.product_id = prod.id
     order by prices.date;"))
df_carbon$date <- as.Date(df_carbon$date)

# Fill any missing daily prices
start_date <- max(min(df_gas$date), min(df_carbon$date))
end_date <- min(max(df_gas$date), max(df_carbon$date))
df_gas <- resize_and_interpolate_daily_prices(df_gas, df_util_daily, start_date, end_date)
df_carbon <- resize_and_interpolate_daily_prices(df_carbon, df_util_daily, start_date, end_date)

# historical day ahead (spot) power prices
df_power <- tbl_df(dbGetQuery(conn, 
    "select prices.datehour, avg(prices.price) as price
     from tbl_ref_price_products power, tbl_hist_intradayprices prices
     where power.product = 'DAH' and prices.product_id = power.id
     group by prices.datehour order by prices.datehour;"))
df_power$datehour <- as.POSIXct(strptime(df_power$datehour, "%Y-%m-%d %H:%M:%S"), tz = "US/Pacific")

start_datehour <- max(min(df_power$datehour))
end_datehour <- min(max(df_power$datehour))
df_power <- resize_and_interpolate_hourly_prices(df_power, df_util_hourly, start_datehour, end_datehour)

## Create one dataframe including all data
df_all <- df_util_hourly %>%
    inner_join(df_util_daily, by = "date") %>%
    inner_join(df_power, by = "datehour") %>%
    inner_join(df_gas, by = "date") %>%
    inner_join(df_carbon, by = "date") %>%
    inner_join(df_gen, by = "datehour")
names(df_all)[14] <- "power"
names(df_all)[15] <- "gas"
names(df_all)[16] <- "carbon"

# Uncomment the following if you want to produce a CSV file -- useful to do some analyses in Excel or Tableau
# write.csv(df_all, file = "~/Tmp/all_data.csv") 

## End

# Disconnect from the database
dbDisconnect(conn)

# Remove objects not required anymore
remove(conn, resize_and_interpolate_daily_prices, start_date, end_date, 
       resize_and_interpolate_hourly_prices, start_datehour, end_datehour)
