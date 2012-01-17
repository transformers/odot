#! /usr/bin/python

# Author: Ben Zoon
# Date: 12/22/2011
#
# Description: This is the script that updates the gtfs data

import os
import pprint
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
def init_directories ():
	if os.path.exists(data_path):
		os.system("rm -rf " + data_path)
	#print "%s%s%s %s" % (DB_HOST, DB_USER, DB_PASS, data_path)
	os.system("mkdir " + data_path)

	for path, url in entries.items():
		dest = data_path + "/" + path
		os.system("mkdir " + dest)
		os.system("wget -P " + dest + " " + url)
		os.system("unzip -d " + dest + " " + dest + "/*.zip")

def update_entry (dirname, url):
	download_data (dirname, url);
	#update_data (dirname)

def download_data (dirname, url):
	pass

if read_config() == 1:
	print "ERROR: could not read config file."
init_directories()
#update_entry("curry", "something")
#print "%s%s%s %s" % (DB_HOST, DB_USER, DB_PASS, data_path)
#pprint.pprint(entries)
