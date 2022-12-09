#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import pandas as pd
import argparse
import numpy as np


SCRIPT_DESCRIPTION = """
#========================================================================================
# script for removing outliers based on heterozygosity rate (estimated using plink --het)
#
# Author: Eva Gradovich <eva@lifebit.ai>
# Date: 2022-11-04
# Version: 0.0.1
#========================================================================================
"""


def arguments():

    parser = argparse.ArgumentParser(
                formatter_class=argparse.RawDescriptionHelpFormatter,
                description=SCRIPT_DESCRIPTION)
    parser.add_argument('--plink_het',
                        metavar='<str: plink.het>',
                        type=str,
                        required=True,
                        help="""Path to .het file (output of plink --het command) """)
    parser.add_argument('--sd',
                        metavar='<float: S>',
                        type=float,
                        default=3.0,
                        help="""Exclude individuals with F coefficient greater than S standard deviations from the mean.""")
    args = parser.parse_args()
    return args

args = arguments()

het_table = pd.read_csv(args.plink_het, delim_whitespace=True)

# Get samples with F coefficient within 3 SD of the population mean
f_mean = np.mean(het_table['F'])
f_sd = np.std(het_table['F'])
filter = (het_table['F'] >= f_mean - args.sd * f_sd ) & (het_table['F'] <= f_mean + args.sd * f_sd )
pass_het_samples = het_table[filter]

pass_het_samples[['FID','IID']].to_csv('het_passing_samples.tsv',sep='\t', index=False, header=None)


