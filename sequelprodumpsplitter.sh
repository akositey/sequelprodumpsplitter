#!/bin/sh

# Current Version: 1.0
# Extracts database, table, all databases, all tables or tables matching on regular expression from Sequel Pro exported dump.
# Includes output compression options.
# Follow GIT: https://github.com/akositey/sequelprodumpsplitter/
# Credits: Kedar Vaijanapurkar for creating mysqldumpsplitter which this project is based from

# ToDo: Work with straming input
## Formating Colour
# Text color variables
txtund=$(tput sgr 0 1)    # Underline
txtbld=$(tput bold)       # Bold
txtred=$(tput setaf 1)    # Red
txtgrn=$(tput setaf 2)    # Green
txtylw=$(tput setaf 3)    # Yellow
txtblu=$(tput setaf 4)    # Blue
txtpur=$(tput setaf 5)    # Purple
txtcyn=$(tput setaf 6)    # Cyan
txtwht=$(tput setaf 7)    # White
txtrst=$(tput sgr0)       # Text reset

## Variable Declaration
SOURCE='';
MATCH_STR='';
EXTRACT='';
OUTPUT_DIR='out';
EXT="sql.gz";
TABLE_NAME='';
DB_NAME='';
COMPRESSION='gzip';
DECOMPRESSION='cat';
VERSION=1.0

## Usage Description
usage()
{
        echo "\n\t\t\t\t\t\t\t${txtgrn}${txtund}************ Usage ************ \n"${txtrst};
        echo "${txtgrn}sh sequelprodumpsplitter.sh --source filename --extract [TABLE|ALLTABLES|REGEXP] --match_str string --compression [gzip|pigz|bzip2|none] --decompression [gzip|pigz|bzip2|none] --output_dir [path to output dir] [--config /path/to/config] ${txtrst}"
        echo "${txtund}                                                    ${txtrst}"
        echo "OPTIONS:"
        echo "${txtund}                                                    ${txtrst}"
        echo "  --source: Sequel Pro SQL dump filename to process. It could be a compressed or regular file."
        echo "  --desc: This option will list out all databases and tables."
        echo "  --extract: Specify what to extract. Possible values  TABLE, ALLTABLES, REGEXP"
        echo "  --match_str: Specify match string for extract command option."
        echo "  --compression: gzip/pigz/bzip2/none (default: gzip). Extracted file will be of this compression."
        echo "  --decompression: gzip/pigz/bzip2/none (default: gzip). This will be used against input file."
        echo "  --output_dir: path to output dir. (default: ./out/)"
        echo "  --config: path to config file. You may use --config option to specify the config file that includes following variables."
        echo "\t\tSOURCE=
\t\tEXTRACT=
\t\tCOMPRESSION=
\t\tDECOMPRESSION=
\t\tOUTPUT_DIR=
\t\tMATCH_STR=
"
        echo "${txtund}                                                    ${txtrst}"
        echo "Ver. $VERSION"
        exit 0;
}

