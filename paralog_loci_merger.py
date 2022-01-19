from heapq import merge
import os
import argparse
import pandas as pd
import csv
import numpy as np

def main(table_path, output_path):

    table = pd.read_csv(table_path, delimiter="\t")
    table.columns = ['loci','match','a','b','c']

    merged_loci = []
    unique_loci = np.unique([loci.split('_')[0] for loci in pd.unique(table.iloc[0:,0])])
    
    for unique in unique_loci:

        append_list = []
        
        if unique not in merged_loci:
            for match in table[table['loci'].str.contains(unique)]['match']:

                if match.split('_')[0] not in append_list:
                    append_list.append(match.split('_')[0])

            append_list.append(unique)  
            append_list.sort()          
            merged_loci.append(append_list)

    for loci in merged_loci:
        for loci2 in merged_loci:
            if loci == loci2:
                continue
            elif set(loci).issubset(set(loci2)):
                if loci in merged_loci:
                    merged_loci.remove(loci)

    merged_loci = np.unique(merged_loci)

    with open(os.path.join(output_path,'merged_paralogous_loci.tsv'), 'w', newline='') as f_output:
        tsv_output = csv.writer(f_output, delimiter='\t')
        for i in merged_loci:
            tsv_output.writerow(i)

def parse_arguments():

    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)

    parser.add_argument('-t', type=str, required=True,
                        dest='table_path',
                        help='annotation table')
    
    parser.add_argument('-o', type=str, required=True,
                        dest='output_path',
                        help='output dir')
    

    args = parser.parse_args()

    return args


if __name__ == '__main__':

    args = parse_arguments()

    main(**vars(args))