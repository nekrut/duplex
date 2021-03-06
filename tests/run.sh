#!/usr/bin/env bash
if [ x$BASH = x ] || [ ! $BASH_VERSINFO ] || [ $BASH_VERSINFO -lt 4 ]; then
  echo "Error: Must use bash version 4+." >&2
  exit 1
fi
# get the name of the test directory
dirname=$(dirname $0)

USAGE="Usage: \$ $(basename $0) [options] [test1 [test2]]"


function main {

  do_all=true
  verbose=true
  # Run the requested tests
  for arg in "$@"; do
    # Check for options
    #TODO: option to keep test data at end instead of removing it.
    if [[ ${arg:0:1} == '-' ]]; then
      case "$arg" in
        -h)
          echo "$USAGE" >&2
          echo "Currently valid tests:" >&2
          list_tests >&2
          exit 1;;
        -q)
          verbose='';;
        -v)
          verbose=true;;
        *)
          echo "Unrecognized option \"$arg\"." >&2;;
      esac
      continue
    fi
    # Execute valid tests (if they're existing functions).
    if [[ $(type -t $arg) == function ]]; then
      do_all=''
      if [[ $verbose ]]; then
        $arg
      else
        $arg 2>/dev/null
      fi
    else
      echo "Unrecognized test \"$arg\"." >&2
      do_all=''
    fi
  done

  # If no tests were specified in arguments, do all tests.
  if [[ $do_all ]]; then
    if [[ $verbose ]]; then
      all
    else
      all 2>/dev/null
    fi
  fi
}

function fail {
  echo "$@" >&2
  exit 1
}

function list_tests {
  while read declare f test; do
    # Filter out functions that aren't tests.
    if echo "$initial_declarations" | grep -qF 'declare -f '"$test"; then
      continue
    else
      echo "$test"
    fi
  done < <(declare -F)
}

# Capture a list of all functions defined before the tests, to tell which are actual functions
# and which are tests.
initial_declarations=$(declare -F)

########## Functional tests ##########

# Do all tests.
function all {
  align
  duplex
  duplex_qual
  stats_diffs
}

# align_families.py
function align {
  echo -e "\talign_families.py ::: families.in.tsv:"
  python "$dirname/../align_families.py" "$dirname/families.in.tsv" | diff -s - "$dirname/families.msa.tsv"
}

# duplex.py defaults on toy data
function duplex {
  echo -e "\tduplex.py ::: families.msa.tsv:"
  python "$dirname/../duplex.py" "$dirname/families.msa.tsv" | diff -s - "$dirname/families.cons.fa"
  python "$dirname/../duplex.py" --incl-sscs "$dirname/families.msa.tsv" | diff -s - "$dirname/families.cons.incl-sscs.fa"
}

# duplex.py quality score consideration
function duplex_qual {
  echo -e "\tduplex.py ::: qual.msa.tsv:"
  python "$dirname/../duplex.py" --incl-sscs -q 20 "$dirname/qual.msa.tsv" | diff -s - "$dirname/qual.cons.fa"
}

function duplex_gapqual {
  echo -e "\tduplex.py ::: gapqual.msa.tsv:"
  python "$dirname/../duplex.py" --incl-sscs -q 25 "$dirname/gapqual.msa.tsv" | diff -s - "$dirname/gapqual.cons.fa"
}

function stats_diffs {
  echo -e "\tstats.py diffs ::: gaps.msa.tsv:"
  python "$dirname/../stats.py" diffs "$dirname/gaps.msa.tsv" | diff -s - "$dirname/gaps-diffs.out.tsv"
}

main "$@"