## Parsing and processing input
parse_result()
{


        ## Validate SOURCE is provided and exists
        if [ -z "$SOURCE" ]; then
            echo "${txtred}ERROR: Source file not specified or does not exist. (Entered: $SOURCE)${txtrst}"
        elif [ ! -f "$SOURCE" ]; then
            echo "${txtred}ERROR: Source file does not exist. (Entered: $SOURCE)${txtrst}"
            exit 2;
        fi

        ## Parse Extract Operation
        case $EXTRACT in
                ALLTABLES|DESCRIBE)
                        if [ "$MATCH_STR" != '' ]; then
                            echo "${txtylw}Ignoring option --match_string.${txtrst}"
                        fi;
                         ;;
                TABLE|REGEXP)
                        if [ "$MATCH_STR" = '' ]; then
                            echo "${txtred}ERROR: Expecting input for option --match_string.${txtrst}"
                            exit 1;
                        fi;
                        ;;
                * )     echo "${txtred}ERROR: Please specify correct option for --extract.${txtrst}"
                        usage;
        esac;

        ## Parse compression
        if [ "$COMPRESSION" = 'none' ]; then
                COMPRESSION='cat';
                EXT="sql"
                echo "${txtgrn}Setting no compression.${txtrst}";
        elif [ "$COMPRESSION" = 'pigz' ]; then
                which $COMPRESSION &>/dev/null
                if [ $? -ne 0 ]; then
                        echo "${txtred}WARNING:$COMPRESSION appears having issues, using default gzip.${txtrst}";
                        COMPRESSION="gzip";
                fi;
                echo "${txtgrn}Setting compression as $COMPRESSION.${txtrst}";
                EXT="sql.gz"
        elif [ "$COMPRESSION" = 'bzip2' ]; then
                which $COMPRESSION &>/dev/null
                if [ $? -ne 0 ]; then
                        echo "${txtred}WARNING:$COMPRESSION appears having issues, using default gzip.${txtrst}";
                        COMPRESSION="gzip";
                fi;
                echo "${txtgrn}Setting compression as $COMPRESSION.${txtrst}";
                EXT="sql.bz2";
        else
                COMPRESSION='gzip';
                echo "${txtgrn}Setting compression $COMPRESSION (default).${txtrst}";
                EXT="sql.gz"
        fi;


        ## Parse  decompression
        if [ "$DECOMPRESSION" = 'none' ]; then
                DECOMPRESSION='cat';
                echo "${txtgrn}Setting no decompression.${txtrst}";
        elif [ "$DECOMPRESSION" = 'pigz' ]; then
                which $DECOMPRESSION &>/dev/null
                if [ $? -ne 0 ]; then
                        echo "${txtred}WARNING:$DECOMPRESSION appears having issues, using default gzip.${txtrst}";
                        DECOMPRESSION="gzip -d -c";
                else
                        DECOMPRESSION="pigz -d -c";
                fi;
                echo "${txtgrn}Setting decompression as $DECOMPRESSION.${txtrst}";
       elif [ "$DECOMPRESSION" = 'bzip2' ]; then
                which $DECOMPRESSION &>/dev/null
                if [ $? -ne 0 ]; then
                        echo "${txtred}WARNING:$DECOMPRESSION appears having issues, using default gzip.${txtrst}";
                        DECOMPRESSION="gzip -d -c";
                else
                        DECOMPRESSION="bzip2 -d -c";
                fi;
                echo "${txtgrn}Setting decompression as $DECOMPRESSION.${txtrst}";
        else
                DECOMPRESSION="gzip -d -c";
                echo "${txtgrn}Setting decompression $DECOMPRESSION (default).${txtrst}";
        fi;


        ## Verify file type:
        filecommand=`file "$SOURCE"`
        echo $filecommand | grep "compressed"  1>/dev/null
        if [ `echo $?` -eq 0 ]
        then
                echo "${txtylw}File $SOURCE is a compressed dump.${txtrst}"
                if [ "$DECOMPRESSION" = 'cat' ]; then
                        echo "${txtred} The input file $SOURCE appears to be a compressed dump. \n While the decompression is set to none.\n Please specify ${txtund}--decompression [gzip|bzip2|pigz]${txtrst}${txtred} argument.${txtrst}";
                        exit 1;
                fi;
        else
                echo "${txtylw}File $SOURCE is a regular dump.${txtrst}"
                if [ "$DECOMPRESSION" != 'cat' ]; then
                        echo "${txtred} Default decompression method for source is gzip. \n The input file $SOURCE does not appear a compressed dump. \n ${txtylw}We will try using no decompression. Please consider specifying ${txtund}--decompression none${txtrst}${txtylw} argument.${txtrst}";
                        DECOMPRESSION='cat'; ## Auto correct decompression to none for regular files.
                fi;
        fi;


        # Output directory
        if [ "$OUTPUT_DIR" = "" ]; then
                OUTPUT_DIR="out";
        fi;
        mkdir -p $OUTPUT_DIR
        if [ $? -eq 0 ]; then
                echo "${txtgrn}Setting output directory: $OUTPUT_DIR.${txtrst}";
        else
                echo "${txtred}ERROR:Issue while checking output directory: $OUTPUT_DIR.${txtrst}";
                exit 2;
        fi;

echo "${txtylw}Processing: Extract $EXTRACT $MATCH_STR from $SOURCE with compression option as $COMPRESSION and output location as $OUTPUT_DIR${txtrst}";

}

# Include first 20 lines of full Sequel Pro SQL dump - preserve time_zone/charset/environment variables.
include_dump_info()
{
        if [ $1 = "" ]; then
                echo "${txtred}Couldn't find out-put file while preserving time_zone/charset settings!${txtrst}"
                exit;
        fi;
        OUTPUT_FILE=$1

        echo "Including environment settings from Sequel Pro SQL dump."
        $DECOMPRESSION "$SOURCE" | head -20 | $COMPRESSION > $OUTPUT_DIR/$OUTPUT_FILE.$EXT
        echo "/* -- Splitted with sequelprodumpsplitter (https://github.com/akositey/sequelprodumpsplitter/) -- */" | $COMPRESSION >> $OUTPUT_DIR/$OUTPUT_FILE.$EXT
        echo "\n" | $COMPRESSION >> $OUTPUT_DIR/$tablename.$EXT
}

