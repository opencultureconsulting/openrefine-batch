## OpenRefine batch processing (openrefine-batch.sh)

Shell script to run OpenRefine on Windows, Linux or Mac in batch mode (import, transform, export). This bash script automatically...

1. imports all data from a given directory into OpenRefine
2. transforms the data by applying OpenRefine transformation rules from all json files in another given directory and
3. finally exports the data in TSV (tab-separated values) format.

It orchestrates a [docker container for OpenRefine](https://hub.docker.com/r/felixlohmeier/openrefine/) (server) and a [docker container for a python client](https://hub.docker.com/r/felixlohmeier/openrefine-client/) that communicates with the OpenRefine API. By restarting the server after each process it reduces memory requirements to a minimum.

### Typical Workflow

- Step 1: Do some experiments with your data (or parts of it) in the graphical user interface of OpenRefine. If you are fine with all transformation rules, [extract the json code](http://kb.refinepro.com/2012/06/google-refine-json-and-my-notepad-or.html) and save it as file (e.g. transform.json).
- Step 2: Put your data and the json file(s) in two different directories and execute the script. The script will automatically import all data files in OpenRefine projects, apply the transformation rules in the json files to each project and export all projects in TSV-files.

### Install

Linux:

1. Install [Docker](https://docs.docker.com/engine/installation/#on-linux)
2. Open Terminal and enter `wget https://github.com/felixlohmeier/openrefine-batch/raw/master/openrefine-batch.sh && chmod +x openrefine-batch.sh`

Mac:

1. Install Docker
2. ...

Windows:

1. Install Docker
2. Install Cygwin with Bash
3. ...

### Usage

```
./openrefine-batch.sh input/ config/ output/
```

#### Example

clone or [download GitHub repository](https://github.com/felixlohmeier/openrefine-batch/archive/master.zip) to get example data

```
./openrefine-batch.sh examples/powerhouse-museum/input/ examples/powerhouse-museum/config/ examples/powerhouse-museum/output/ 4G tsv --processQuotes=false --guessCellValueTypes=true
```

#### Options

```
./openrefine-batch.sh $inputdir $configdir $outputdir $ram $inputformat $inputoptions
```

1. inputdir: path to directory with source files (multiple files may be imported into a single project by providing a zip or tar.gz archive)
2. configdir: path to directory with OpenRefine transformation rules (json files)
3. outputdir: path to directory for exported files (and temporary workspace)
4. ram: maximum RAM for OpenRefine java heap space (default: 4G)
5. inputformat: csv, tsv, xml, json, line-based, fixed-width, xlsx or ods
6. inputoptions: several options provided by [openrefine-client](https://hub.docker.com/r/felixlohmeier/openrefine-client/)

inputoptions (mandatory for xml, json, fixed-width, xslx, ods):
* `--recordPath=RECORDPATH` (xml, json): please provide path in multiple arguments without slashes, e.g. /collection/record/ should be entered like this: `--recordPath=collection --recordPath=record`
* `--columnWidths=COLUMNWIDTHS` (fixed-width): please provide widths separated by comma (e.g. 7,5)
* `--sheets=SHEETS` (xlsx, ods): please provide sheets separated by comma (e.g. 0,1), default: 0 (first sheet)

more inputoptions (optional, only together with inputformat):
* `--limit=LIMIT` (all formats), default: -1
* `--includeFileSources=INCLUDEFILESOURCES` (all formats), default: false
* `--trimStrings=TRIMSTRINGS` (xml, json), default: false
* `--storeEmptyStrings=STOREEMPTYSTRINGS` (xml, json), default: true
* `--guessCellValueTypes=GUESSCELLVALUETYPES (xml, csv, tsv, fixed-width, json)`, default: false
* `--encoding=ENCODING (csv, tsv, line-based, fixed-width)`, please provide short encoding name (e.g. UTF-8)
* `--ignoreLines=IGNORELINES (csv, tsv, line-based, fixed-width, xlsx, ods)`, default: -1
* `--headerLines=HEADERLINES` (csv, tsv, fixed-width, xlsx, ods), default: 1
* `--skipDataLines=SKIPDATALINES` (csv, tsv, line-based, fixed-width, xlsx, ods), default: 0
* `--storeBlankRows=STOREBLANKROWS` (csv, tsv, line-based, fixed-width, xlsx, ods), default: true
* `--processQuotes=PROCESSQUOTES` (csv, tsv), default: true
* `--storeBlankCellsAsNulls=STOREBLANKCELLSASNULLS` (csv, tsv, line-based, fixed-width, xlsx, ods), default: true
* `--linesPerRow=LINESPERROW` (line-based), default: 1

### Logging

The script uses `docker attach` to print log messages from OpenRefine server and `ps` to show statistics for each step. Here is a sample log:

```
[00:08 felix ~/openrefine/openrefine-batch]$ ./openrefine-batch.sh examples/powerhouse-museum/input/ examples/powerhouse-museum/config/ examples/powerhouse-museum/output/ 4G tsv --processQuotes=false --guessCellValueTypes=true
Input dir:              /home/felix/occcloud/Openness/Kunden+Projekte/OpenRefine/openrefine-batch/examples/powerhouse-museum/input
Input files:            phm-collection.tsv
Input format:           --format=tsv
Input options:          --processQuotes=false --guessCellValueTypes=true        
Transformation rules:   phm-transform.json
OpenRefine heap space:  4G
OpenRefine version:     2.7rc1
Docker container:       41ca6232-8484-40e0-a606-3bcbf29903f6
Output directory:       /home/felix/occcloud/Openness/Kunden+Projekte/OpenRefine/openrefine-batch/examples/powerhouse-museum/output

begin: Mo 27. Feb 00:08:02 CET 2017

start OpenRefine server...
[sudo] password for felix: 
fab9894d902372767cdb38d05b6e247dce722da22192d734862fc2f096a23d51

import phm-collection.tsv...
New project: 1719405033732
Number of rows: 75814
 STARTED     ELAPSED %MEM %CPU   RSS
00:08:13       00:29 10.0  122 813604
save project and restart OpenRefine server...
23:08:46.130 [           ProjectManager] Saving all modified projects ... (4679ms)
23:08:55.190 [        project_utilities] Saved project '1719405033732' (9060ms)
41ca6232-8484-40e0-a606-3bcbf29903f6
41ca6232-8484-40e0-a606-3bcbf29903f6
6bb7ee1f1f2a1d09e191a3fadad9e26aaa89414b2c618a47d3d3ef7c040c6b1a

begin project 1719405033732 @ Mo 27. Feb 00:09:12 CET 2017
transform phm-transform.json...
23:09:13.747 [                   refine] GET /command/core/get-models (2489ms)
23:09:16.887 [                  project] Loaded project 1719405033732 from disk in 3 sec(s) (3140ms)
23:09:17.140 [                   refine] POST /command/core/apply-operations (253ms)
 STARTED     ELAPSED %MEM %CPU   RSS
00:08:57       01:10 20.1  124 1625788
save project and restart OpenRefine server...
23:10:07.930 [           ProjectManager] Saving all modified projects ... (50790ms)
23:10:15.173 [        project_utilities] Saved project '1719405033732' (7243ms)
41ca6232-8484-40e0-a606-3bcbf29903f6
41ca6232-8484-40e0-a606-3bcbf29903f6
cc9c49dcaf54c720d915a55b4e646909f657fb6582c0ac3c9f069996b9cd0b53
export to file 1719405033732.tsv...
23:10:29.972 [                   refine] GET /command/core/get-models (4381ms)
23:10:33.826 [                  project] Loaded project 1719405033732 from disk in 3 sec(s) (3854ms)
23:10:34.123 [                   refine] GET /command/core/get-all-project-metadata (297ms)
23:10:34.140 [                   refine] POST /command/core/export-rows/phm-collection.tsv.tsv (17ms)
 STARTED     ELAPSED %MEM %CPU   RSS
00:10:17       02:01 12.8 27.2 1041596
save project and restart OpenRefine server...
41ca6232-8484-40e0-a606-3bcbf29903f6
41ca6232-8484-40e0-a606-3bcbf29903f6
8e1febaf862c2e0bb162c6dfe968015b54f600d6b45f8d1a401b74e7285bc521
finished project 1719405033732 @ Mo 27. Feb 00:12:36 CET 2017

cleanup...
41ca6232-8484-40e0-a606-3bcbf29903f6
41ca6232-8484-40e0-a606-3bcbf29903f6

output (number of lines / size in bytes):
  167017 60527726 /home/felix/occcloud/Openness/Kunden+Projekte/OpenRefine/openrefine-batch/examples/powerhouse-museum/output/1719405033732.tsv

finish: Mo 27. Feb 00:12:42 CET 2017
```

### Todo

- [ ] howto for installation on Mac and Windows
- [ ] howto for extracting input options from OpenRefine GUI with Firefox network monitor
- [ ] use getopts for parsing of arguments
- [ ] provide more example data from other OpenRefine tutorials

### Licensing

MIT License

Copyright (c) 2017 Felix Lohmeier

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
