"""
This script merges output from paralagous_interloci_validation.py and from alelle_call_merger.py

Inputs :
    --paralagous_alellecall : str
        output from alelle_call_merger.py.
    --interloci_validation : str
        paralagous_interloci_validation.py.
    -o : str
        path to where output results.

Outputs:
    TSV file containing paralogous groups one per row, each loci is contained in one column.

"""
import os
import argparse
import csv
import numpy as np
from collections import Counter

def main(paralagous_loci_validation, paralagous_alelle_call, output_path):

    with open(paralagous_loci_validation) as file1:
        loci_validation = list(csv.reader(file1, delimiter="\t"))
    
    with open(paralagous_alelle_call) as file2:
        alelle_call = list(csv.reader(file2, delimiter="\t"))

    merged = loci_validation

    """
    Chooses and merges similiar items from both sets of paralagous loci.
    
    """
    for i in merged:

        for l in alelle_call:

            if i == l:            
                continue

            elif len(set(i).intersection(set(l)))>0:

                merged.append(list(set(i).union(set(l))))

                if i in merged:
                    merged.remove(i)
                if l in merged:
                    merged.remove(l)

            elif l not in merged:
                merged.append(l)

    """
    Remove duplicates and merge lists with similiar content.

    e.g:

       [x y z] u [x y k] merges to create [x y z k]
    """
    loop = 0
    loops_todo = Counter([i[0] for i in merged]).most_common()[0][1]

    while loop != loops_todo:

        loop += 1

        for i in merged:
            for l in merged:
                if i == l:
                    continue
                
                elif len(set(i).intersection(set(l)))>0:

                    merged.append(list(set(i).union(set(l))))

                    if i in merged:
                        merged.remove(i)
                    if l in merged:
                        merged.remove(l)


    for i in range(len(merged)):

        merged[i].sort()

    merged = list(np.unique(merged))

    with open(os.path.join(output_path,'merged_paralogous.tsv'), 'w', newline='') as f_output:
        tsv_output = csv.writer(f_output, delimiter='\t')

        for i in merged:
            tsv_output.writerow(i)

def parse_arguments():

    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)

    parser.add_argument('--paralagous_alellecall', type=str, required=True,
                        dest='paralagous_alelle_call',
                        help='paralagous alelle call file')

    parser.add_argument('--interloci_validation', type=str, required=True,
                        dest='paralagous_loci_validation',
                        help='interloci validation table')
    
    parser.add_argument('-o', type=str, required=True,
                        dest='output_path',
                        help='output dir')
    

    args = parser.parse_args()

    return args


if __name__ == '__main__':

    args = parse_arguments()

    main(**vars(args))