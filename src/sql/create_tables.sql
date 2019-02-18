/*
 * Copyright (c) 2019, Pyxidr and/or its affiliates. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 *   - Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *
 *   - Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 *   - Neither the name of Pyxidr or the names of its
 *     contributors may be used to endorse or promote products derived
 *     from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
 * IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/*
 * SQL code for creating the tables/view associated with energy's data sources.
 * The code is specific to SQLite.
 *
 * Nomenclature:
 *
 * - Table name starts with tbl_
 *     . Reference data are followed by Ref_ (they are usually "manually" populated)
 *     . Historical data are followed by Hist_ (they should be automatically populated)
 * - View name starts with qry_
 *
 * Instructions:
 *   sqlite3 tutorial1.db
 *   .read create_tables.sql
 *
 * To do:
 *  - None
*/

/**********************
 **                  **
 **  Reference data  **
 **                  **
 **********************/

-- tbl_Ref_Power_Markets: Power markets

create table if not exists tbl_ref_power_markets
(
    id integer not null,
    short_name varchar(10) not null,
    long_name varchar(50) not null,
    iso varchar(50),
    country varchar(50) not null,
    primary key (id),
    unique (short_name),
    unique (long_name),
    unique (country)
);

delete from tbl_ref_power_markets;

insert into tbl_ref_power_markets (id, short_name, long_name, iso, country)
  values
      (100, 'PM', 'Power Market', 'ISO', 'United States');

-- tbl_Ref_Power_Plants: Power plants

create table if not exists tbl_ref_power_plants
(
    id integer not null,
    name varchar(50) not null,
    type varchar(50),
    powermin real not null,            -- (MW)
    powermax real not null,            -- (MW)
    duct real not null,                -- Including duct capacity (MW)
    efficiency_pmin real not null,     -- (percent)
    heatrate_pmin real not null,       -- (btu/kWh)
    efficiency real not null,          -- (percent)
    heatrate real not null,            -- (btu/kWh)
    efficiency_duct real not null,     -- (percent)
    heatrate_duct real not null,       -- (btu/kWh)
    country varchar(50),
    market_name varchar(10) not null,
    market_id integer not null,
    latitude real,
    longitude real,
    primary key (id),
    unique (name),
    foreign key (country) references tbl_ref_power_markets(country),
    foreign key (market_name) references tbl_ref_power_markets(short_name),
    foreign key (market_id) references tbl_ref_power_markets(id)
);

create index if not exists tbl_ref_power_plants_idx_country on tbl_ref_power_plants (country);
create index if not exists tbl_ref_power_plants_idx_market_name on tbl_ref_power_plants (market_name);
create index if not exists tbl_ref_power_plants_idx_market_id on tbl_ref_power_plants (market_id);

delete from tbl_ref_power_plants;

insert into tbl_ref_power_plants (id, name, type, powermin, powermax, duct,
    efficiency_pmin, heatrate_pmin, efficiency, heatrate, efficiency_duct, heatrate_duct,
    country, market_name, market_id, latitude, longitude)
  values
      (10000, 'PP', 'CCGT', 46.25, 62.50, 77.50, 0.45210, 7511.0, 0.46666, 7312.0, 0.44868, 7605.0, 'United States', 'PM', 100, 0, 0);

-- tbl_Ref_Price_Products: Various commodity prices

create table if not exists tbl_ref_price_products
(
    id integer not null,
    product varchar(30) not null,
    commodity varchar(50) not null,
    market varchar(30) not null,
    term varchar(30) not null,
    frequency varchar(30) not null,
    currency varchar(30) not null,
    unit varchar(30) not null,
    comment varchar(255),
    primary key (product),
    unique (id)
);

create index if not exists tbl_ref_price_products_idx_market on tbl_ref_price_products (market);

delete from tbl_ref_price_products;

insert into tbl_ref_price_products (id, product, commodity, market, term,
    frequency, currency, unit, comment)
