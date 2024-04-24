"""
Creator: Mykyta Forofontov

This script separates assemblies that are from refseq but also present in ena661k database, 
input for this scripts uses output of script entrez_id_fetcher.py
"""

import os
import shutil
import pandas as pd
import csv
import argparse


def main(i_path, o_path, t_all_ids_path, t_ena661k_path):
    
    if not os.path.isdir(o_path):
        os.mkdir(o_path) 
    
    print("reading file...")

    table_ids = pd.read_csv(t_all_ids_path, delimiter="\t")

    table_ena661k = pd.read_excel(t_ena661k_path,na_filter=False)

    table_ena661k.convert_dtypes()

    remove_list = []

    for i in range(0,len(table_ids )):

        if i in table_ids['BioSample']:

            remove_list.append(table_ena661k.iloc[i]['File_name'])

            table_ena661k.iat[i,table_ena661k.columns.get_loc("excluded")] = "yes"

            if table_ena661k.iloc[i]["observation"] == "":
                table_ena661k.iat[i,table_ena661k.columns.get_loc("observation")]  = "Present in ena661k"


    print("moving assemblies...")

    for assembly in remove_list:
        if os.path.exists(os.path.join(i_path,assembly)):
            shutil.move(os.path.join(i_path,assembly),o_path)

    print("writing updated report...")

    table_ena661k.to_excel(os.path.join(o_path,"assemblies_removed_file.xlsx"), index = False)




def parse_arguments():

    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)

    parser.add_argument('-i', type=str, required=True,
                        dest='i_path',
                        help='folder with refseq assemblies')

    parser.add_argument('-o', type=str, required=True,
                        dest='o_path',
                        help='folder where to move excluded assemblies')
    
    parser.add_argument('--table_ids', type=str, required=True,
                        dest='t_all_ids_path',
                        help='path to table with id created by entrez_id_fetcher.py')
    
    parser.add_argument('--table_ena661k', type=str, required=True, 
                        dest='t_ena661k_path', 
                        help='path to ena table created by file_merger_assemblies.py')

    args = parser.parse_args()

    return args


if __name__ == '__main__':

    args = parse_arguments()

    main(**vars(args))
