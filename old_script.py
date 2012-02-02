#! /usr/bin/python

# Author: Ben Zoon
# Date: 12/22/2011
#
# Description: This is the script that updates the gtfs data

import os
import sys
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

	fail = False

	#parse the xml file
	config_dom = minidom.parse("gtfs_urls.xml")

	#gather database data
	for node in config_dom.getElementsByTagName("database"):
		DB_HOST = node.getAttribute("host")
		DB_USER = node.getAttribute("user")
		DB_PASS = node.getAttribute("pass")

	#get data directory
	for node in config_dom.getElementsByTagName("datapath"):
		data_path = node.getAttribute("value")

	#get url entries
	for node in config_dom.getElementsByTagName("entry"):
		entries[node.getAttribute("dirname")] = node.getAttribute("url")

	#check for errors
	if data_path is None or data_path == "":
		print "ERROR: data_path not set"
		fail = True
	if DB_PASS is None or DB_PASS == "":
		print "ERROR: DB_HOST not set"
		fail = True
	if DB_HOST is None or DB_HOST == "":
		print "ERROR: DB_HOST not set"
		fail = True
	if DB_USER is None or DB_USER == "":
		print "ERROR: DB_USER not set"
		fail = True
	if len(entries) == 0:
		print "ERROR: No urls set."
		fail = True

	return fail

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
		print "Downloading from " + url + " into " + dest + "..."
		os.system("wget -P " + dest + " " + url + " -o /dev/null")
		os.system("unzip -d " + dest + " " + dest + "/*.zip > /dev/null 2>&1")
		os.system("rm -f " + dest + "/*.zip")
		if not os.path.exists(dest + "/agency.txt"):
			os.system("rm -rf " + dest);
			del entries[data_path]
			print "ERROR: Unable to download from " + url

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
	"""
	if table == "agency":
		update_row(table, ["agency_id"], fieldnames, row)
	elif table == "stops":
		update_row(table, ["stop_id"], fieldnames, row)
	elif table == "routes":
		update_row(table, ["route_id"], fieldnames, row)
	elif table == "trips":
		update_row(table, ["trip_id"], fieldnames, row)
	elif table == "stop_times":
		update_row(table, ["trip_id"], fieldnames, row)
	elif table == "calendar":
		update_row(table, ["trip_id"], fieldnames, row)
	elif table == "calendar_dates":
		update_row(table, ["trip_id"], fieldnames, row)
	elif table == "fare_attributes":
		update_row(table, ["trip_id"], fieldnames, row)
	elif table == "fare_rules":
		update_row(table, ["trip_id"], fieldnames, row)
	elif table == "shapes":
		update_row(table, ["trip_id"], fieldnames, row)
	elif table == "frequencies":
		update_row(table, ["trip_id"], fieldnames, row)
	elif table == "transfers":
		update_row(table, ["trip_id"], fieldnames, row)
	elif table == "feed_info":
		update_row(table, ["trip_id"], fieldnames, row)
	else:
		print "ERROR: Table '" + table + "' is not found."
	"""

	update_row (table, "", fieldnames, row)
	
# Insert/Update a row of data
# table: tablename
# key: primary key of the table
# fieldnames: an array of fieldnames
# row: a row of data, fields are seperated by ;
def update_row (table, key, fieldnames, row):
	run_query("delete from agency")
	run_query("delete from stops")
	run_query("delete from routes")
	run_query("delete from trips")
	run_query("delete from stop_times")
	run_query("delete from calendar")
	run_query("delete from calendar_dates")
	run_query("delete from fare_attributes")
	run_query("delete from fare_rules")
	run_query("delete from shapes")
	run_query("delete from frequencies")
	run_query("delete from transfers")
	run_query("delete from feed_info")

	#this query is used for table that has primary key with ONLY ONE field
	#it needs to be customize for primary key with multi-fields

	# http://www.velocityreviews.com/forums/t358221-db-api-how-can-i-find-the-column-names-in-a-cursor.html
	rowd = dict(zip([d[0] for d in curs.description], row))

	ssql = "select * from " + table + " where "
	for id in key:
		ssql += id + "='" + rowd[id] + "' and "
	ssql = ssql[:-5]

	print ssql

	#cursor = run_query (ssql)
	data = cursor.fetchone()

	#data is not existed in DB ==> INSERT
	if data is None:
		query = "insert into " + table + " ("
		for name in fieldnames:
			query += name + ", "
		query = query[:-2] + ") values ("
		for value in row:
			query += "'" + value + "', "
		query = query[:-2] + ")"

		#print query

		run_query (query)

	#data is existed in DB ==> UPDATE
	else:
		query = "update " + table + " set "
		i = 0
		for name in fieldnames:
			query += name + "='" + row[i] + "', "
			i += 1
		query = query[:-2] + " where "
		for id in key:
			query += id + "='" + rowd[id] + "' and "
		query = query[:-5]

		#print query

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

print "**************************************"
print "ODOT Transit Network and Reporting App"
print "Database Update Script"
print "Copyright(c) 2012"
print "**************************************"

print ""
print "Reading config..."
if read_config():
	print "FATAL: Error reading config. Quitting..."
	sys.exit()

print ""
print "Downloading data..."
download_data()

print ""
print "Updating data..."
update_data()

print ""
print "Complete."