values
    (1001, 'Z1', 'Gas', 'US', 'Cash', 'Daily', 'USD', 'mmBtu', 'Zone 1'),
    (1101, 'DAH', 'Power', 'US', 'DA', 'Hourly', 'USD', 'MWh', 'DAH LMP'),
    (1201, 'Carbon', 'CO2', 'US', 'Cash', 'Daily', 'USD', 'tonne', 'Carbon Spot OTC');

/**********************
**                   **
**  Historical data  **
**                   **
***********************/

-- tbl_Hist_Generation: Actual generation

create table if not exists tbl_hist_generation
(
    datehour timestamp not null,
    plant_id integer not null,
    generation real default 0.0,  -- MWh
    -- primary key (datehour, plant_id),  -- Doesn't work as some days have twice 2am due to time change
    foreign key (plant_id) references tbl_ref_power_plants(id)
);

create index if not exists tbl_hist_generation_idx_datehour on tbl_hist_generation (datehour);
create index if not exists tbl_hist_generation_idx_plant_id on tbl_hist_generation (plant_id);

-- Tables related to historical prices

-- tbl_Hist_DailyPrices: Historical daily prices (e.g., fuel prices)

create table if not exists tbl_hist_dailyprices
(
    date date not null,
    product_id integer not null,
    bid real not null,
    ask real not null,
    bid_size real not null,
    ask_size real not null,
    primary key (date, product_id),
    foreign key (product_id) references tbl_ref_priceproducts(id)
);

-- tbl_hist_intradayprices: Historical hourly prices (e.g., day ahead power prices)

create table if not exists tbl_hist_intradayprices
(
    datehour timestamp not null,  -- Could be hourly, 30-min or 5-min periods
    product_id integer not null,
    price real not null,
    -- primary key (datehour, product_id),  -- Doesn't work as some days have twice 2am due to time change
    foreign key (product_id) references tbl_ref_priceproducts(id)
);

create index if not exists tbl_hist_intradayprices_idx_datehour on tbl_hist_intradayprices (datehour);
create index if not exists tbl_hist_intradayprices_idx_product_id on tbl_hist_intradayprices (product_id);

/*********************************************
**                                          **
**  Utility tables useful for blending data **
**                                          **
**********************************************/

-- tbl_util_daily_periods

create table if not exists tbl_util_daily_periods
(
    date date not null,
    year smallint not null,
    month smallint not null,
    week smallint not null,
    weekday smallint not null,
    quarterid varchar(6) not null,
    monthid varchar(7) not null,
    weekid varchar(7) not null,
    season varchar(10) not null,
    primary key (date)
);

create index if not exists tbl_util_daily_periods_idx_year on tbl_util_daily_periods (year);
create index if not exists tbl_util_daily_periods_idx_month on tbl_util_daily_periods (month);
create index if not exists tbl_util_daily_periods_idx_week on tbl_util_daily_periods (week);
create index if not exists tbl_util_daily_periods_idx_weekday on tbl_util_daily_periods (weekday);
create index if not exists tbl_util_daily_periods_idx_quarterid on tbl_util_daily_periods (quarterid);
create index if not exists tbl_util_daily_periods_idx_monthid on tbl_util_daily_periods (monthid);
create index if not exists tbl_util_daily_periods_idx_weekid on tbl_util_daily_periods (weekid);
create index if not exists tbl_util_daily_periods_idx_season on tbl_util_daily_periods (season);

-- tbl_util_hourly_periods

create table if not exists tbl_util_hourly_periods
(
    date date not null,
    hour smallint not null,
    datehour timestamp not null,
    weekhour smallint not null,
    periodtype varchar(10) not null,
    primary key (date, hour)
);

create index if not exists tbl_util_hourly_periods_idx_datehour on tbl_util_hourly_periods (datehour);
create index if not exists tbl_util_hourly_periods_idx_weekhour on tbl_util_hourly_periods (weekhour);
create index if not exists tbl_util_hourly_periods_idx_periodtype on tbl_util_hourly_periods (periodtype);
