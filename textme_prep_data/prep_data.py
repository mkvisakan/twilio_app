import os, sys
import csv

with open('Madison_Metro_Transit_Bus_Stops.csv', 'rb') as csvfile:
	spamreader = csv.reader(csvfile, delimiter=',', quotechar='"')
	for row in spamreader:
		Stop_ID,StopCode,Stop_Name,Stop_Description,Stop_Location,LocationType,ParentStation,Position,Direction,Wheelchair_Boarding = row
		print StopCode+","+Stop_Name
