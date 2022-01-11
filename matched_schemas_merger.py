"""
This script merges two schemas by using output from match_schemas.py

"""

import os
import pandas as pd
import argparse



def main(input_reference_table, table_to_add, matched_schemas, output_path):

    table_ref = pd.read_csv(input_reference_table, delimiter="\t")
    table_add = pd.read_csv(table_to_add, delimiter="\t")
    matched_tab = pd.read_csv(matched_schemas, delimiter="\t",names=['Locus_ID','Locus','BSR_schema_match'])

    table_ref.convert_dtypes()
    table_add.convert_dtypes()
    matched_tab.convert_dtypes()

    table_add = table_add[['Locus','User_locus_name','Custom_annotatiom']]

    if not os.path.isdir(output_path):
        os.mkdir(output_path)

    #merge columns so that both table to add and reference have locus_ID
    merged_table = pd.merge(table_add,matched_tab, on = 'Locus', 
                            how = 'left')
    #change columns names
    merged_table.columns = ['Locus_GAS','User_locus_name_GAS',
                            'Custom_annotatiom_GAS',
                            'Locus_ID','BSR_schema_match']

    print(matched_tab)
    matched_table = pd.merge(table_ref,
                            merged_table,
                            on = ['Locus_ID'],
                            how = 'left')
    return matched_table.to_csv(os.path.join(output_path,"merged_file.tsv"),sep='\t',index=False)


def parse_arguments():

    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)

    parser.add_argument('--reference_table', type=str, required=True,
                        dest='input_reference_table',
                        help='annotation table')

    parser.add_argument('--add_table', type=str, required=True,
                        dest='table_to_add',
                        help='annotation to add table')

    parser.add_argument('--matched_table', type=str, required=True,
                        dest='matched_schemas',
                        help='schemas matcher output')
    
    parser.add_argument('-o', type=str, required=True,
                        dest='output_path',
                        help='output dir')
    

    args = parser.parse_args()

    return args


if __name__ == '__main__':

    args = parse_arguments()

    main(**vars(args))