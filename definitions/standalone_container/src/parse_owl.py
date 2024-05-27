#!/usr/bin/env python3

import argparse
import os
from owlready2 import *


def get_args():
    parser = argparse.ArgumentParser()

    parser.add_argument('-i', '--input',  help='go.owl file containing the ontology', required=True)

    return vars(parser.parse_args())


if __name__ == "__main__":
    args = get_args()
    owl_file = args['input']

    if not os.path.exists(owl_file):
        print(f'Input constraints file provided {owl_file} does not exist!', file=sys.stderr)
        raise FileNotFoundError

    owl = GoOwl(owl_file, namespace="http://purl.obolibrary.org/obo/")
    bpo = set(owl.go_descentants_by_ontology_using_valid_edges('GO_0008150'))
    mfo = set(owl.go_descentants_by_ontology_using_valid_edges('GO_0003674'))
    cco = set(owl.go_descentants_by_ontology_using_valid_edges('GO_0005575'))

    print('ONTOLOGY SUMMARY\n')
    print(f'Biological Process ontology has {len(bpo)} go terms')
    print(f'Molecular Function ontology has {len(mfo)} go terms')
    print(f'Cellular Component ontology has {len(cco)} go terms')
