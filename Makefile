##
## Makefile for data-science-consulting-part1
##

# Programs used by data-science-consulting-part1
PYTHON=python   # We assume python 3.5 or later
SQLITE=sqlite3

DATABASE_DIR=./data/processed
DATABASE=tutorial1.db
DB_CREATE_TABLES=./src/sql/create_tables.sql

MAKE_DATASET_DIR=./src/python
MAKE_DATASET_DIR_2_ROOT=../..
MAKE_DATASET=make_dataset.py

R_NOTEBOOKS=./notebooks/r

.PHONY: help create_db create_populate_db make_dataset vacuuming_db clean remove_db

help:
	@echo 'This makefile has the following commands:'
	@echo ' - make_dataset (build database from scratch)'
	@echo ' - clean (remove all temporary files)'
	@echo ' - create_db (just create database without populating it)'
	@echo ' - help (this message)'
	@echo ' - remove_db (remove the database file)'
	@echo ' - vacuuming_db (clean the database)'
	@echo ' '
	@echo 'Use DATABASE=dbname for working on a specific database (e.g., make make_dataset DATABASE=test.db)'

create_db: remove_db
	@if [ -a $(DATABASE_DIR)/$(DATABASE) ] ; then \
		echo 'No actions done!' ; \
	else \
		echo '>> Create a SQLite database <<' ; \
		cd $(MAKE_DATASET_DIR) && \
		$(PYTHON) $(MAKE_DATASET) \
			--db $(MAKE_DATASET_DIR_2_ROOT)/$(DATABASE_DIR)/$(DATABASE) \
			--verbose --create_db ; \
	fi;

make_dataset: remove_db create_populate_db vacuuming_db

create_populate_db:
	@if [ -a $(DATABASE_DIR)/$(DATABASE) ] ; then \
		echo 'No actions done!' ; \
	else \
		echo '>> Create and populate a SQLite database <<' ; \
		cd $(MAKE_DATASET_DIR) && \
		$(PYTHON) $(MAKE_DATASET) \
			--db $(MAKE_DATASET_DIR_2_ROOT)/$(DATABASE_DIR)/$(DATABASE) \
			--verbose ; \
	fi;

vacuuming_db:
	@echo '>> Vacuuming the database <<'
	@$(SQLITE) $(DATABASE_DIR)/$(DATABASE) 'VACUUM;'

clean:
	@echo 'All temporary files have been removed!'
	@rm -rf $(MAKE_DATASET_DIR)/modules/__pycache__
	@rm -rf $(R_NOTEBOOKS)/.RData $(R_NOTEBOOKS)/.Rhistory $(R_NOTEBOOKS)/.Rproj.user

remove_db:
	@if [ -a $(DATABASE_DIR)/$(DATABASE) ] ; then \
		rm -i $(DATABASE_DIR)/$(DATABASE) ; \
	fi;
