# sequelprodumpsplitter
	split / extract tables from Sequel Pro SQL dump.

## Usage
	`sh sequelprodumpsplitter.sh --source /path/to/dump <method> <options>`

	--source: path to Sequel Pro SQL dump file. It could be compressed or a sql file.

    Methods:
	--desc: this method will list out all databases and tables.
	--extract: this method accepts 3 possible values: TABLE(single table), ALLTABLES and REGEXP

	Options:
	--match_str: this option specifies the string to match when TABLE or REGEXP is specified in --extract method.
	--compression: format to use with the output files. Possible values: gzip/bzip2/none (default: gzip).
	--decompression: format used by the dump file. Possible values: gzip/bzip2/none (default: gzip).
	--output_dir: path to output directory. (default: ./out/)
	--config: path to config file. You may use --config option to specify the config file that includes following variables:
		SOURCE=
		EXTRACT=
		COMPRESSION=
		DECOMPRESSION=
		OUTPUT_DIR=
		MATCH_STR=


## Sample Recipes
#### Extract single table from Sequel Pro SQL dump:
	`sh sequelprodumpsplitter.sh --source filename --extract TABLE --match_str table-name`

	Above command will create sql for specified table from specified Sequel Pro SQL dump file and store it in compressed format to database-name.sql.gz.

#### Extract all table from Sequel Pro SQL dump:
	`sh sequelprodumpsplitter.sh --source filename --extract ALLTABLES`

	if the dump is not compressed, and you don't want to compress the output as well, you can do:
  	`sh sequelprodumpsplitter.sh --source filename --decompression none --compression none --extract ALLTABLES`

	Above command will extract all tables from specified Sequel Pro SQL dump file and store it in compressed format to individual table-name.sql.gz.

#### Extract tables matching regular expression from Sequel Pro SQL dump:

	`sh sequelprodumpsplitter.sh --source filename --extract REGEXP --match_str regular-expression`

	Above command will create sqls for tables matching specified regular expression from specified Sequel Pro SQL dump file and store it in compressed format to individual table-name.sql.gz.

#### Extract list of tables from Sequel Pro SQL dump:

	`sh sequelprodumpsplitter.sh --source filename --extract REGEXP --match_str '(table1|table2|table3)'`

	Above command will extract tables from the specified "filename" Sequel Pro SQL dump  file and store them in compressed format to individual table-name.sql.gz.

#### Extract all tables from Sequel Pro SQL dump in a different folder:
	`sh sequelprodumpsplitter.sh --source filename --extract ALLTABLES --output_dir /path/to/extracts/`

	Above command will extract all tables from specified Sequel Pro SQL dump file and extract tables in compressed format to individual files, table-name.sql.gz stored under /path/to/extracts/.
	The script will create the folder /path/to/extracts/ if not exists.

#### List content of the Sequel Pro SQL dump file
	`sh sequelprodumpsplitter.sh --source filename --desc`

	Above command will list databases and tables from the dump file.
