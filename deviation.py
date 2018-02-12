#!/usr/bin/python

import sys, getopt
import json
from math import sqrt

def main(argv):
    json_file = ''
    try:
        opts, args = getopt.getopt(argv,"hf::",["file=",])
    except getopt.GetoptError:
        print('deviation.py -f <exp_file>.json')
        sys.exit(2)
    for opt, arg in opts:
        if opt == '-h':
            print('deviation.py -f <exp_file>.json')
            sys.exit()
        elif opt in ("-f", "--file"):
         json_file = arg

    if json_file == '':
        print('deviation.py -f <exp_file>.json')
        sys.exit(2)

    with open(json_file) as file:
        try:
            data = json.load(file)
            
            avg = data["tasks"][0]["subtasks"][0]["workloads"][0]["statistics"]["durations"]["total"]["data"]["avg"]
        
            sum = 0
            for stat in  data["tasks"][0]["subtasks"][0]["workloads"][0]["data"]: 
                sum += (stat["duration"] - avg)**2

            deviation = sqrt(1/len(data["tasks"][0]["subtasks"][0]["workloads"][0]["data"])*sum)

            print("Concurrency : " + str(data["tasks"][0]["subtasks"][0]["workloads"][0]["runner"]["constant"]["concurrency"]))
            print("Deviation : " + str(deviation))
        except:
            print("Your file is not a correct json file or the informations needed are not correctly formatted")

if __name__ == "__main__":
    main(sys.argv[1:])
