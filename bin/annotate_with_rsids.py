#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import pandas as pd
import argparse


SCRIPT_DESCRIPTION = """
#==============================================================================
# script for annotating .bim file with rsids (necessary for KING)
#
# Author: Eva Gradovich <eva@lifebit.ai>
# Date: 2022-06-17
# Version: 0.0.1
#==============================================================================
"""


def arguments():

    parser = argparse.ArgumentParser(
                formatter_class=argparse.RawDescriptionHelpFormatter,
                description=SCRIPT_DESCRIPTION)
    parser.add_argument('--rsid_cpra_table',
                        metavar='<str: rsid_cpra_table.tsv>',
                        type=str,
                        required=True,
                        help="""Path to the file containig cpra and rsids.""")
    parser.add_argument('-out', '--output_var_conv',
                        metavar='<str: output_var_conv.tsv',
                        type=str,
                        required=True,
                        help="""Path to the output file containing variant ID conversion in format expected by plink2.""")
    parser.add_argument('-pvar', '--pvar_file',
                        metavar='<str: .pvar file',
                        type=str,
                        required=True,
                        help=""".pvar file containing variant-level info.""")
    args = parser.parse_args()
    return args

args = arguments()

rsid_cpra_table = pd.read_csv(args.rsid_cpra_table,sep='\t')

rsid_cpra_table['cpra'] = rsid_cpra_table['chr'].astype(str) + '-' + rsid_cpra_table['pos'].astype(str) + '-' \
+ rsid_cpra_table['c1'].astype(str) + '-' + rsid_cpra_table['c2'].astype(str)

pvar = pd.read_csv(args.pvar_file,header=None, sep='\t',names=['chrom','pos','id','ref','alt'])
pvar['cpra'] = pvar['chrom'].astype(str) + '-' +  pvar['pos'].astype(str) + '-' + pvar['ref'].astype(str) + '-' + pvar['alt'].astype(str)
merged = pd.merge(pvar,rsid_cpra_table,on='cpra')
merged = merged.drop_duplicates(subset=['id'], keep='first')
merged[['rsid','id']].to_csv('output_var_conv.tsv',index=False,sep=' ', header=None)


