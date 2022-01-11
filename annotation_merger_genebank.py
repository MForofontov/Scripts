"""
This script merges output from ProtFinder ChewBBACA module and from genbank annotations script

"""

import os
import pandas as pd
import argparse



def main(input_reference_table, table_to_add, output_path):

    table_ref = pd.read_csv(input_reference_table, delimiter="\t")
    table_add = pd.read_csv(table_to_add, delimiter="\t")

    table_ref.convert_dtypes()
    table_add.convert_dtypes()

    table_add.rename({"origin_id":"genebank_origin_id","origin_product":"genebank_origin_product",
                            "origin_name":"genebank_origin_name","origin_bsr":"genebank_origin_bsr"},axis='columns',inplace=True)

    if not os.path.isdir(output_path):
        os.mkdir(output_path)

    merged_table = pd.merge(table_ref,
                            table_add,
                            on =['Locus_ID'],
                            how ='left')
    
    
    return merged_table.to_csv(os.path.join(output_path,"merged_file.tsv"),sep='\t',index=False)


def parse_arguments():

    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)

    parser.add_argument('--reference_table', type=str, required=True,
                        dest='input_reference_table',
                        help='ProtFinder output file')

    parser.add_argument('--add_table', type=str, required=True,
                        dest='table_to_add',
                        help='proteome_matcher.py output file')
    
    parser.add_argument('-o', type=str, required=True,
                        dest='output_path',
                        help='output dir')
    

    args = parser.parse_args()

    return args


if __name__ == '__main__':

    args = parse_arguments()

    main(**vars(args))