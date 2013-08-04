#!/usr/bin/env python

"""
A utility to make a log of fan speeds alongside CPU temporatures (for a
ThinkPad T410 but probably usable on other machines with small adjustments).
"""

import sys,os.path,string,time
from datetime import datetime

def readString(path, start):
    f = open(path)
    for line in f:
        if line[0:len(start)] == start:
            return string.strip(string.split(line,":")[1])

def readValue(path):
    f = open(path)
    for line in f:
        return string.strip(line)

def main(pname):
    logpath = os.path.dirname(pname) + "/record-fan.log"
    logf = open(logpath, "a+")
    while(True):
        t1 = readValue("/sys/devices/virtual/hwmon/hwmon0/temp1_input")
        t2 = readValue("/sys/devices/platform/coretemp.0/temp2_input")
        t4 = readValue("/sys/devices/platform/coretemp.0/temp4_input")
        level = readString("/proc/acpi/ibm/fan", "level")
        speed = readString("/proc/acpi/ibm/fan", "speed")
        freq = readString("/proc/cpuinfo", "cpu MHz")
        date = str(datetime.now())
        line = date+";"+freq+";"+t1+";"+t2+";"+t4+";"+level+";"+speed+"\n"
        print line,
        logf.write(line)
        logf.flush()
        time.sleep(15)

main(sys.argv[0])
