<img src="./images/data-science.jpg" height=500>

# Data Science Applied to Management Consulting Engagements -- Tutorial I

> <img src="./images/exclamation-icon.png" height=20> This tutorial require some knowledge of Python, R and SQL but not at the level that will get you hired at Google.

## Contents

- [Introduction](#introduction)
- [About this tutorial](#about-this-tutorial)
- [Getting Started](#getting-started)
- [License](#license)

<a name="introduction" />

## Introduction

You may have realized as a management consultant at the analyst/associate level that a decent knowledge of data science would have been instrumental in some client engagements for achieving high impact analyses. How often did your analysis requires processing a large amount of data too big for Excel but not big enough to be called Big Data --- the “not so Big Data” challenge? When did you wish you knew more than a regression analysis for identifying relationships? How clueless were you when your manager asked you to do an optimal allocation of 100+ resources? How frustrated were you of not finding a way to present data that made your insights obvious? How disappointed was the client when you told her that she could not use your work in exploitation?

However, you are asking yourself which skills I need to acquire and how deep I need to be to be impactful. We have experienced situations where the client expected the consultant to have strong business acumen and outstanding analytics, be the expert in machine learning and statistics, and have better than average programming skills. While some individuals are real polymaths, most of us need to make some compromises. Do you want to be a translator or a data scientist? It is easier for a consultant without a strong background in computer science (or related disciplines) to aspire to be a translator than a data scientist. We suggest wanting to be between a translator and a data scientist, i.e., putting an emphasis on business intelligence and analytics, and learning just enough about programming, statistics, machine learning, or mathematical programming to quickly get to the right insights. If you are a consultant at a top management consulting firm, you already have the intrinsics required for business intelligence and analytics. Experience, curiosity, and creativity will make you better at these skills. The other abilities are complementary but can make a meaningful difference if you are time/budget constrained. A short engagement with high impact usually leads to a proper one as you have now persuaded the client about the benefits. After you have convinced the client about the opportunities, you can always help her structure the critical elements of a project that will involve experts in programming, machine learning, etc., to have a “production” version of your “proof-of-concept”.

A typical engagement involving advanced analytics requires doing the following four steps:

1. Request/gather data from various sources (e.g., client, Bloomberg, Internet, etc.) that could come in different formats (e.g., xls, csv, xml, json)
2. Put these data into a form that make them easily analyzable (aka data wrangling)
3. Perform numerous analyses
4. Communicate insights and observations

If step 1 leads to too many files or step 3 requires blending a large amount of data, Excel becomes quickly a very inefficient tool. We can use a combination of commercial tools requiring limited programming skills to do steps 2, 3 and 4 but they are usually expensive and not always flexible. In the other hand, open source tools are free and very flexible but involve a learning curve for most consultants.

Our objective with this project is to put together a series of tutorials for showing how a consultant can use open source tools to achieve steps 2, 3 and 4 on disguised client engagements --- we find it more comfortable to learn from examples (top-down approach) than reading the necessary documents before getting started (bottom-up approach). We are planning so far three tutorials:

1. **How to perform essential data wrangling/blending and analyses** (this tutorial)
2. How to use mathematical programming for accomplishing more sophisticated/insightful analyses
3. How to use machine learning techniques for identifying patterns that can lead to commercial insights

All tutorials revolve around the following stack:
* [Julia](https://julialang.org) for mathematical programming and numerical computing
* [Jupyter](http://jupyter.org) for literate programming (mostly used with Julia and Python)
* [Python](https://www.python.org/) for data wrangling and analyses,
* [R](https://www.r-project.org/) for analyses and communicating results, insights and observations --- we can re-use some of the graphics produced in R for creating a PowerPoint document.
* [SQLite](https://sqlite.org/download.html) for storing and querying the data (“blending”)

One can replace SQLite by [MySQL](https://www.mysql.com/) or [PostgreSQL](https://www.postgresql.org/) that are more powerful databases, but they are a little bit more complicated to work with.

We provide a [curated list](http://pyxidr.com/data-science-list-resources.html) of data science resources that you can consult to get more familiar with these tools and approaches.

Why going through the troubles of learning three programming languages (i.e., Julia, Python, and R)? Based on our experience, Python is perfect for “gluing” things together — it has an extensive collection of libraries; R has a very polished literate programming environment (through RMarkdown) and outstanding graphics that allow producing client-ready deliverables; and, Julia has the flexibility of a scripting language but the performance of a compiled language (e.g., C and C++).

Hopefully, this tutorial should ease the learning curve of using open source tools and lead to better insights --- _our problem-solving capability should be the limiting factor, not the tools we use_.

You can send any feedback or questions to [research@pyxidr.com](mailto:research@pyxidr.com).

<a name="about-this-tutorial" />

## About this tutorial

You will learn in this tutorial the following elements:

1. How to create a relational database using SQLite and SQL
2. How to populate the database with the client's data in Python
3. How to run the analyses in R and use RMarkdown to communicate the findings --- see this [notebook](./notebooks/r/analyses.html) as an example

### Client engagement

The client owns an efficient gas-fired power plant that is offered every day in the spot market. The dispatch team is responsible for scheduling the plant to maximize its margin while meeting all its dynamic constraints (e.g., start-up time, ramping, etc.). We have been asked to identify potential dispatch opportunities, i.e., ways to schedule the plant that lead to more profits.

### Folders' structure

This is how we organize our folders:
```
.
├── data
│   ├── client     # Client's data
│   ├── processed  # Data that we have processed
├── images         # Images common to various documents
├── notebooks      # Analyses
├── reports        # Progress review documents
└── src            # Applications, scripts, etc.
```

### Data

To perform the analysis, the client provides the historical spot prices associated with power, natural gas and carbon, and past generation. The following Excel files include all the client's data:

* `data/client/gas and carbon prices.xlsx` (natural gas and carbon daily spot prices)
* `data/client/power prices.xlsx` (power hourly spot prices)
* `data/client/generation.xlsx` (hourly generation)

### Data wrangling

We have implemented a script in Python `src/python/make_dataset.py` that reads the client's Excel files and populates an SQL database. We create first the database by running the SQL code in `src/sql/create_tables.sql`. We have documented both the script and sql code --- please refer to the code for more details.

### Analyses and communication

We have built a notebook (`notebooks/r/analyses_v1.Rmd`) using RMarkdown (with RStudio) to run the analyses and communicate the insights. RMarkdown is a form of [literate programming](https://en.wikipedia.org/wiki/Literate_programming) beneficial for communicating complicated analyses.

<a name="getting-started" />

## Getting Started

These instructions will get you a copy of the project on your machine.

### Prerequisites

We would have used [Docker](https://www.docker.com/what-docker) if it was popular among management consultants --- it allows you to automatically install the various applications and packages required for a given project without interfering with your current environment.

You need at least to install the following software:

* [SQLite](https://sqlite.org/download.html) (and you may want to get [DB Browser for SQLite](http://sqlitebrowser.org/))
* [Python 3.5+](https://www.python.org/), or
* [Anaconda](https://www.continuum.io/downloads) (better environment for Python that comes with many libraries already installed)
* [R](https://www.r-project.org/)
* [R Studio](https://www.rstudio.com/)

We do our development on MacOS and use the following software (in addition to the above):

* [Atom](https://atom.io/) a "hackable text editor for the 21st Century"
* [Git](https://en.wikipedia.org/wiki/Git) a version control system for tracking changes
* [GNU Make](https://www.gnu.org/software/make/) a tool which controls the generation of executables and other non-source files of a program from the program's source files

If you are on Windows, you can get Git and GNU Make (and other Unix utilities) by installing
[Cygwin](https://www.cygwin.com/).

### Installing

TBD --- installing from GitHub

Requirements.txt: `conda install --yes --file requirements.txt` or ` pip install -r requirements.txt`

### Building the database

There are 2 approaches:

#### Using GNU Make

In the root directory (where you will find the file `Makefile`), run simply `make populate_db`.

#### Manually

In folder `data/processed`, run the following commands:

1. `sqlite3 tutorial1.db`
2. `.read ../../src/sql/create_tables.sql`
6. `.quit`
7. `cd ../../src/python`
8. `python make_dataset.py -d ../../data/processed/tutorial1.db -p "../../data/client" -V`

You can compact the database by running `sqlite3 tutorial1.db 'VACUUM;'` in folder `data/processed`.

### Running the analyses

In RStudio, open project `notebooks/r/R.Rproj` and file `notebooks/r/analyses_v1.Rmd`. Once you have opened this file, click on button Knit to produce an html version of the notebook.

<a name="license" />

## License

This project is licensed under the MIT License - see the
[LICENSE.md](LICENSE.md) file for details
