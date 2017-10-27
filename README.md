## OpenRefine batch processing (openrefine-batch.sh)

[![Codacy Badge](https://api.codacy.com/project/badge/Grade/66bf001c38194f5bb722f65f5e15f0ec)](https://www.codacy.com/app/mail_74/openrefine-batch?utm_source=github.com&utm_medium=referral&utm_content=opencultureconsulting/openrefine-batch&utm_campaign=badger)

Shell script to run OpenRefine in batch mode (import, transform, export). This bash script automatically...

1. imports all data from a given directory into OpenRefine
2. transforms the data by applying OpenRefine transformation rules from all json files in another given directory and
3. finally exports the data in csv, tsv, html, xlsx or ods.

It orchestrates [OpenRefine](https://github.com/OpenRefine/OpenRefine) (server) and a [python client](https://github.com/felixlohmeier/openrefine-client) that communicates with the OpenRefine API. By restarting the server after each process it reduces memory requirements to a minimum.

If you prefer a containerized approach, see a [variation of this script for Docker](#docker) below.

### Typical Workflow

- **Step 1**: Do some experiments with your data (or parts of it) in the graphical user interface of OpenRefine. If you are fine with all transformation rules, [extract the json code](http://kb.refinepro.com/2012/06/google-refine-json-and-my-notepad-or.html) and save it as file (e.g. transform.json).
- **Step 2**: Put your data and the json file(s) in two different directories and execute the script. The script will automatically import all data files in OpenRefine projects, apply the transformation rules in the json files to each project and export all projects to files in the format specified (default: TSV - tab-separated values).

### Install

Download the script and grant file permissions to execute: `wget https://github.com/felixlohmeier/openrefine-batch/raw/master/openrefine-batch.sh && chmod +x openrefine-batch.sh`

That's all. The script will automatically download copies of OpenRefine and the python client on first run and will tell you if something (python, java) is missing.

### Usage

```
mkdir input
cp INPUTFILES input/
mkdir config
cp CONFIGFILES config/
./openrefine-batch.sh -a input/ -b config/ -c OUTPUT/
```

**INPUTFILES**
* any data that [OpenRefine supports](https://github.com/OpenRefine/OpenRefine/wiki/Importers). CSV, TSV and line-based files should work out of the box. XML, JSON, fixed-width, XSLX and ODS need one additional input parameter (see chapter [Options](https://github.com/felixlohmeier/openrefine-batch#options) below)
* multiple slices of data may be transformed into a into a single file [by providing a zip or tar.gz archive](https://github.com/OpenRefine/OpenRefine/wiki/Importers)
* you may use hard symlinks instead of cp: `ln INPUTFILE input/`

**CONFIGFILES**
* JSON files with [OpenRefine transformation rules)](http://kb.refinepro.com/2012/06/google-refine-json-and-my-notepad-or.html)

**OUTPUT/**
* path to directory where results and temporary data should be stored
* Transformed data will be stored in this directory in the format specified (default: TSV). Show results: `ls OUTPUT/*.tsv`
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
[14:45 felix ~/openrefine-batch]$ ./openrefine-batch.sh
Usage: ./openrefine-batch.sh [-a INPUTDIR] [-b TRANSFORMDIR] [-c OUTPUTDIR] ...

== basic arguments ==
    -a INPUTDIR      path to directory with source files (leave empty to transform only ; multiple files may be imported into a single project by providing a zip or tar.gz archive, cf. https://github.com/OpenRefine/OpenRefine/wiki/Importers )
    -b TRANSFORMDIR  path to directory with OpenRefine transformation rules (json files, cf. http://kb.refinepro.com/2012/06/google-refine-json-and-my-notepad-or.html ; leave empty to transform only)
    -c OUTPUTDIR     path to directory for exported files (and OpenRefine workspace)

== options ==
    -d CROSSDIR      path to directory with additional OpenRefine projects (will be copied to workspace before transformation step to support the cross function, cf. https://github.com/OpenRefine/OpenRefine/wiki/GREL-Other-Functions )
    -e EXPORTFORMAT  (csv, tsv, html, xls, xlsx, ods)
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

./openrefine-batch.sh -a examples/powerhouse-museum/input/ -b examples/powerhouse-museum/config/ -c examples/powerhouse-museum/output/ -f tsv -i processQuotes=false -i guessCellValueTypes=true -RX

clone or download GitHub repository to get example data:
https://github.com/felixlohmeier/openrefine-batch/archive/master.zip
```

### Logging

The script prints log messages from OpenRefine server and makes use of `ps` to show statistics for each step. Here is a sample:

```
[00:41 felix ~/openrefine-batch]$ ./openrefine-batch.sh -a examples/powerhouse-museum/input/ -b examples/powerhouse-museum/config/ -c examples/powerhouse-museum/output/ -f tsv -i processQuotes=false -i guessCellValueTypes=true -RX
Download OpenRefine...
openrefine-linux-2017-10-26.tar.gz                   100%[=====================================================================================================================>]  66,34M  5,62MB/s    in 12s     
Install OpenRefine in subdirectory openrefine...
Total bytes read: 79861760 (77MiB, 128MiB/s)

Download OpenRefine client...
openrefine-client_0-3-1_linux-64bit                  100%[=====================================================================================================================>]   5,39M  5,08MB/s    in 1,1s    

Input directory:         /home/felix/owncloud/Business/projekte/openrefine/openrefine-batch/examples/powerhouse-museum/input
Input files:             phm-collection.tsv
Input format:            --format=tsv
Input options:           --processQuotes=false --guessCellValueTypes=true
Config directory:        /home/felix/owncloud/Business/projekte/openrefine/openrefine-batch/examples/powerhouse-museum/config
Transformation rules:    phm-transform.json
Cross directory:         /dev/null
Cross projects:          
OpenRefine heap space:   2048M
OpenRefine port:         3333
OpenRefine workspace:    /home/felix/owncloud/Business/projekte/openrefine/openrefine-batch/examples/powerhouse-museum/output
Export to workspace:     true
Export format:           tsv
restart after file:      false
restart after transform: false

=== 1. Launch OpenRefine ===

starting time: Sa 28. Okt 00:42:33 CEST 2017

Starting OpenRefine at 'http://127.0.0.1:3333/'

00:42:33.199 [            refine_server] Starting Server bound to '127.0.0.1:3333' (0ms)
00:42:33.200 [            refine_server] refine.memory size: 2048M JVM Max heap: 2058354688 (1ms)
00:42:33.206 [            refine_server] Initializing context: '/' from '/home/felix/owncloud/Business/projekte/openrefine/openrefine-batch/openrefine/webapp' (6ms)
00:42:33.418 [                   refine] Starting OpenRefine 2017-10-26 [TRUNK]... (212ms)
00:42:33.424 [       FileProjectManager] Failed to load workspace from any attempted alternatives. (6ms)
00:42:35.993 [                   refine] Running in headless mode (2569ms)

=== 2. Import all files ===

starting time: Sa 28. Okt 00:42:36 CEST 2017

import phm-collection.tsv...
00:42:36.393 [                   refine] POST /command/core/create-project-from-upload (400ms)
New project: 1721413008439
00:42:40.731 [                   refine] GET /command/core/get-rows (4338ms)
Number of rows: 75814
 STARTED     ELAPSED %MEM %CPU   RSS
00:42:32       00:07  5.7  220 937692

=== 3. Prepare transform & export ===

starting time: Sa 28. Okt 00:42:40 CEST 2017

get project ids...
00:42:40.866 [                   refine] GET /command/core/get-all-project-metadata (135ms)
 1721413008439: phm-collection.tsv

=== 4. Transform phm-collection.tsv ===

starting time: Sa 28. Okt 00:42:40 CEST 2017

transform phm-transform.json...
00:42:40.963 [                   refine] GET /command/core/get-models (97ms)
00:42:40.967 [                   refine] POST /command/core/apply-operations (4ms)
 STARTED     ELAPSED %MEM %CPU   RSS
00:42:32       00:29  7.1  142 1162720


=== 5. Export phm-collection.tsv ===

starting time: Sa 28. Okt 00:43:02 CEST 2017

export to file phm-collection.tsv...
00:43:02.555 [                   refine] GET /command/core/get-models (21588ms)
00:43:02.557 [                   refine] GET /command/core/get-all-project-metadata (2ms)
00:43:02.561 [                   refine] POST /command/core/export-rows/phm-collection.tsv.tsv (4ms)
 STARTED     ELAPSED %MEM %CPU   RSS
00:42:32       00:53  7.1 81.1 1164684


output (number of lines / size in bytes):
  167017 60619468 /home/felix/owncloud/Business/projekte/openrefine/openrefine-batch/examples/powerhouse-museum/output/phm-collection.tsv

cleanup...
00:43:26.161 [           ProjectManager] Saving all modified projects ... (23600ms)
00:43:29.586 [        project_utilities] Saved project '1721413008439' (3425ms)

=== Statistics ===

starting time and run time of each step:
                      Start process Sa 28. Okt 00:42:33 CEST 2017 (00:00:00)
                  Launch OpenRefine Sa 28. Okt 00:42:33 CEST 2017 (00:00:03)
                   Import all files Sa 28. Okt 00:42:36 CEST 2017 (00:00:04)
         Prepare transform & export Sa 28. Okt 00:42:40 CEST 2017 (00:00:00)
       Transform phm-collection.tsv Sa 28. Okt 00:42:40 CEST 2017 (00:00:22)
          Export phm-collection.tsv Sa 28. Okt 00:43:02 CEST 2017 (00:00:28)
                        End process Sa 28. Okt 00:43:30 CEST 2017 (00:00:00)

total run time: 00:00:57 (hh:mm:ss)
highest memory load: 1137 MB
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
