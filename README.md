# mlst-db-run
This is a bash script that iterates over fastq files to run against the CGE MLST database and output results.

analyze.sh is run from the command line with this set up:
$bash analyze.sh -m ~/mlst -d ~/mlst_db  -k ~/kma -o test kpneumoniae
(script name) (-m location of mlst directory) (-d location of mlst database directory) (-k  location of kma directory) (-o folder to output results to) (the mlst_db entry matching the species)

