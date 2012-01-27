#! /usr/bin/python

# Author: Ben Zoon
# Date: 12/22/2011
#
# Description: This is the script that updates the gtfs data

import os
import csv
import pprint
import MySQLdb
from xml.dom import minidom

DB_HOST = ""
DB_USER = ""
DB_PASS = ""

data_path = ""

entries = {}

# Read an XML config file to get login information
def read_config ():
	#this function will modify the values of these global variables
	global DB_HOST, DB_USER, DB_PASS, data_path, entries

	#parse the xml file
	config_dom = minidom.parse("gtfs_urls.xml")

	#gather database data
	for node in config_dom.getElementsByTagName("database"):
		DB_HOST = node.getAttribute("host")
		if len(DB_HOST) == 0:
			return 1
		DB_USER = node.getAttribute("user")
		if len(DB_USER) == 0:
			return 1
		DB_PASS = node.getAttribute("pass")
		if len(DB_PASS) == 0:
			return 1

		#print "%s%s%s" % (DB_HOST, DB_USER, DB_PASS)

	#get data directory
	for node in config_dom.getElementsByTagName("datapath"):
		data_path = node.getAttribute("value")
		if len(data_path) == 0:
			return 1

	#get url entries
	for node in config_dom.getElementsByTagName("entry"):
		entries[node.getAttribute("dirname")] = node.getAttribute("url")

# Download and Upzip public data feed into appropriate directory
# Remove the data directory and recreate it so it can be filled with new data.
# NOTE: This solution is not optimal because it does not preserve old data. 
# Old data can be saved later if needed.
def download_data ():
	#create new directory
	if os.path.exists(data_path):
		os.system("rm -rf " + data_path)
	os.system("mkdir " + data_path)

	#download public data feed, unzip, and delete the (downloaded) zip file
	for path, url in entries.items():
		dest = data_path + "/" + path
		os.system("mkdir " + dest)
		os.system("wget -P " + dest + " " + url)
		os.system("unzip -d " + dest + " " + dest + "/*.zip")
		os.system("rm -f " + dest + "/*.zip")

# Update whole database
def update_data ():
	#get path and filename seperately
	for dirname in entries.keys():
		path = data_path + "/" + dirname
		for file in os.listdir(path):
			update_data_file(path, file)

# Update each table based on each text file
# path: path only
# file: filename
def update_data_file (path, file):
	csv_reader = csv.reader(open(path + "/" + file, 'rb'))
	row_count = 0
	fieldnames = []

	#tablename = filename - last 4 chars (.txt)
	table = file[:-4]

	for row in csv_reader:
		#1st row is fieldnames
		if row_count == 0:
			fieldnames = row
		#other rows are data
		else:
			update_table (table, fieldnames, row)
		row_count += 1

# Insert/Update a row of data
# table: tablename
# fieldnames: an array of fieldnames
# row: a row of data, fields are seperated by ;
def update_table (table, fieldnames, row):
	#there is to way to compare tablename and primary key of the table automatically
	#because pairs of tablename and its keyname are different
	#we have to use control flow and hard code here
	if table == "agency":
		update_row(table, "agency_id", fieldnames, row)
	#elif table == "stops":
	#	update_row(table, "stop_id", fieldnames, row)
	#elif table == "routes":
	#	update_row(table, "route_id", fieldnames, row)
	#elif table == "trips":
	#	update_row(table, "trip_id", fieldnames, row)
	#temporary: stop_times, calendar, calendar_dates, fare_attributes, fare_rules, shapes, frequencies, transfers, feed_info
	#else:
	#	print "ERROR: Table '" + table + "' is not found."
	
# Insert/Update a row of data
# table: tablename
# key: primary key of the table
# fieldnames: an array of fieldnames
# row: a row of data, fields are seperated by ;
def update_row (table, key, fieldnames, row):
	#this query is used for table that has primary key with ONLY ONE field
	#it needs to be customize for primary key with multi-fields
	ssql = "select * from " + table + " where " + key + "='" + row[0] + "'"
	cursor = run_query (ssql)
	data = cursor.fetchone()

	#temporary
	#if (table == "agency" or table == "stops" or table == "routes" or table == "trips"):
	if (table == "agency"):
		#data is not existed in DB ==> INSERT
		if data is None:
			query = "insert into " + table + " ("
			for name in fieldnames:
				query += name + ", "
			query = query[:-2] + ") values ("
			for value in row:
				query += "'" + value + "', "
			query = query[:-2] + ")"

			print query

			run_query (query)
		#data is existed in DB ==> UPDATE
		else:
			query = "update " + table + " set "
			i = 0
			for name in fieldnames:
				query += name + "='" + row[i] + "', "
				i += 1
			query = query[:-2] + " where agency_id='" + row[0] + "'"

			print query

			run_query (query)

		#data is existed in DB but not in textfile ==> DELETE
		#...

# Execute a query
# query: the query will be executed
def run_query (query):
	db = MySQLdb.connect(DB_HOST, DB_USER, DB_PASS, "cs461-team35")

	cursor = db.cursor()
	cursor.execute(query)

	db.close()

	return cursor

if read_config() == 1:
	print "ERROR: could not read config file."

download_data()

update_data()

#print "%s%s%s %s" % (DB_HOST, DB_USER, DB_PASS, data_path)
#pprint.pprint(entries)