## Actual dump splitting
dump_splitter()
{
        case $EXTRACT in
                TABLE)
                        tablename=$MATCH_STR
                        # Include first 20 lines of standard Sequel Pro SQL dump to preserve time_zone and charset.
                        include_dump_info $tablename

                        #Loop for each tablename found in provided dumpfile
                        echo "Extracting $tablename."
                        #Extract table specific dump to tablename.sql
                        $DECOMPRESSION "$SOURCE" | sed -n -e "/^# Dump of table \b$tablename\b/,/UNLOCK TABLES;/p" | $COMPRESSION >> $OUTPUT_DIR/$tablename.$EXT
                        echo "${txtbld} Table $tablename  extracted from $SOURCE at $OUTPUT_DIR${txtrst}"
                        ;;

                ALLTABLES)
                        for tablename in $($DECOMPRESSION "$SOURCE" | grep "# Dump of table " | awk -F" " {'print $5'})
                        do
                         # Include first 20 lines of standard Sequel Pro SQL dump to preserve time_zone and charset.
                         include_dump_info $tablename

                         #Extract table specific dump to tablename.sql
                         $DECOMPRESSION "$SOURCE" | sed -n -e "/^# Dump of table \b$tablename\b/,/UNLOCK TABLES;/p" | $COMPRESSION >> $OUTPUT_DIR/$tablename.$EXT
                         TABLE_COUNT=$((TABLE_COUNT+1))
                         echo "${txtbld}Table $tablename extracted from $SOURCE at $OUTPUT_DIR/$tablename.$EXT${txtrst}"
                        done;
                         echo "${txtbld}Total $TABLE_COUNT tables extracted.${txtrst}"
                        ;;
                REGEXP)

                        TABLE_COUNT=0;
                        for tablename in $($DECOMPRESSION "$SOURCE" | grep -E "# Dump of table $MATCH_STR" | awk -F" " {'print $5'})
                        do
                         # Include first 20 lines of standard Sequel Pro SQL dump to preserve time_zone and charset.
                         include_dump_info $tablename

                         echo "Extracting $tablename..."
                                #Extract table specific dump to tablename.sql
                                $DECOMPRESSION "$SOURCE" | sed -n -e "/^# Dump of table \b$tablename\b/,/UNLOCK TABLES;/p" | $COMPRESSION >> $OUTPUT_DIR/$tablename.$EXT
                         echo "${txtbld}Table $tablename extracted from $SOURCE at $OUTPUT_DIR/$tablename.$EXT${txtrst}"
                                TABLE_COUNT=$((TABLE_COUNT+1))
                        done;
                        echo "${txtbld}Total $TABLE_COUNT tables extracted.${txtrst}"
                        ;;
                *)      echo "Wrong option, exiting.";
                        usage;
                        exit 1;;
        esac
}

missing_arg()
{
        echo "${txtred}ERROR:Missing argument $1.${txtrst}"
        exit 1;
}

if [ "$#" -eq 0 ]; then
        usage;
        exit 1;
fi

# Accepts Parameters
while [ "$1" != "" ]; do
    case $1 in
        --source|-S  )   shift
                if [ -z "$1" ]; then
                        missing_arg --source
                fi;
                SOURCE=$1 ;;

        --extract|-E  )   shift
                if [ -z $1 ]; then
                        missing_arg --extract
                fi;
                EXTRACT=$1 ;;
        --compression|-C  )   shift
                if [ -z $1 ]; then
                        missing_arg --compression
                fi;
                COMPRESSION=$1 ;;
        --decompression|-D) shift
                if [ -z $1 ]; then
                        missing_arg --decompression
                fi;
                DECOMPRESSION=$1 ;;
        --output_dir|-O  ) shift
                if [ -z $1 ]; then
                        missing_arg --output_dir
                fi;
                OUTPUT_DIR=$1 ;;
        --match_str|-M ) shift
                if [ -z $1 ]; then
                        missing_arg --match_str
                fi;
                MATCH_STR=$1 ;;
        --desc  )
                        EXTRACT="DESCRIBE"
                        parse_result
                        echo "-------------------------------";
                        echo "Database\t\tTables";
                        echo "-------------------------------";
                        $DECOMPRESSION "$SOURCE" | grep -E "(^# Database:|^# Dump of table)" | sed  's/# Database: /-------------------------------\n/' | sed 's/# Dump of table /\t\t/'| sed 's/`//g' ;
                        echo "-------------------------------";
                        exit 0;
                ;;

        --config        ) shift;
                if [ -z $1 ]; then
                        missing_arg --config
                fi;
                if [ ! -f $1 ]; then
                    echo "${txtred}ERROR: Config file $1 does not exist.${txtrst}"
                    exit 2;
                fi;
. ./$1 ;;
        -h  )   usage
                exit ;;
        * )     echo "";
                usage
                exit 1
    esac
    shift
done

parse_result
dump_splitter
exit 0;
