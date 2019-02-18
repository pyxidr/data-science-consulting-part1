"""
Copyright (c) 2019, Pyxidr and/or its affiliates. All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

  - Redistributions of source code must retain the above copyright
    notice, this list of conditions and the following disclaimer.

  - Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in the
    documentation and/or other materials provided with the distribution.

  - Neither the name of Pyxidr or the names of its
    contributors may be used to endorse or promote products derived
    from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR
CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

===============================================================================

-- client_data.py --

Provides subroutines for populating SQL database with data
associated with power generating assets.

To do:
  - None at the moment
"""

import os
import datetime
import math
import logging
import pandas as pd

from modules.utils import Months
from modules.utils import convert_to_numeric

logger = logging.getLogger('make_dataset')


class ClientDataError(Exception):
    '''
    Class used for throwing errors.
    '''


def populate_client_data(conn, parameters):
    '''
    Populates the SQL database with client's data.
    '''
    logger.info('. Populating data associated with generating assets')
    cursor = conn.cursor()
    _populate_hourly_prices(conn, cursor, parameters['Prices']['Hourly'])
    _populate_daily_prices(conn, cursor, parameters['Prices']['Daily'])
    _populate_generation(conn, cursor, parameters['Generation'])


def _populate_hourly_prices(conn, cursor, parameters):
    '''
    Populates hourly prices.
    '''
    f_in_name = parameters[0]  # There is only one file

    # -- Power prices --

    logger.info('.. Reading \'{}\''.format(os.path.basename(f_in_name)))

    # Put all the data into a dataframe
    df = pd.read_excel(f_in_name)

    # Get product ID's
    cursor.execute(
        '''
            select id
            from tbl_ref_price_products
            where product = \'DAH\';
        ''')
    product_id = cursor.fetchone()[0]

    # Delete any previous records
    cursor.execute('delete from tbl_hist_intradayprices ' +
                   'where product_id = {};'.format(product_id))
    conn.commit()

    logger.info('.. Processing power spot prices')

    list_of_records = list()
    cur_row = 0
    while cur_row < len(df.index):
        if isinstance(df.iat[cur_row, 4], datetime.date):
            # For each hour
            for h in range(0, 24):
                if not math.isnan(df.iat[cur_row, h + 6]):
                    record = dict({
                        "datehour": datetime.datetime(
                            df.iat[cur_row, 4].year,
                            df.iat[cur_row, 4].month,
                            df.iat[cur_row, 4].day, h, 0),
                        "product_id": product_id,
                        "price": convert_to_numeric(df.iat[cur_row, h + 6])
                    })
                    list_of_records.append(record)
        cur_row += 1
    df2 = pd.DataFrame(list_of_records)
    df2.to_sql('tbl_hist_intradayprices', conn,
               if_exists='append', index=False)
    conn.commit()


def _populate_daily_prices(conn, cursor, parameters):
    '''
    Populates daily prices.
    '''
    f_in_name = parameters[0]  # There is only one file

    # -- Gas prices --

    logger.info('.. Reading gas prices from \'{}\''
                .format(os.path.basename(f_in_name)))

    # Put all the data into a dataframe
    df = pd.read_excel(f_in_name, sheet_name='Gas')

    # Get product ID's
    cursor.execute(
        '''
            select id
            from tbl_ref_price_products
            where product = \'Z1\';
        ''')
    product_id = cursor.fetchone()[0]

    # Delete any previous records
    cursor.execute('delete from tbl_hist_dailyprices ' +
                   'where product_id = {};'.format(product_id))
    conn.commit()

    logger.info('.. Processing gas cash prices')

    list_of_records = list()
    cur_row = 3
    while cur_row < len(df.index):
        if isinstance(df.iat[cur_row, 3], datetime.date):
            try:
                record = dict({
                    "date": df.iat[cur_row, 3],
                    "product_id": product_id,
                    "bid": convert_to_numeric(df.iat[cur_row, 4]),
                    "ask": convert_to_numeric(df.iat[cur_row, 4]),
                    "bid_size": 0,
                    "ask_size": 0
                })
                list_of_records.append(record)
            except KeyError:
                logger.warning('** Warning: Does not recognize price type ' +
                               '\'{}\'.'.format(df.iat[cur_row, 0]))
        cur_row += 1
    df2 = pd.DataFrame(list_of_records)
    df2.to_sql('tbl_hist_dailyprices', conn, if_exists='append', index=False)
    conn.commit()

    # -- Carbon prices --

    logger.info('.. Reading carbon prices from \'{}\''
                .format(os.path.basename(f_in_name)))

    # Put all the data into a dataframe
    df = pd.read_excel(f_in_name, sheet_name='Carbon')

    # Get the product ID
    cursor.execute(
        '''
            select id
            from tbl_ref_price_products
            where product = \'Carbon\';
        ''')
    product_id = cursor.fetchone()[0]

    # Delete any previous records
    cursor.execute('delete from tbl_hist_dailyprices ' +
                   'where product_id = {};'.format(product_id))
    conn.commit()

    logger.info('.. Processing carbon prices')

    list_of_records = list()
    cur_row = 4
    while cur_row < len(df.index):
        if isinstance(df.iat[cur_row, 0], datetime.date):
            record = dict({
                "date": df.iat[cur_row, 0],
                "product_id": product_id,
                "bid": convert_to_numeric(df.iat[cur_row, 1]),
                "ask": convert_to_numeric(df.iat[cur_row, 1]),
                "bid_size": 0,
                "ask_size": 0
            })
            list_of_records.append(record)
        cur_row += 1
    df2 = pd.DataFrame(list_of_records)
    df2.to_sql('tbl_hist_dailyprices', conn, if_exists='append', index=False)
    conn.commit()


def _populate_generation(conn, cursor, parameters):
    '''
    Populates historical generation.
    '''
    f_in_name = parameters[0]  # There is only one file

    logger.info('.. Reading generation from \'{}\''
                .format(os.path.basename(f_in_name)))

    # Put all the data into a dataframe
    df = pd.read_excel(f_in_name)

    # Get generating plant ID
    cursor.execute(
        '''
            select id
            from tbl_ref_power_plants
            where name = \'PP\';
        ''')
    plant_id = cursor.fetchone()[0]

    # Delete any previous records
    cursor.execute('delete from tbl_hist_generation ' +
                   'where plant_id = {};'.format(plant_id))
    conn.commit()

    logger.info('.. Processing generation for PP')

    list_of_records = list()
    cur_row = 3
    while cur_row < len(df.index):
        if isinstance(df.iat[cur_row, 1], datetime.datetime):
            record = dict({
                # Make sure we get a "clean" hour
                "datehour": datetime.datetime(
                    df.iat[cur_row, 1].year,
                    df.iat[cur_row, 1].month,
                    df.iat[cur_row, 1].day,
                    df.iat[cur_row, 1].hour),
                "plant_id": plant_id,
                "generation": convert_to_numeric(df.iat[cur_row, 2])
            })
            list_of_records.append(record)
        cur_row += 1
    df2 = pd.DataFrame(list_of_records)
    df2.to_sql('tbl_hist_generation', conn, if_exists='append', index=False)
    conn.commit()
