#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Hail GWAS script
"""

import argparse
import hail as hl


SCRIPT_DESCRIPTION = """
#==============================================================================
# hail_gwas: script to perform GWAS analysis using Hail package
#
# Author: David Piñeyro <davidp@lifebit.ai>
# Date: 2022-02-18
# Version: 0.0.1
#==============================================================================
"""


def arguments():
    """This function uses argparse functionality to collect arguments."""
    parser = argparse.ArgumentParser(
                formatter_class=argparse.RawDescriptionHelpFormatter,
                description=SCRIPT_DESCRIPTION)
    parser.add_argument('--hail',
                        metavar='<str: hail.mt>',
                        type=str,
                        required=True,
                        help="""A hail MatrixTable file.""")
    parser.add_argument('--phe',
                        metavar='<str: pheno.phe>',
                        type=str,
                        required=True,
                        help="""A tab separated phenotype file, being the first
                                column the participant ID and the rest of the
                                columns the provided phenotypic values. It's expected
                                to contain a header.""")
    parser.add_argument('--id-col',
                        metavar='<str: column name>',
                        type=str,
                        default='IID',
                        help="""ID column name in the --phe file to be used
                                as sample name column. Default=IID""")
    parser.add_argument('--response',
                        metavar='<str: column name>',
                        type=str,
                        required=True,
                        help="""Trait column name in the --phe file to be used as a response
                                variable (y term) to perform the GWAS regression.""")
    parser.add_argument('--cov',
                        metavar='<str: cov1,cov2,...>',
                        type=str,
                        help="""A comma separated list of column names from --phe to be
                                used as covariates for the model.""")
    parser.add_argument('--pca',
                        metavar='<int: 3>',
                        type=int,
                        default=3,
                        help="""How many Principal Components to be used as covariates.
                                Default=3""")
    parser.add_argument('--call-rate-thr',
                        metavar='<float: 0.97>',
                        type=float,
                        default=0.97,
                        help="""Call rate threshold. Default=0.97""")
    parser.add_argument('--maf-thr',
                        metavar='<float: 0.01>',
                        type=float,
                        default=0.01,
                        help="""Minor allele frequency threshold. Default=0.01""")
    parser.add_argument('--output',
                        metavar='<str: output.tsv',
                        type=str,
                        help="""Path to the output TSV file with the GWAS results.
                                Default=output.tsv""")
    args = parser.parse_args()
    return args


###############################################################################
# MAIN
def main_program():
    """Main program."""
    args = arguments()

    # Import the original Hail MatrixTable
    mt = hl.read_matrix_table(args.hail)
    genome_build = mt.locus.dtype.reference_genome.name
    # Import the phenotypic data
    table = hl.import_table(args.phe, impute=True).key_by(args.id_col)
    # Subset mt to only individuals in phenofile then annotate MatrixTable with phenotypic data
    mt = mt.semi_join_cols(table)
    mt = mt.annotate_cols(pheno=table[mt.s])
    # Do a sample QC
    mt = hl.sample_qc(mt)
    # Filter for call rate.
    mt = mt.filter_cols(mt.sample_qc.call_rate >= args.call_rate_thr)
    # Split multi-allelic sites
    bi = mt.filter_rows(hl.len(mt.alleles) == 2).annotate_rows(a_index=1, was_split=False)
    multi = hl.split_multi_hts(mt.filter_rows(hl.len(mt.alleles) > 2))
    mt = multi.union_rows(bi)
    # Do a variant QC
    mt = hl.variant_qc(mt)
    mt = mt.annotate_rows(alt_allele_freq=mt.variant_qc.AF[1])
    # Filter for Allele Frequency
    mt = mt.filter_rows(mt.variant_qc.AF[1] > args.maf_thr)
    # Annotate Principal Components
    if args.pca is not None:
        eigenvalues, pcs, _ = hl.hwe_normalized_pca(mt.GT, k=args.pca)
        mt = mt.annotate_cols(scores=pcs[mt.s].scores)
    # Making covariates list
    covariates = [1.0]
    covariates += [mt.pheno[c] for c in args.cov.split(',')]
    if args.pca is not None:
        covariates += [mt.scores[i] for i in range(args.pca)]
    # Set output cols
    col_order = ['alt_allele_freq', 'n', 'beta', 'standard_error', 't_stat', 'p_value']
    extra_cols = ['alt_allele_freq']
    if 'rsid' in mt.row:
        col_order = ['rsid'] + col_order
        extra_cols += ['rsid']
    # Perform GWAS
    gwas = hl.linear_regression_rows(
        y=mt.pheno[args.response],
        x=mt.GT.n_alt_alleles(),
        covariates=covariates,
        pass_through=extra_cols
    )
    # Reformat gwas table
    gwas = (gwas
        .annotate(chrom=gwas['locus'].contig, pos=gwas['locus'].position, ref=gwas['alleles'][0], alt=gwas['alleles'][1])
        .key_by().drop('locus','alleles')
        .select(*(['chrom', 'pos', 'ref', 'alt'] + col_order))
    )
    # Write output TSV
    gwas.export(args.output)

    with open('genome_build', 'w') as f:
        print(genome_build, end='', file=f)

    print(f'\nYour GWAS results have been written to {args.output}')


###############################################################################
# Conditional to run the script
if __name__ == '__main__':
    main_program()
