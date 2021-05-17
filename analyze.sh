#!/bin/sh
# huge massive thanks to hunto

MLST=mlst.py
MLST_DB=/database
KMA=kma
FORCE=
ADDITIONAL_SPECIES=

show_help () {
	echo "Analyze sequences"
	echo $0 -m path/to/mlst -k path/to/kma -d path/to/mlst_db -o output_dir [-s species]* sample/directory
	echo
	echo This tool takes a list of directories named according to the primary species
	echo and analyses all contained fasta files with mlst
	echo
	echo -s: additional species to test, can be specified multiple times
	echo

}

while getopts "hm:o:d:k:s:f" opt; do
    case "$opt" in
    h)
        show_help
        exit 0
        ;;
    m)  MLST=$OPTARG
        ;;
    d)  MLST_DB=$OPTARG
        ;;
    k)  KMA=$OPTARG
        ;;
    o)  OUTPUT_FOLDER=$OPTARG
        ;;
    f)  FORCE=1
		;;
	s)  ADDITIONAL_SPECIES="$ADDITIONAL_SPECIES $OPTARG"
    esac
done

shift $((OPTIND-1))

[ "${1:-}" = "--" ] && shift

if [[ -z $OUTPUT_FOLDER ]]; then
	echo Must specify an output folder with -o >&2
	exit 1
fi

if [[ -e $OUTPUT_FOLDER ]]; then
	if [[ ! -d $OUTPUT_FOLDER ]]; then
	    echo Output folder already exists as a file >&2
	    exit 1
    fi
fi

if [[ ! -d $OUTPUT_FOLDER ]]; then
	mkdir $OUTPUT_FOLDER
fi

if [[ ! -d $KMA ]]; then
	echo Can\'t find kma executable in $KMA  >&2
	exit 1
fi

if [[ ! -e $MLST/mlst.py ]]; then
	echo Can\'t find mlst.py executable in $MLST  >&2
	exit 1
fi

if [[ ! -d $MLST_DB ]]; then
	echo $MLST_DB is not a valid mlst database >&2
	exit 1
fi

if [[ -z $@ ]]; then
	echo No input specified >&2
	exit 1
fi

AVAILABLE_SPECIES=""

for DBENTRY in $MLST_DB/*; do
	if [[ -d $DBENTRY ]]; then
		AVAILABLE_SPECIES="$AVAILABLE_SPECIES $(basename $DBENTRY)"
	fi
done




for SAMPLE_DIR in $@; do
	if [[ ! -d $SAMPLE_DIR ]]; then
		echo Cannot open $SAMPLE_DIR >&2
		exit 1
	fi
done

for SAMPLE_DIR in $@; do
	SPECIES=$(basename $SAMPLE_DIR)
	if [[ -e $OUTPUT_FOLDER/$SPECIES && -z FORCE ]]; then
		echo Output for $SPECIES already exists. >&2
		echo Exiting to avoid overwriting >&2
		exit 1
	fi
	if [[ "$AVAILABLE_SPECIES" != *"$SPECIES"* ]]; then
		echo $SPECIES is not a support species >&2
		echo Suppoted species: $AVAILABLE_SPECIES  >&2
		exit 1
	fi
	mkdir $OUTPUT_FOLDER/$SPECIES 2>/dev/null
done
for SPECIES in $ADDITIONAL_SPECIES; do
	if [[ "$AVAILABLE_SPECIES" != *"$SPECIES"* ]]; then
		echo $SPECIES is not a support species >&2
		echo Suppoted species: $AVAILABLE_SPECIES  >&2
		exit 1
	fi
done

for SAMPLE_DIR in $@; do
	SPECIES=$(basename $SAMPLE_DIR)
	for SAMPLE in $SAMPLE_DIR/*; do
		SAMPLE_OUTPUT_DIR=$OUTPUT_FOLDER/$SPECIES/$(basename $SAMPLE)
		mkdir $SAMPLE_OUTPUT_DIR 2>/dev/null
		SAMPLE_OUTPUT=`$MLST/mlst.py -o $SAMPLE_OUTPUT_DIR -i $SAMPLE -p $MLST_DB -mp $KMA/kma -s $SPECIES -x 2> /dev/null`
		if [[ "$SAMPLE_OUTPUT" == *"No MLST loci"* ]]; then
			echo Sample $SAMPLE does not match species $SPECIES
		else
			echo Sample $SAMPLE matches species $SPECIES
		fi
		for ADDITIONAL_SPECIE in $ADDITIONAL_SPECIES; do
			mkdir $OUTPUT_FOLDER/$SPECIES/$ADDITIONAL_SPECIE 2> /dev/null
			mkdir $OUTPUT_FOLDER/$SPECIES/$ADDITIONAL_SPECIE/$(basename $SAMPLE) 2> /dev/null
		done
		for ADDITIONAL_SPECIE in $ADDITIONAL_SPECIES; do
			SAMPLE_OUTPUT_DIR=$OUTPUT_FOLDER/$SPECIES/$ADDITIONAL_SPECIE/$(basename $SAMPLE)
			SAMPLE_OUTPUT=`$MLST/mlst.py -o $SAMPLE_OUTPUT_DIR -i $SAMPLE -p $MLST_DB -mp $KMA/kma -s $ADDITIONAL_SPECIE -x 2> /dev/null`
			if [[ "$SAMPLE_OUTPUT" == *"No MLST loci"* ]]; then
				echo Sample $SAMPLE does not match species $ADDITIONAL_SPECIE
				rm -rf $SAMPLE_OUTPUT_DIR
			else
				echo Sample $SAMPLE matches species $ADDITIONAL_SPECIE
			fi
		done
	done
done

