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

# Remove the data directory and recreate it so it can be filled with new data.
# NOTE: This solution is not optimal because it does not preserve old data. 
#  Old data can be saved later if needed.
def download_data ():
	if os.path.exists(data_path):
		os.system("rm -rf " + data_path)
	#print "%s%s%s %s" % (DB_HOST, DB_USER, DB_PASS, data_path)
	os.system("mkdir " + data_path)

	for path, url in entries.items():
		dest = data_path + "/" + path
		os.system("mkdir " + dest)
		os.system("wget -P " + dest + " " + url)
		os.system("unzip -d " + dest + " " + dest + "/*.zip")
		os.system("rm -f " + dest + "/*.zip")

def update_data ():
	for dirname in entries.keys():
		path = data_path + "/" + dirname
		for file in os.listdir(path):
			update_data_file(path, file)

def update_data_file (path, file):
	csv_reader = csv.reader(open(path + "/" + file, 'rb'))
	row_count = 0
        fieldnames = []
	table = file[:-4]
	for row in csv_reader:
		if row_count == 0:
			fieldnames = row
		else:
			update_row (table, fieldnames, row)
		row_count += 1

def update_row (table, fieldnames, row):
	if table == "agency":
		cursor = run_query ("select * from agency")
		data = cursor.fetchone()
		print data	

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
#update_entry("curry", "something")
#print "%s%s%s %s" % (DB_HOST, DB_USER, DB_PASS, data_path)
#pprint.pprint(entries)
