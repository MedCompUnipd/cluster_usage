#!/usr/bin/python3

import argparse
from tqdm import tqdm
import time
import tensorflow as tf


def get_args():
    parser = argparse.ArgumentParser()

    parser.add_argument('-n', '--iter', help='Number of iterations', required=False, default=10)

    return vars(parser.parse_args())


if __name__ == '__main__':
    args = get_args()
    iter = int(args['iter'])

    with tqdm(range(iter), desc='Progress bar implemented via tqdm') as pbar:
        for i in pbar:
            time.sleep(1)
            a = tf.zeros(i)
