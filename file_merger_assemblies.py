#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sat Nov 20 12:40:05 2021

@author: mykyta
"""

import os
import argparse
import pandas as pd

def main(mlst_tsv, sero_tsv, statistics_file, out_path):
    
    
    if not os.path.isdir(out_path):
        os.mkdir(out_path)
    
    mlst_table = pd.read_csv(mlst_tsv, delimiter="\t",header = None)
    
    sero_table = pd.read_csv(sero_tsv, delimiter="\t",header=None)
    
    stat_table = pd.read_csv(statistics_file, delimiter="\t")
    
    out_table = pd.DataFrame()
    
    out_table["File_name"] = mlst_table.iloc[:,0]

    
    out_table["organism_name"] = mlst_table.iloc[:,1]
    
    out_table["serotype"] = sero_table.iloc[:,2]
    
    out_table["ST"] = mlst_table.iloc[:,2]
    
    del stat_table["Sample"]
    
    out_table = out_table.join(stat_table)

    out_table["excluded"] = "no"

    out_table["observation"] = ""

    out_table.to_excel(os.path.join(out_path,"merged_file.xlsx"), index = False)
    
    
def parse_arguments():
    
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    
    parser.add_argument('--mlst_tsv', '--output', type=str, required=True, dest='mlst_tsv',
                        help='Path to the output directory.')

    parser.add_argument('--sero_tsv', type=str, required=True, dest='sero_tsv',
                        help='Path to the directory containing the ST file.')


    parser.add_argument('--statistics_file', type=str, required=True, dest='statistics_file',
                        help='Number of CPU cores to use. If the provided value exceeds \
                                         the maximum number of available cores uses maximum -2.')

    parser.add_argument('-o', type=str, required=True, dest='out_path',
                        help='Number of contigs allowed for each assembly.')
    
    args = parser.parse_args()

    return args


if __name__ == '__main__':

    args = parse_arguments()

    main(**vars(args))