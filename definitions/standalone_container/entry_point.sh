#!/bin/bash


usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "OPTIONS:"
    echo "-h, --help:     |      Print this help message and exit       |"
    echo "                |                                             |"
    echo "-i, --input:    |      The input file to be parsed.           |     DEFAULT: /data/input/sample.txt"
    echo "-o, --output:   |      The output file where to save results. |     DEFAULT: /data/output/summary.txt"
    echo "-w, --owl:      |      The owl file to be parsed.             |     DEFAULT: /data/input/go.owl"
    echo "                |                                             |"
    exit 1
}


# DEFAULT
input_file="/data/input/sample.txt"
owl_file="/data/input/go.owl"
output_file="/data/output/summary.txt"


# ARGUMENT PARSING
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -w|--owl)
            if [[ $# -gt 1 && ! $2 == -* ]]; then
                if [ -f "$2" ]; then
                    case "$2" in
                        *.owl*) used_go=$(echo "$2" | awk -F/ '{print $NF}');;
                        *) echo 'ERROR: Gene ontology graph is not in the owl format.'; usage;;
                    esac
                else
                    echo "ERROR: must be a file, not a folder."
                    usage
                fi
            else
                echo "Expected argument after option -w/--owl!"
                usage
            fi
            shift
            shift;;

        -i|--input)
            if [[ $# -gt 1 && ! $2 == -* ]]; then
                if [ -f "$2" ]; then
                    input_file="$2"
                else
                    echo "This argument required a file, not a folder!"
                    usage
                fi
            else
                echo "Expected argument after option -i/--input!"
                usage
            fi
            shift
            shift;;

        -o|--output)
            if [[ $# -gt 1 && ! $2 == -* ]]; then
                if [ -f "$2" ]; then
                    input_file="$2"
                else
                    echo "This argument required a file, not a folder!"
                    usage
                fi
            else
                echo "Expected argument after option -o/--output!"
                usage
            fi
            shift
            shift;;

        -h|--help)
            usage;;

        *)
            echo "Error: Unknown option $1"
            usage;;
    esac
done


# THE ACTUAL CODE
python3 /data/src/parse_sample.py -i $input_file -o $output_file
python3 /data/src/parse_owl.py -i $owl_file
