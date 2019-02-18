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

-- utility_tables.py --

Provides subroutines for populating SQL database with utility tables to
facilitate some analyses.

To do:
  - None at the moment
"""

import datetime
import logging
import pandas as pd

from modules.utils import get_season

logger = logging.getLogger('client_data')


class UtilTablesError(Exception):
    pass


def create_utility_tables(conn, start_date, end_date, start_peak, end_peak):
    '''
    Populates tables used to provide attributes to days and hours.
    '''
    logger.info('. Creating utility talbes')
    cursor = conn.cursor()
    _create_hourly_periods(conn, cursor, start_date, end_date,
                           start_peak, end_peak)
    _create_daily_periods(conn, cursor, start_date, end_date)


def _create_hourly_periods(conn, cursor, start_date, end_date,
                           start_peak, end_peak):
    '''
    Populates attributes associated hours.
    '''
    logger.info('.. Creating hourly table')

    # Delete any previous records
    cursor.execute('delete from tbl_util_hourly_periods;')
    conn.commit()

    list_of_records = list()
    range_of_dates = pd.date_range(start_date, end_date)
    for d in range_of_dates:
        for h in range(0, 24):
            record = dict({
                "date": d,
                "hour": h + 1,
                "datehour": datetime.datetime(d.year, d.month, d.day, h),
                "weekhour": d.weekday() * 24 + h + 1,
                "periodtype": 'On-Peak' if d.weekday() < 6 and
                h >= start_peak and h <= end_peak
                else 'Off-Peak'
            })
            list_of_records.append(record)
    df = pd.DataFrame(list_of_records)
    df.to_sql('tbl_util_hourly_periods', conn, if_exists='append', index=False)
    conn.commit()


def _create_daily_periods(conn, cursor, start_date, end_date):
    '''
    Populates attributes associated hours.
    '''
    logger.info('.. Creating daily table')

    # Delete any previous records
    cursor.execute('delete from tbl_util_daily_periods;')
    conn.commit()

    list_of_records = list()
    range_of_dates = pd.date_range(start_date, end_date)
    for d in range_of_dates:
        record = dict({
            "Date": d,
            "Year": d.year,
            "Month": d.month,
            "Week": d.isocalendar()[1],
            "Weekday": d.weekday() + 1,
            "QuarterID": "Q{}".format(d.year * 10 + (d.month - 1) // 3 + 1),
            "MonthID": "M{}".format(d.year * 100 + d.month),
            "WeekID": "W{}".format(d.year * 100 + d.isocalendar()[1]),
            "Season": get_season(d)
        })
        list_of_records.append(record)
    df = pd.DataFrame(list_of_records)
    df.to_sql('tbl_util_daily_periods', conn, if_exists='append', index=False)
    conn.commit()
