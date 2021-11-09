## OpenRefine batch processing (openrefine-batch.sh)

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/ad8a97e42e634bbe87203ea48efb436e)](https://www.codacy.com/gh/opencultureconsulting/openrefine-batch/dashboard) [![Binder](https://mybinder.org/badge.svg)](https://mybinder.org/v2/gh/opencultureconsulting/openrefine-batch/master?urlpath=lab/tree/demo.ipynb)

Shell script to run OpenRefine in batch mode (import, transform, export). This bash script automatically...

1. imports all data from a given directory into OpenRefine
2. transforms the data by applying OpenRefine transformation rules from all json files in another given directory and
3. finally exports the data in csv, tsv, html, xlsx or ods.

It orchestrates [OpenRefine](https://github.com/OpenRefine/OpenRefine) (server) and a [python client](https://github.com/felixlohmeier/openrefine-client) that communicates with the OpenRefine API. By restarting the server after each process it reduces memory requirements to a minimum.

If you prefer a containerized approach, see a [variation of this script for Docker](#docker) below.

### Typical Workflow

- **Step 1**: Do some experiments with your data (or parts of it) in the graphical user interface of OpenRefine. If you are fine with all transformation rules, [extract the json code](http://kb.refinepro.com/2012/06/google-refine-json-and-my-notepad-or.html) and save it as file (e.g. transform.json).
- **Step 2**: Put your data and the json file(s) in two different directories and execute the script. The script will automatically import all data files in OpenRefine projects, apply the transformation rules in the json files to each project and export all projects to files in the format specified (default: TSV - tab-separated values).

### Demo via binder

[![Binder](https://mybinder.org/badge.svg)](https://mybinder.org/v2/gh/opencultureconsulting/openrefine-batch/master?urlpath=lab/tree/demo.ipynb)

- free to use on-demand server with Jupyterlab and Bash Kernel
- no registration needed, will start within a few minutes
- [restricted](https://mybinder.readthedocs.io/en/latest/about/about.html#how-much-memory-am-i-given-when-using-binder) to 2 GB RAM and server will be deleted after 10 minutes of inactivity

### Install

Download the script and grant file permissions to execute:
```
wget https://github.com/felixlohmeier/openrefine-batch/raw/master/openrefine-batch.sh
chmod +x openrefine-batch.sh
```

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
[felix@tux openrefine-batch]$ ./openrefine-batch.sh
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
    -t TEMPLATING    several options for templating export, see below...
    -E               do NOT export files
    -R               do NOT restart OpenRefine after each transformation (e.g. config file)
    -X               do NOT restart OpenRefine after each project (e.g. input file)
    -h               displays this help screen

== inputoptions (mandatory for xml, json, fixed-width, xslx, ods) ==
    -i recordPath=RECORDPATH (xml, json): please provide path in multiple arguments without slashes, e.g. /collection/record/ should be entered like this: -i recordPath=collection -i recordPath=record, default xml: record, default json: _ _
    -i columnWidths=COLUMNWIDTHS (fixed-width): please provide widths separated by comma (e.g. 7,5)
    -i sheets=SHEETS (xls, xlsx, ods): please provide sheets separated by comma (e.g. 0,1), default: 0 (first sheet)

== more inputoptions (optional, only together with inputformat) ==
    -i projectName=PROJECTNAME (all formats), default: filename
    -i limit=LIMIT (all formats), default: -1
    -i includeFileSources=true/false (all formats), default: false
    -i trimStrings=true/false (xml, json), default: false
    -i storeEmptyStrings=true/false (xml, json), default: true
    -i guessCellValueTypes=true/false (xml, csv, tsv, fixed-width, json), default: false
    -i encoding=ENCODING (csv, tsv, line-based, fixed-width), please provide short encoding name (e.g. UTF-8)
    -i ignoreLines=IGNORELINES (csv, tsv, line-based, fixed-width, xls, xlsx, ods), default: -1
    -i headerLines=HEADERLINES (csv, tsv, fixed-width, xls, xlsx, ods), default: 1, default fixed-width: 0
    -i skipDataLines=true/false (csv, tsv, line-based, fixed-width, xls, xlsx, ods), default: 0, default line-based: -1
    -i storeBlankRows=true/false (csv, tsv, line-based, fixed-width, xls, xlsx, ods), default: true
    -i processQuotes=true/false (csv, tsv), default: true
    -i storeBlankCellsAsNulls=true/false (csv, tsv, line-based, fixed-width, xls, xlsx, ods), default: true
    -i linesPerRow=LINESPERROW (line-based), default: 1

== templating options (alternative exportformat) ==
    -t template=TEMPLATE (mandatory; (big) text string that you enter in the *row template* textfield in the export/templating menu in the browser app)
    -t mode=row-based/record-based (engine mode, default: row-based)
    -t prefix=PREFIX (text string that you enter in the *prefix* textfield in the browser app)
    -t rowSeparator=ROWSEPARATOR (text string that you enter in the *row separator* textfield in the browser app)
    -t suffix=SUFFIX (text string that you enter in the *suffix* textfield in the browser app)
    -t filterQuery=REGEX (Simple RegEx text filter on filterColumn, e.g. ^12015$)
    -t filterColumn=COLUMNNAME (column name for filterQuery, default: name of first column)
    -t facets=FACETS (facets config in json format, may be extracted with browser dev tools in browser app)
    -t splitToFiles=true/false (will split each row/record into a single file; it specifies a presumably unique character series for splitting; prefix and suffix will be applied to all files
    -t suffixById=true/false (enhancement option for splitToFiles; will generate filename-suffix from values in key column)

== examples ==

download example data

wget https://github.com/opencultureconsulting/openrefine-batch/archive/master.zip
unzip master.zip openrefine-batch-master/examples/*
mv openrefine-batch-master/examples .
rm -f master.zip

example 1 (input, transform, export to tsv)

./openrefine-batch.sh -a examples/powerhouse-museum/input/ -b examples/powerhouse-museum/config/ -c examples/powerhouse-museum/output/ -f tsv -i processQuotes=false -i guessCellValueTypes=true -RX

example 2 (input, transform, templating export)

./openrefine-batch.sh -a examples/powerhouse-museum/input/ -b examples/powerhouse-museum/config/ -c examples/powerhouse-museum/output/ -f tsv -i processQuotes=false -i guessCellValueTypes=true -RX -t template='{ "Record ID" : {{jsonize(cells["Record ID"].value)}}, "Object Title" : {{jsonize(cells["Object Title"].value)}}, "Registration Number" : {{jsonize(cells["Registration Number"].value)}}, "Description." : {{jsonize(cells["Description."].value)}}, "Marks" : {{jsonize(cells["Marks"].value)}}, "Production Date" : {{jsonize(cells["Production Date"].value)}}, "Provenance (Production)" : {{jsonize(cells["Provenance (Production)"].value)}}, "Provenance (History)" : {{jsonize(cells["Provenance (History)"].value)}}, "Categories" : {{jsonize(cells["Categories"].value)}}, "Persistent Link" : {{jsonize(cells["Persistent Link"].value)}}, "Height" : {{jsonize(cells["Height"].value)}}, "Width" : {{jsonize(cells["Width"].value)}}, "Depth" : {{jsonize(cells["Depth"].value)}}, "Diameter" : {{jsonize(cells["Diameter"].value)}}, "Weight" : {{jsonize(cells["Weight"].value)}}, "License info" : {{jsonize(cells["License info"].value)}} }' -t rowSeparator=',' -t prefix='{ "rows" : [ ' -t suffix='] }' -t splitToFiles=true
```

### Logging

The script prints log messages from OpenRefine server and makes use of `ps` to show statistics for each step. Here is a sample:

```
[felix@tux openrefine-batch]$ ./openrefine-batch.sh -a examples/powerhouse-museum/input/ -b examples/powerhouse-museum/config/ -c examples/powerhouse-museum/output/ -f tsv -i processQuotes=false -i guessCellValueTypes=true -RX
Download OpenRefine...
openrefine-linux-3.5.0.tar.gz                               100%[=========================================================================================================================================>] 125,73M  9,50MB/s    in 13s     
Install OpenRefine in subdirectory openrefine...
Total bytes read: 154163200 (148MiB, 87MiB/s)

Download OpenRefine client...
openrefine-client_0-3-10_linux                              100%[=========================================================================================================================================>]   4,25M  9,17MB/s    in 0,5s    

Input directory:         /home/felix/git/openrefine-batch/examples/powerhouse-museum/input
Input files:             phm-collection.tsv
Input format:            --format=tsv
Input options:           --processQuotes=false --guessCellValueTypes=true
Config directory:        /home/felix/git/openrefine-batch/examples/powerhouse-museum/config
Transformation rules:    phm-transform.json
Cross directory:         /dev/null
Cross projects:          
OpenRefine heap space:   2048M
OpenRefine port:         3333
OpenRefine workspace:    /home/felix/git/openrefine-batch/examples/powerhouse-museum/output
Export to workspace:     true
Export format:           tsv
Templating options:      
restart after file:      false
restart after transform: false

=== 1. Launch OpenRefine ===

starting time: Di 9. Nov 22:37:25 CET 2021

Using refine.ini for configuration
You have 15913M of free memory.
Your current configuration is set to use 2048M of memory.
OpenRefine can run better when given more memory. Read our FAQ on how to allocate more memory here:
https://github.com/OpenRefine/OpenRefine/wiki/FAQ-Allocate-More-Memory
/usr/bin/java -cp server/classes:server/target/lib/* -Drefine.headless=true -Xms2048M -Xmx2048M -Drefine.memory=2048M -Drefine.max_form_content_size=1048576 -Drefine.verbosity=info -Dpython.path=main/webapp/WEB-INF/lib/jython -Dpython.cachedir=/home/felix/.local/share/google/refine/cachedir -Drefine.data_dir=/home/felix/git/openrefine-batch/examples/powerhouse-museum/output -Drefine.webapp=main/webapp -Drefine.port=3333 -Drefine.interface=127.0.0.1 -Drefine.host=127.0.0.1 -Drefine.autosave=1440 com.google.refine.Refine
Starting OpenRefine at 'http://127.0.0.1:3333/'

log4j:WARN No appenders could be found for logger (org.eclipse.jetty.util.log).
log4j:WARN Please initialize the log4j system properly.
log4j:WARN See http://logging.apache.org/log4j/1.2/faq.html#noconfig for more info.
SLF4J: Class path contains multiple SLF4J bindings.
SLF4J: Found binding in [jar:file:/home/felix/git/openrefine-batch/openrefine/webapp/WEB-INF/lib/slf4j-log4j12-1.7.30.jar!/org/slf4j/impl/StaticLoggerBinder.class]
SLF4J: Found binding in [jar:file:/home/felix/git/openrefine-batch/openrefine/server/target/lib/slf4j-log4j12-1.7.30.jar!/org/slf4j/impl/StaticLoggerBinder.class]
SLF4J: See http://www.slf4j.org/codes.html#multiple_bindings for an explanation.
SLF4J: Actual binding is of type [org.slf4j.impl.Log4jLoggerFactory]
22:37:28.211 [                   refine] Starting OpenRefine 3.5.0 [d4209a2]... (0ms)
22:37:28.213 [                   refine] initializing FileProjectManager with dir (2ms)
22:37:28.213 [                   refine] /home/felix/git/openrefine-batch/examples/powerhouse-museum/output (0ms)
22:37:28.223 [       FileProjectManager] Failed to load workspace from any attempted alternatives. (10ms)

=== 2. Import all files ===

starting time: Di 9. Nov 22:37:33 CET 2021

import phm-collection.tsv...
22:37:33.804 [                   refine] GET /command/core/get-csrf-token (5581ms)
22:37:33.872 [                   refine] POST /command/core/create-project-from-upload (68ms)
22:37:44.653 [                   refine] GET /command/core/get-models (10781ms)
22:37:44.790 [                   refine] POST /command/core/get-rows (137ms)
id: 2252508879578
rows: 75814
 STARTED     ELAPSED %MEM %CPU   RSS
22:37:25       00:19 10.2  202 1670620

=== 3. Prepare transform & export ===

starting time: Di 9. Nov 22:37:44 CET 2021

get project ids...
22:37:45.112 [                   refine] GET /command/core/get-csrf-token (322ms)
22:37:45.115 [                   refine] GET /command/core/get-all-project-metadata (3ms)
 2252508879578: phm-collection

=== 4. Transform phm-collection ===

starting time: Di 9. Nov 22:37:45 CET 2021

transform phm-transform.json...
22:37:45.303 [                   refine] GET /command/core/get-csrf-token (188ms)
22:37:45.308 [                   refine] GET /command/core/get-models (5ms)
22:37:45.324 [                   refine] POST /command/core/apply-operations (16ms)
File /home/felix/git/openrefine-batch/examples/powerhouse-museum/config/phm-transform.json has been successfully applied to project 2252508879578
 STARTED     ELAPSED %MEM %CPU   RSS
22:37:25       00:34 11.9  175 1940600


=== 5. Export phm-collection ===

starting time: Di 9. Nov 22:37:59 CET 2021

export to file phm-collection.tsv...
22:37:59.944 [                   refine] GET /command/core/get-csrf-token (14620ms)
22:37:59.947 [                   refine] GET /command/core/get-models (3ms)
22:37:59.951 [                   refine] GET /command/core/get-all-project-metadata (4ms)
22:37:59.954 [                   refine] POST /command/core/export-rows/phm-collection.tsv (3ms)
Export to file /home/felix/git/openrefine-batch/examples/powerhouse-museum/output/phm-collection.tsv complete
 STARTED     ELAPSED %MEM %CPU   RSS
22:37:25       00:38 12.4  181 2021388


output (number of lines / size in bytes):
   75728 59431272 /home/felix/git/openrefine-batch/examples/powerhouse-museum/output/phm-collection.tsv

cleanup...
22:38:06.850 [           ProjectManager] Saving all modified projects ... (6896ms)
22:38:10.014 [        project_utilities] Saved project '2252508879578' (3164ms)

=== Statistics ===

starting time and run time of each step:
                      Start process Di 9. Nov 22:37:25 CET 2021 (00:00:00)
                  Launch OpenRefine Di 9. Nov 22:37:25 CET 2021 (00:00:08)
                   Import all files Di 9. Nov 22:37:33 CET 2021 (00:00:11)
         Prepare transform & export Di 9. Nov 22:37:44 CET 2021 (00:00:01)
           Transform phm-collection Di 9. Nov 22:37:45 CET 2021 (00:00:14)
              Export phm-collection Di 9. Nov 22:37:59 CET 2021 (00:00:11)
                        End process Di 9. Nov 22:38:10 CET 2021 (00:00:00)

total run time: 00:00:45 (hh:mm:ss)
highest memory load: 1974 MB
```

### Docker

A variation of the shell script orchestrates a [docker container for OpenRefine](https://hub.docker.com/r/felixlohmeier/openrefine/) (server) and a [docker container for the python client](https://hub.docker.com/r/felixlohmeier/openrefine-client/) instead of native applications.

**Install**

1. Install [Docker](https://docs.docker.com/engine/installation/#on-linux)
  * **a)** [configure Docker to start on boot](https://docs.docker.com/engine/installation/linux/linux-postinstall/#configure-docker-to-start-on-boot)
  * or **b)** start Docker on demand each time you use the script: `sudo systemctl start docker`
2. Download the script and grant file permissions to execute:
```
wget https://github.com/felixlohmeier/openrefine-batch/raw/master/openrefine-batch-docker.sh
chmod +x openrefine-batch-docker.sh
```

**Usage**

```
mkdir input
cp INPUTFILES input/
mkdir config
cp CONFIGFILES config/
./openrefine-batch-docker.sh -a input/ -b config/ -c OUTPUT/
```

The script may ask you for sudo privileges. Why `sudo`? Non-root users can only access the Unix socket of the Docker daemon by using `sudo`. If you created a Docker group in [Post-installation steps for Linux](https://docs.docker.com/engine/installation/linux/linux-postinstall/) then you may call the script without `sudo`.

**Example**

[Example Powerhouse Museum](examples/powerhouse-museum)

download example data

```
wget https://github.com/opencultureconsulting/openrefine-batch/archive/master.zip
unzip master.zip openrefine-batch-master/examples/*
mv openrefine-batch-master/examples .
rm -f master.zip
```

execute openrefine-batch-docker.sh

```
./openrefine-batch-docker.sh \
-a examples/powerhouse-museum/input/ \
-b examples/powerhouse-museum/config/ \
-c examples/powerhouse-museum/output/ \
-f tsv \
-i processQuotes=false \
-i guessCellValueTypes=true \
-RX
```

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
