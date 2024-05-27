#!/usr/bin/env python3

import argparse
import os
from owlready2 import *


def get_args():
    parser = argparse.ArgumentParser()

    parser.add_argument('-i', '--input',  help='go.owl file containing the ontology', required=True)
    parser.add_argument('-o', '--output',  help='go.owl file containing the ontology', required=True)

    return vars(parser.parse_args())


if __name__ == "__main__":
    args = get_args()
    input_file = args['input']
    output_file = args['output']

    if not os.path.exists(input_file):
        print(f'Input constraints file provided {input_file} does not exist!', file=sys.stderr)
        raise FileNotFoundError

    out_path, basename = os.path.split(output_file)
    if not os.path.exists(out_path):
        print(f'WARNING: output directory {out_path} does not exist, creating it', file=sys.stderr)
        os.makedirs(out_path)

    with open(input_file, 'r') as fp:
        first, second, third = set(), set(), set()
        for line in fp:
            data = line.strip().split('\t')
            first.add(data[0])
            second.add(data[1])
            third.add(data[2])

    with open(output_file, 'w') as fp:
        fp.write('Summary for the given input file:\n\n')
        fp.write(f'First column has {len(first)} unique fields\n')
        fp.write(f'Second column has {len(second)} unique fields\n')
        fp.write(f'Third column has {len(third)} unique fields\n')
