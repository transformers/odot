#! /usr/bin/python

# Author: Ben Zoon, Phung Phan
# Date: 12/22/2011 - 2/2/2012
#
# Description: This is the script that updates the GTFS data in
#	       the database.

import os
import sys
import csv
import pprint
import MySQLdb
from xml.dom import minidom

DB_HOST = ""
DB_USER = ""
DB_PASS = ""
DB_NAME = ""

data_path = ""

entries = {}

agency_id = ""

# Read an XML config file to get login information
def read_config ():
	#this function will modify the values of these global variables
	global DB_HOST, DB_USER, DB_PASS, DB_NAME, data_path, entries

	fail = False

	#parse the xml file
	config_dom = minidom.parse("config.xml")

	#gather database data
	for node in config_dom.getElementsByTagName("database"):
		DB_HOST = node.getAttribute("host")
		DB_USER = node.getAttribute("user")
		DB_PASS = node.getAttribute("pass")
		DB_NAME = node.getAttribute("dbname")

	#get data directory
	for node in config_dom.getElementsByTagName("datapath"):
		data_path = node.getAttribute("value")

	#get url entries
	for node in config_dom.getElementsByTagName("entry"):
		if(node.getAttribute("active") != "0"):
			entries[node.getAttribute("dirname")] = node.getAttribute("url")

#	print DB_HOST, DB_USER, DB_PASS, DB_NAME

	#check for errors
	if data_path is None or data_path == "":
		print "ERROR: data_path not set"
		fail = True
	if DB_HOST is None or DB_HOST == "":
		print "ERROR: DB_HOST not set"
		fail = True
	if DB_USER is None or DB_USER == "":
		print "ERROR: DB_USER not set"
		fail = True
	if DB_PASS is None or DB_PASS == "":
		print "ERROR: DB_PASS not set"
		fail = True
	if DB_NAME is None or DB_NAME == "":
		print "ERROR: DB_NAME not set"
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
		print "Downloading from " + url + " into " + dest + "/"
		os.system("wget -P " + dest + " " + url + " -o /dev/null")
		os.system("unzip -d " + dest + " " + dest + "/*.zip > /dev/null 2>&1")
		os.system("rm -f " + dest + "/*.zip")
		if not os.path.exists(dest + "/agency.txt"):
			os.system("rm -rf " + dest);
			del entries[data_path]
			print "ERROR: Unable to download from " + url

# Update whole database
def update_data ():
	global agency_id

	# clear current database so new data can be added
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

	# get path and filename seperately
	for dirname in entries.keys():
		print "Updating data for " + dirname + "..."
		path = data_path + "/" + dirname
		agency_id = dirname
		for file in os.listdir(path):
			update_data_file(path, file)

# Update each table based on each text file
# path: path only
# file: filename
def update_data_file (path, file):
	csv_reader = csv.reader(open(path + "/" + file, 'rb'))
	row_count = 0
	fieldnames = []
	columns = []
	column_ids = []
	values = []

	#tablename = filename - last 4 chars (.txt)
	table = file[:-4]

	res = run_query("show columns from " + table)
	for col in res:
		fieldnames.append(col[0])

	for row in csv_reader:
		#1st row is fieldnames
		if row_count == 0:
			i = 0
			for field in row:
				if field in fieldnames:
					columns.append(field)
					column_ids.append(i)
				else:
					print "WARNING: Unsupported fieldname \"" + field + " detected in " + path + "/" + file
				i += 1

		#other rows are data
		else:
			values = []
			i = 0
			for field in row:
				if i in column_ids:
					values.append(field)
				i += 1
		
		#print columns
		#print column_ids
		#print values		
		if row_count > 0:
			insert_row (table, dict(zip(columns, values)))
		row_count += 1

# Insert/Update a row of data
# table: tablename
# key: primary key of the table
# fieldnames: an array of fieldnames
# row: a row of data, fields are seperated by ;
def insert_row (table, values):
	unique_fields = {"agency": "agency_id", "stops": "stop_id", "routes": "route_id",
                         "trips": "trip_id", "calendar": "service_id", "fare_attributes": "fare_id"}

	id_fields = ["agency_id", "stop_id", "zone_id", "route_id", "service_id", "trip_id", "block_id", 
                     "shape_id", "fare_id", "origin_id", "destination_id", "contains_id", "from_stop_id", "to_stop_id"]

	if table in unique_fields.keys():
		res = run_query("select * from " + table + " where " + unique_fields[table] + "='" + values[unique_fields[table]] + "'", True)
		if res is not None:
			print "WARNING: Duplicate unique key " + unique_fields[table] + " in table " + table

	query = "insert into " + table + " ("
	for name in values.keys():
		query += name + ", "
	query = query[:-2] + ") values ("
	for (name, value) in values.items():
		query += "'"
		if(name in id_fields): 
			query += agency_id + "_"
                query +=  escape_string(value) + "', "
	query = query[:-2] + ")"

	#print query

	run_query (query)

	if (table == "agency" and "agency_id" not in values):
                res = run_query("select max(id) from agency", True)
                run_query ("update agency set agency_id='" + agency_id + "' where id = " + str(res[0]))
        if (table == "routes" and "agency_id" not in values):
                res = run_query("select max(id) from routes", True)
                run_query ("update routes set agency_id='" + agency_id + "' where id = " + str(res[0]))

# Execute a query
# query: the query will be executed
def run_query (query, onerow = False):
	try:
		db = MySQLdb.connect(DB_HOST, DB_USER, DB_PASS, DB_NAME)
	except MySQLdb.Error:
		print "ERROR: Could not connect to database."

	cursor = db.cursor()

	try:
		cursor.execute(query)
	except MySQLdb.Error, e:
		print "ERROR: MySQL error: " + e.args[1]

	if(onerow):
		res = cursor.fetchone()
	else:
		res = cursor.fetchall()

	cursor.close();
	db.commit()
	db.close()

	return res

def escape_string (str):
	str = str.replace("'", "\\'")
	str = str.replace('"', '\\"')
	return str 

"""
read_config()
#run_query("drop table test1")
#run_query("create table test1( id int(11) not null primary key auto_increment )")
run_query("delete from test1")
for i in range(1000):
	query = "insert into test1() values ()"
	run_query(query)
	print query
print "Complete"
"""

print "**************************************"
print "ODOT Transit Network and Reporting App"
print "Database Update Script"
print "Copyright(c) 2012"
print "**************************************"

print ""
print "Reading config..."
if read_config():
	print "FATAL: Error reading config. Exit!"
	sys.exit()

print ""
print "Downloading data..."
download_data()

print ""
print "Updating data..."
update_data()

os.system("rm -rf feeds")

print ""
print "Complete."
