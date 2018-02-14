#!/usr/bin/python

import json
import sys, os
from optparse import OptionParser
from optparse import Option, OptionValueError
import matplotlib.pyplot as plt
import random

class MultipleOption(Option):
    ACTIONS = Option.ACTIONS + ("extend",)
    STORE_ACTIONS = Option.STORE_ACTIONS + ("extend",)
    TYPED_ACTIONS = Option.TYPED_ACTIONS + ("extend",)
    ALWAYS_TYPED_ACTIONS = Option.ALWAYS_TYPED_ACTIONS + ("extend",)

    def take_action(self, action, dest, opt, value, values, parser):
        if action == "extend":
            values.ensure_value(dest, []).append(value)
        else:
            Option.take_action(self, action, dest, opt, value, values, parser)

def main(argv):    
    PROG = os.path.basename(os.path.splitext(__file__)[0])
    description = """Plot durations"""
    parser = OptionParser(option_class=MultipleOption,
                          usage='usage: %prog [OPTIONS] [PLOT_FILE]',
                          description=description)
    parser.add_option('-f', '--files', 
                      action="extend", type="string",
                      dest='files', 
                      metavar='FILES', 
                      help='comma separated list of files')
    parser.add_option('-l', '--labels', 
                      action="extend", type="string",
                      dest='labels', 
                      metavar='LABELS', 
                      help='comma separated list of legends')    
    parser.add_option('-t', '--title', 
                      type="string",
                      dest='title', 
                      metavar='TITLE', 
                      help='title on the graph')
    parser.add_option('-n', '--title2', 
                      type="string",
                      dest='title2', 
                      metavar='TITLE', 
                      help='title new line on the graph')

    if len(sys.argv) == 1:
        parser.parse_args(['--help'])

    OPTIONS, args = parser.parse_args()

    ps = []
    markers = [ '+' , '*' , '^' , 'o' , 'x']
    for f, l in zip(OPTIONS.files, OPTIONS.labels):
        points = []
        with open(f) as file:
            try:
                data = json.load(file)
                for stat in  data["tasks"][0]["subtasks"][0]["workloads"][0]["data"]: 
                    points.append(stat["duration"])

                ps.append(plt.plot(points, label=l, marker=random.choice(markers)))
            except:
                print("Your file is not a correct json file or the informations needed are not correctly formatted")
                sys.exit(2)

    plt.title(OPTIONS.title + (('\n' + OPTIONS.title2) if OPTIONS.title2 else ''))
    plt.legend()
    plt.xlabel('Iterations')
    plt.ylabel('Duration (s)')
    plt.xticks([0,5,10,15])

    plt.savefig(args[0], dpi=500)
    
    

if __name__ == "__main__":
    main(sys.argv[1:])
