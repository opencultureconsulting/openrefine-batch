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
./openrefine-batch.sh examples/powerhouse-museum/input/ examples/powerhouse-museum/config/ examples/powerhouse-museum/output/ examples/powerhouse-museum/cross/ 4G 2.7rc1 tsv --processQuotes=false --guessCellValueTypes=true
```

#### Options

```
./openrefine-batch.sh $inputdir $configdir $outputdir $crossdir $ram $version $inputformat $inputoptions
```

1. inputdir: path to directory with source files (multiple files may be imported into a single project [by providing a zip or tar.gz archive](https://github.com/OpenRefine/OpenRefine/wiki/Importers))
2. configdir: path to directory with [OpenRefine transformation rules (json files)](http://kb.refinepro.com/2012/06/google-refine-json-and-my-notepad-or.html)
3. outputdir: path to directory for exported files (and OpenRefine workspace)
4. crossdir: path to directory with additional OpenRefine projects (will be copied to workspace before transformation step to support the [cross function](https://github.com/OpenRefine/OpenRefine/wiki/GREL-Other-Functions#crosscell-c-string-projectname-string-columnname))
5. ram: maximum RAM for OpenRefine java heap space (default: 4G)
6. version: OpenRefine version (2.7rc1, 2.6rc2, 2.6rc1, dev)
7. inputformat: csv, tsv, xml, json, line-based, fixed-width, xlsx or ods
8. inputoptions: several options provided by [openrefine-client](https://hub.docker.com/r/felixlohmeier/openrefine-client/)

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
[03:27 felix ~/openrefine-batch (master *)]$ ./openrefine-batch.sh examples/powerhouse-museum/input/ examples/powerhouse-museum/config/ examples/powerhouse-museum/output/ examples/powerhouse-museum/cross/ 4G 2.7rc1 tsv --processQuotes=false --guessCellValueTypes=true
Input directory:        /home/felix/openrefine-batch/examples/powerhouse-museum/input
Input files:            phm-collection.tsv
Input format:           --format=tsv
Input options:          --processQuotes=false --guessCellValueTypes=true            
Config directory:       /home/felix/openrefine-batch/examples/powerhouse-museum/config
Transformation rules:   phm-transform.json
Cross directory:        /home/felix/openrefine-batch/examples/powerhouse-museum/cross
Cross projects:         
OpenRefine heap space:  4G
OpenRefine version:     2.7rc1
Docker container:       6b7eb36f-fc72-4040-b135-acee36948c13
Output directory:       /home/felix/openrefine-batch/examples/powerhouse-museum/output

begin: Mo 27. Feb 03:28:45 CET 2017

start OpenRefine server...
[sudo] password for felix: 
92499ecd252a8768ea5b57e0be0fb30fe6340eab67d28b1be158e0ad01f79419

import phm-collection.tsv...
New project: 2325849087106
Number of rows: 75814
 STARTED     ELAPSED %MEM %CPU   RSS
03:28:55       00:29 10.0  122 812208
save project and restart OpenRefine server...
02:29:28.170 [           ProjectManager] Saving all modified projects ... (4594ms)
02:29:36.414 [        project_utilities] Saved project '2325849087106' (8244ms)
6b7eb36f-fc72-4040-b135-acee36948c13
6b7eb36f-fc72-4040-b135-acee36948c13
f28de26b99475c4db09dbfb9ab3d445aa8127dedd08b8e729cb6b4d65c96bf38

begin project 2325849087106 @ Mo 27. Feb 03:29:52 CET 2017
transform phm-transform.json...
02:29:54.372 [                   refine] GET /command/core/get-models (2815ms)
02:29:57.525 [                  project] Loaded project 2325849087106 from disk in 3 sec(s) (3153ms)
02:29:57.640 [                   refine] POST /command/core/apply-operations (115ms)
 STARTED     ELAPSED %MEM %CPU   RSS
03:29:38       01:07 19.6  128 1588152
save project and restart OpenRefine server...
02:30:46.280 [           ProjectManager] Saving all modified projects ... (48640ms)
02:30:53.404 [        project_utilities] Saved project '2325849087106' (7124ms)
6b7eb36f-fc72-4040-b135-acee36948c13
6b7eb36f-fc72-4040-b135-acee36948c13
186b0bda0ca542642ce1875d55f8341648e05248eb359541b80191832783f40b
export to file 2325849087106.tsv...
02:31:08.149 [                   refine] GET /command/core/get-models (4039ms)
02:31:11.485 [                  project] Loaded project 2325849087106 from disk in 3 sec(s) (3336ms)
02:31:11.756 [                   refine] GET /command/core/get-all-project-metadata (271ms)
02:31:11.774 [                   refine] POST /command/core/export-rows/phm-collection.tsv.tsv (18ms)
 STARTED     ELAPSED %MEM %CPU   RSS
03:30:55       01:59 11.6 28.6 942900
restart OpenRefine server...
6b7eb36f-fc72-4040-b135-acee36948c13
6b7eb36f-fc72-4040-b135-acee36948c13
eb0f91675b5fbf21b4c17cceb6d93146876ea19316b7ab44af78a36f64ff1037
finished project 2325849087106 @ Mo 27. Feb 03:33:11 CET 2017

output (number of lines / size in bytes):
  167017 60527726 /home/felix/openrefine-batch/examples/powerhouse-museum/output/2325849087106.tsv

cleanup...
6b7eb36f-fc72-4040-b135-acee36948c13
6b7eb36f-fc72-4040-b135-acee36948c13

finish: Mo 27. Feb 03:33:17 CET 2017
```

### Todo

- [ ] howto for installation on Mac and Windows
- [ ] howto for extracting input options from OpenRefine GUI with Firefox network monitor
- [ ] use getopts for parsing of arguments
- [ ] add option to delete openrefine projects in output directory
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
