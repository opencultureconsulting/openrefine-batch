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
* JSON files with [OpenRefine transformation rules](http://kb.refinepro.com/2012/06/google-refine-json-and-my-notepad-or.html)

**OUTPUT/**
* path to directory where results and temporary data should be stored
* Transformed data will be stored in this directory in the format specified (default: TSV). Show results: `ls OUTPUT/*.tsv`
* OpenRefine stores data in directories like "1234567890123.project". You may have a look at the results by starting OpenRefine with this workspace. Delete the directories if you do not need them: `rm -r -f OUTPUT/*.project`

### Example

[Example Powerhouse Museum](examples/powerhouse-museum)

download example data

```
wget https://github.com/opencultureconsulting/openrefine-batch/archive/master.zip
unzip master.zip openrefine-batch-master/examples/*
mv openrefine-batch-master/examples .
rm -f master.zip
```

execute openrefine-batch.sh

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

### Help Screen

```
[23:10 felix ~/openrefine-batch]$ ./openrefine-batch.sh
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

download example data

wget https://github.com/opencultureconsulting/openrefine-batch/archive/master.zip
unzip master.zip openrefine-batch-master/examples/*
mv openrefine-batch-master/examples .
rm -f master.zip

execute openrefine-batch.sh

./openrefine-batch.sh -a examples/powerhouse-museum/input/ -b examples/powerhouse-museum/config/ -c examples/powerhouse-museum/output/ -f tsv -i processQuotes=false -i guessCellValueTypes=true -RX

```

### Logging

The script prints log messages from OpenRefine server and makes use of `ps` to show statistics for each step. Here is a sample:

```
[23:10 felix ~/openrefine-batch]$ ./openrefine-batch.sh -a examples/powerhouse-museum/input/ -b examples/powerhouse-museum/config/ -c examples/powerhouse-museum/output/ -f tsv -i processQuotes=false -i guessCellValueTypes=true -RX
Download OpenRefine...
openrefine-linux-2017-10-2 100%[=====================================>]  66,34M  5,62MB/s    in 12s     
Install OpenRefine in subdirectory openrefine...
Total bytes read: 79861760 (77MiB, 129MiB/s)

Download OpenRefine client...
openrefine-client_0-3-1_li 100%[=====================================>]   5,39M  5,17MB/s    in 1,0s    

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
Export to workspace:     true
Export format:           tsv
restart after file:      false
restart after transform: false

=== 1. Launch OpenRefine ===

starting time: Do 2. Nov 23:10:38 CET 2017

Starting OpenRefine at 'http://127.0.0.1:3333/'

23:10:38.887 [            refine_server] Starting Server bound to '127.0.0.1:3333' (0ms)
23:10:38.887 [            refine_server] refine.memory size: 2048M JVM Max heap: 2058354688 (0ms)
23:10:38.893 [            refine_server] Initializing context: '/' from '/home/felix/openrefine-batch/openrefine/webapp' (6ms)
23:10:39.100 [                   refine] Starting OpenRefine 2017-10-28 [TRUNK]... (207ms)
23:10:39.105 [       FileProjectManager] Failed to load workspace from any attempted alternatives. (5ms)
23:10:41.616 [                   refine] Running in headless mode (2511ms)

=== 2. Import all files ===

starting time: Do 2. Nov 23:10:41 CET 2017

import phm-collection.tsv...
23:10:42.057 [                   refine] POST /command/core/create-project-from-upload (441ms)
New project: 1820134322107
23:10:46.020 [                   refine] GET /command/core/get-rows (3963ms)
Number of rows: 75814
 STARTED     ELAPSED %MEM %CPU   RSS
23:10:37       00:08  5.8  186 951316

=== 3. Prepare transform & export ===

starting time: Do 2. Nov 23:10:46 CET 2017

get project ids...
23:10:46.146 [                   refine] GET /command/core/get-all-project-metadata (126ms)
 1820134322107: phm-collection.tsv

=== 4. Transform phm-collection.tsv ===

starting time: Do 2. Nov 23:10:46 CET 2017

transform phm-transform.json...
23:10:46.243 [                   refine] GET /command/core/get-models (97ms)
23:10:46.248 [                   refine] POST /command/core/apply-operations (5ms)
 STARTED     ELAPSED %MEM %CPU   RSS
23:10:37       00:22  7.1  143 1152200


=== 5. Export phm-collection.tsv ===

starting time: Do 2. Nov 23:11:00 CET 2017

export to file phm-collection.tsv...
23:11:00.168 [                   refine] GET /command/core/get-models (13920ms)
23:11:00.171 [                   refine] GET /command/core/get-all-project-metadata (3ms)
23:11:00.174 [                   refine] POST /command/core/export-rows/phm-collection.tsv.tsv (3ms)
 STARTED     ELAPSED %MEM %CPU   RSS
23:10:37       00:43  7.1 76.5 1152604


output (number of lines / size in bytes):
   75728 59431272 /home/felix/openrefine-batch/examples/powerhouse-museum/output/phm-collection.tsv

cleanup...
23:11:24.461 [           ProjectManager] Saving all modified projects ... (24287ms)
23:11:27.520 [        project_utilities] Saved project '1820134322107' (3059ms)

=== Statistics ===

starting time and run time of each step:
                      Start process Do 2. Nov 23:10:38 CET 2017 (00:00:00)
                  Launch OpenRefine Do 2. Nov 23:10:38 CET 2017 (00:00:03)
                   Import all files Do 2. Nov 23:10:41 CET 2017 (00:00:05)
         Prepare transform & export Do 2. Nov 23:10:46 CET 2017 (00:00:00)
       Transform phm-collection.tsv Do 2. Nov 23:10:46 CET 2017 (00:00:14)
          Export phm-collection.tsv Do 2. Nov 23:11:00 CET 2017 (00:00:28)
                        End process Do 2. Nov 23:11:28 CET 2017 (00:00:00)

total run time: 00:00:50 (hh:mm:ss)
highest memory load: 1125 MB
```

### Performance gain with extended cross function

The original cross function expects normalized data (one foreign key per cell in base column). If you have multiple key values in one cell you need to split them first in multiple rows before you apply cross (and join results afterwards). This can be quite "expensive" if you work with bigger datasets.

There is a [fork available that extend the cross function](https://github.com/felixlohmeier/OpenRefine/wiki>) to support an integrated split and may provide a massive performance gain for this special use case.

Here is a code snippet to install this fork together with openrefine-batch.sh in a blank directory:
```
wget https://github.com/felixlohmeier/openrefine-batch/raw/master/openrefine-batch.sh && chmod +x openrefine-batch.sh
sed -i 's/.tar.gz/-with-pr1294.tar.gz/' openrefine-batch.sh
./openrefine-batch.sh
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
