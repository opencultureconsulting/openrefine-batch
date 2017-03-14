## OpenRefine batch processing (openrefine-batch.sh)

Shell script to run OpenRefine in batch mode (import, transform, export). This bash script automatically...

1. imports all data from a given directory into OpenRefine
2. transforms the data by applying OpenRefine transformation rules from all json files in another given directory and
3. finally exports the data in TSV (tab-separated values) format.

It orchestrates [OpenRefine](https://github.com/OpenRefine/OpenRefine) (server) and a [python client](https://github.com/felixlohmeier/openrefine-client) that communicates with the OpenRefine API. By restarting the server after each process it reduces memory requirements to a minimum.

If you prefer a containerized approach, see a [variation of this script for Docker](#docker) below.

### Typical Workflow

- **Step 1**: Do some experiments with your data (or parts of it) in the graphical user interface of OpenRefine. If you are fine with all transformation rules, [extract the json code](http://kb.refinepro.com/2012/06/google-refine-json-and-my-notepad-or.html) and save it as file (e.g. transform.json).
- **Step 2**: Put your data and the json file(s) in two different directories and execute the script. The script will automatically import all data files in OpenRefine projects, apply the transformation rules in the json files to each project and export all projects in TSV-files.

### Install

Download the script and grant file permissions to execute: `wget https://github.com/felixlohmeier/openrefine-batch/raw/master/openrefine-batch.sh && chmod +x openrefine-batch.sh`

That's all. The script will automatically download copies of OpenRefine and the python client on first run and will tell you if something (python, java) is missing.

### Usage

```
mkdir input
cp INPUTFILES input/
mkdir config
cp CONFIGFILES config/
./openrefine-batch.sh input/ config/ OUTPUT/
```

**INPUTFILES**
* any data that [OpenRefine supports](https://github.com/OpenRefine/OpenRefine/wiki/Importers). CSV, TSV and line-based files should work out of the box. XML, JSON, fixed-width, XSLX and ODS need one additional input parameter (see chapter [Options](https://github.com/felixlohmeier/openrefine-batch#options) below)
* multiple slices of data may be transformed into a into a single file [by providing a zip or tar.gz archive](https://github.com/OpenRefine/OpenRefine/wiki/Importers)
* you may use hard symlinks instead of cp: `ln INPUTFILE input/`

**CONFIGFILES**
* JSON files with [OpenRefine transformation rules)](http://kb.refinepro.com/2012/06/google-refine-json-and-my-notepad-or.html)

**OUTPUT/**
* path to directory where results and temporary data should be stored
* Transformed data will be stored in this directory in TSV (tab-separated values) format. Show results: `ls OUTPUT/*.tsv`
* OpenRefine stores data in directories like "1234567890123.project". You may have a look at the results by starting OpenRefine with this workspace. Delete the directories if you do not need them: `rm -r -f OUTPUT/*.project`

### Example

[Example Powerhouse Museum](examples/powerhouse-museum)

```
./openrefine-batch.sh \
-a examples/powerhouse-museum/input/ \
-b examples/powerhouse-museum/config/ \
-c examples/powerhouse-museum/output/ \
-f tsv \
-i processQuotes=false \
-i guessCellValueTypes=true \
-RX
```

clone or [download GitHub repository](https://github.com/felixlohmeier/openrefine-batch/archive/master.zip) to get example data

### Help Screen

```
[18:20 felix ~/openrefine-batch]$ ./openrefine-batch.sh
Usage: ./openrefine-batch.sh [-a INPUTDIR] [-b TRANSFORMDIR] [-c OUTPUTDIR] ...

== basic arguments ==
    -a INPUTDIR      path to directory with source files (leave empty to transform only ; multiple files may be imported into a single project by providing a zip or tar.gz archive, cf. https://github.com/OpenRefine/OpenRefine/wiki/Importers )
    -b TRANSFORMDIR  path to directory with OpenRefine transformation rules (json files, cf. http://kb.refinepro.com/2012/06/google-refine-json-and-my-notepad-or.html ; leave empty to transform only)
    -c OUTPUTDIR     path to directory for exported files (and OpenRefine workspace)

== options ==
    -d CROSSDIR      path to directory with additional OpenRefine projects (will be copied to workspace before transformation step to support the cross function, cf. https://github.com/OpenRefine/OpenRefine/wiki/GREL-Other-Functions )
    -f INPUTFORMAT   (csv, tsv, xml, json, line-based, fixed-width, xlsx, ods)
    -i INPUTOPTIONS  several options provided by openrefine-client, see below...
    -m RAM           maximum RAM for OpenRefine java heap space (default: 2048M)
    -p PORT          PORT on which OpenRefine should listen (default: 3333)
    -E               do NOT export files
    -R               do NOT restart OpenRefine after each transformation (e.g. config file)
    -X               do NOT restart OpenRefine after each project (e.g. input file)
    -h               displays this help screen

== inputoptions (mandatory for xml, json, fixed-width, xslx, ods) ==
    -i recordPath=RECORDPATH (xml, json): please provide path in multiple arguments without slashes, e.g. /collection/record/ should be entered like this: --recordPath=collection --recordPath=record
    -i columnWidths=COLUMNWIDTHS (fixed-width): please provide widths separated by comma (e.g. 7,5)
    -i sheets=SHEETS (xlsx, ods): please provide sheets separated by comma (e.g. 0,1), default: 0 (first sheet)

== more inputoptions (optional, only together with inputformat) ==
    -i projectName=PROJECTNAME (all formats)
    -i limit=LIMIT (all formats), default: -1
    -i includeFileSources=INCLUDEFILESOURCES (all formats), default: false
    -i trimStrings=TRIMSTRINGS (xml, json), default: false
    -i storeEmptyStrings=STOREEMPTYSTRINGS (xml, json), default: true
    -i guessCellValueTypes=GUESSCELLVALUETYPES (xml, csv, tsv, fixed-width, json), default: false
    -i encoding=ENCODING (csv, tsv, line-based, fixed-width), please provide short encoding name (e.g. UTF-8)
    -i ignoreLines=IGNORELINES (csv, tsv, line-based, fixed-width, xlsx, ods), default: -1
    -i headerLines=HEADERLINES (csv, tsv, fixed-width, xlsx, ods), default: 1
    -i skipDataLines=SKIPDATALINES (csv, tsv, line-based, fixed-width, xlsx, ods), default: 0
    -i storeBlankRows=STOREBLANKROWS (csv, tsv, line-based, fixed-width, xlsx, ods), default: true
    -i processQuotes=PROCESSQUOTES (csv, tsv), default: true
    -i storeBlankCellsAsNulls=STOREBLANKCELLSASNULLS (csv, tsv, line-based, fixed-width, xlsx, ods), default: true
    -i linesPerRow=LINESPERROW (line-based), default: 1

== example ==

./openrefine-batch.sh -a examples/powerhouse-museum/input/ -b examples/powerhouse-museum/config/ -c examples/powerhouse-museum/output/ -f tsv -i processQuotes=false -i guessCellValueTypes=true

clone or download GitHub repository to get example data:
https://github.com/felixlohmeier/openrefine-batch/archive/master.zip

```

### Logging

The script prints log messages from OpenRefine server and makes use of `ps` to show statistics for each step. Here is a sample:

```
[17:55 felix ~/openrefine-batch]$ ./openrefine-batch.sh \
> -a examples/powerhouse-museum/input/ \
> -b examples/powerhouse-museum/config/ \
> -c examples/powerhouse-museum/output/ \
> -f tsv \
> -i processQuotes=false \
> -i guessCellValueTypes=true \
> -RX
Input directory:         /home/felix/openrefine-batch/examples/powerhouse-museum/input
Input files:             phm-collection.tsv
Input format:            --format=tsv
Input options:           --processQuotes=false --guessCellValueTypes=true
Config directory:        /home/felix/openrefine-batch/examples/powerhouse-museum/config
Transformation rules:    phm-transform.json
Cross directory:         /dev/null
Cross projects:          
OpenRefine heap space:   2048M
OpenRefine port:         3333
OpenRefine workspace:    /home/felix/openrefine-batch/examples/powerhouse-museum/output
Export TSV to workspace: true
restart after file:      false
restart after transform: false

=== 1. Launch OpenRefine ===

starting time: Di 14. Mär 17:58:08 CET 2017

Starting OpenRefine at 'http://127.0.0.1:3333/'

17:58:08.758 [            refine_server] Starting Server bound to '127.0.0.1:3333' (0ms)
17:58:08.760 [            refine_server] refine.memory size: 2048M JVM Max heap: 1908932608 (2ms)
17:58:08.787 [            refine_server] Initializing context: '/' from '/home/felix/openrefine-batch/openrefine/webapp' (27ms)
17:58:09.463 [                   refine] Starting OpenRefine 2.7-rc.1 [TRUNK]... (676ms)
17:58:09.476 [       FileProjectManager] Failed to load workspace from any attempted alternatives. (13ms)
17:58:12.003 [                   refine] Running in headless mode (2527ms)

=== 2. Import all files ===

starting time: Di 14. Mär 17:58:12 CET 2017

import phm-collection.tsv...
17:58:13.068 [                   refine] POST /command/core/create-project-from-upload (1065ms)
New project: 2073385535316
17:58:26.543 [                   refine] GET /command/core/get-rows (13475ms)
Number of rows: 75814
 STARTED     ELAPSED %MEM %CPU   RSS
17:58:07       00:18  9.8  168 795024

=== 3. Prepare transform & export ===

starting time: Di 14. Mär 17:58:26 CET 2017

get project ids...
17:58:26.778 [                   refine] GET /command/core/get-all-project-metadata (235ms)
 2073385535316: phm-collection.tsv

=== 4. Transform phm-collection.tsv ===

starting time: Di 14. Mär 17:58:26 CET 2017

transform phm-transform.json...
17:58:26.917 [                   refine] GET /command/core/get-models (139ms)
17:58:26.934 [                   refine] POST /command/core/apply-operations (17ms)
 STARTED     ELAPSED %MEM %CPU   RSS
17:58:07       01:02 13.5  134 1096916


=== 5. Export phm-collection.tsv ===

starting time: Di 14. Mär 17:59:09 CET 2017

export to file phm-collection.tsv...
17:59:09.944 [                   refine] GET /command/core/get-models (43010ms)
17:59:09.956 [                   refine] GET /command/core/get-all-project-metadata (12ms)
17:59:09.967 [                   refine] POST /command/core/export-rows/phm-collection.tsv.tsv (11ms)
 STARTED     ELAPSED %MEM %CPU   RSS
17:58:07       02:24 13.5 60.5 1098056


output (number of lines / size in bytes):
  167017 60527726 /home/felix/openrefine-batch/examples/powerhouse-museum/output/phm-collection.tsv

cleanup...
18:00:35.425 [           ProjectManager] Saving all modified projects ... (85458ms)
18:00:42.357 [        project_utilities] Saved project '2073385535316' (6932ms)

=== Statistics ===

starting time and run time of each step:
                      Start process Di 14. Mär 17:58:08 CET 2017 (00:00:00)
                  Launch OpenRefine Di 14. Mär 17:58:08 CET 2017 (00:00:04)
                   Import all files Di 14. Mär 17:58:12 CET 2017 (00:00:14)
         Prepare transform & export Di 14. Mär 17:58:26 CET 2017 (00:00:00)
       Transform phm-collection.tsv Di 14. Mär 17:58:26 CET 2017 (00:00:43)
          Export phm-collection.tsv Di 14. Mär 17:59:09 CET 2017 (00:01:34)
                        End process Di 14. Mär 18:00:43 CET 2017 (00:00:00)

total run time: 00:02:35 (hh:mm:ss)
highest memory load: 1072 MB
```

### Docker

A variation of the shell script orchestrates a [docker container for OpenRefine](https://hub.docker.com/r/felixlohmeier/openrefine/) (server) and a [docker container for the python client](https://hub.docker.com/r/felixlohmeier/openrefine-client/) instead of native applications.

**Install**

1. Install [Docker](https://docs.docker.com/engine/installation/#on-linux) and **a)** [configure Docker to start on boot](https://docs.docker.com/engine/installation/linux/linux-postinstall/#configure-docker-to-start-on-boot) or **b)** start Docker on demand each time you use the script: `sudo systemctl start docker`
2. Download the script and grant file permissions to execute: `wget https://github.com/felixlohmeier/openrefine-batch/raw/master/openrefine-batch-docker.sh && chmod +x openrefine-batch-docker.sh`

**Usage**

```
mkdir input
cp INPUTFILES input/
mkdir config
cp CONFIGFILES config/
sudo ./openrefine-batch-docker.sh input/ config/ OUTPUT/
```

Why `sudo`? Non-root users can only access the Unix socket of the Docker daemon by using `sudo`. If you created a Docker group in [Post-installation steps for Linux](https://docs.docker.com/engine/installation/linux/linux-postinstall/) then you may call the script without `sudo`.

### Todo

- [ ] howto for extracting input options from OpenRefine GUI with Firefox network monitor
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
