import sys, os
import csv
fw = open('fun.csv', 'w')
f = open(sys.argv[1], 'r')
write_line=''
for line in f:
	if len(line.strip())==0:
		if len(write_line.strip())>0:
			fw.write(sys.argv[2]+"|"+write_line+"\n")
			write_line = ''
	else:
		line= line.replace('|', '')
		write_line = write_line + line.replace('\n','\t')
fw.close()
f.close()
