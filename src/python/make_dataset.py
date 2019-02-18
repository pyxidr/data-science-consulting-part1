#! /usr/bin/env python

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

-- make_dataset.py --

Utility used to collect of series of data provided by client and populate a
SQLite database file.

To do:
  - None at the moment
"""

import sys
import os
import argparse
import logging
import sqlite3
import yaml

from modules.client_data import populate_client_data
from modules.client_data import ClientDataError

from modules.utility_tables import create_utility_tables
from modules.utility_tables import UtilTablesError

__version__ = "0.1a"

logger = logging.getLogger('make_dataset')


def _intro():
    '''
    Provides a short description of the program
    '''
    logger.info('Populates client\'s data into a SQLite database ' +
                '(version {})'.format(__version__))


def _flush(conn, statements):
    '''
    Executes a series of SQL statements.
    '''
    cursor = conn.cursor()
    cursor.executescript(''.join(statements))


def make_dataset():
    '''
    Implementation of make_dataset.
    '''

    # Define and read the various user's options
    _description = 'Populates client\'s data into a SQLite database'
    _epilog = 'Contact research@pyxidr.com for further information.'
    aparser = argparse.ArgumentParser(description=_description,
                                      epilog=_epilog)
    aparser.add_argument('-v', '--version', action='version',
                         version='%(prog)s {}'.format(__version__))
    default_config_file = \
        '{}/config.yml'.format(os.path.dirname(os.path.realpath(__file__)))
    aparser.add_argument('-c', '--config', dest='config',
                         default=default_config_file,
                         type=argparse.FileType('r'),
                         help='configuration file, default config.yml')
    aparser.add_argument('-d', '--db', dest='database',
                         type=argparse.FileType('w'),
                         help='SQLite database file',
                         required=True)
    aparser.add_argument('-V', '--verbose', dest='verbose',
                         action='store_true', help='verbose')
    aparser.add_argument('--create_db', dest='create_db',
                         action='store_true',
                         help='just create database without populating it')

    args = aparser.parse_args()

    if args.verbose:
        logging.basicConfig(format='%(message)s', level=logging.INFO)

    _intro()

    # Read the various paramters from the configuration file
    with open(args.config.name, 'r') as ymlfile:
        try:
            cfg = yaml.load(ymlfile)
        except yaml.parser.ParserError:
            logger.error('** Error in parsing file {}.'
                         .format(args.config.name))
            sys.exit(2)

    try:
        # Open a connection to the database
        conn = sqlite3.connect(args.database.name)
        for fn in cfg['Parameters']['SQLFiles']:
            logger.info('. Executing \'{}\''.format(os.path.basename(fn)))
            statements = []
            for statement in open(fn, 'r').readlines():
                statements.append(statement)
            _flush(conn, statements)
        if not args.create_db:
            # Populate client's data
            populate_client_data(conn, cfg['Client'])
            # Create some utility tables
            create_utility_tables(conn, cfg['Parameters']['StartDate'],
                                  cfg['Parameters']['EndDate'],
                                  cfg['Parameters']['StartPeak'],
                                  cfg['Parameters']['EndPeak'])
    except ClientDataError:
        logger.error('** Error in parsing client\'s data.')
        if conn:
            conn.close()
        sys.exit(2)

    except UtilTablesError:
        logger.error('** Error in creating utility tables.')
        if conn:
            conn.close()
        sys.exit(2)

    finally:
        if conn:
            conn.close()


if __name__ == "__main__":
    make_dataset()
