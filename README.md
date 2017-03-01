## OpenRefine batch processing (openrefine-batch.sh)

Shell script to run OpenRefine in batch mode (import, transform, export). This bash script automatically...

1. imports all data from a given directory into OpenRefine
2. transforms the data by applying OpenRefine transformation rules from all json files in another given directory and
3. finally exports the data in TSV (tab-separated values) format.

It orchestrates a [docker container for OpenRefine](https://hub.docker.com/r/felixlohmeier/openrefine/) (server) and a [docker container for a python client](https://hub.docker.com/r/felixlohmeier/openrefine-client/) that communicates with the OpenRefine API. By restarting the server after each process it reduces memory requirements to a minimum.

### Typical Workflow

- **Step 1**: Do some experiments with your data (or parts of it) in the graphical user interface of OpenRefine. If you are fine with all transformation rules, [extract the json code](http://kb.refinepro.com/2012/06/google-refine-json-and-my-notepad-or.html) and save it as file (e.g. transform.json).
- **Step 2**: Put your data and the json file(s) in two different directories and execute the script. The script will automatically import all data files in OpenRefine projects, apply the transformation rules in the json files to each project and export all projects in TSV-files.

### Install

1. Install [Docker](https://docs.docker.com/engine/installation/#on-linux) and **a)** [configure Docker to start on boot](https://docs.docker.com/engine/installation/linux/linux-postinstall/#configure-docker-to-start-on-boot) or **b)** start Docker on demand each time you use the script: `sudo systemctl start docker`
2. Download the script and grant file permissions to execute: `wget https://github.com/felixlohmeier/openrefine-batch/raw/master/openrefine-batch.sh && chmod +x openrefine-batch.sh`

### Usage

```
mkdir -p input && cp INPUTFILES input/
mkdir -p config && cp CONFIGFILES config/
sudo ./openrefine-batch.sh input/ config/ OUTPUT/
```

Why `sudo`? Non-root users can only access the Unix socket of the Docker daemon by using `sudo`. If you created a Docker group in [Post-installation steps for Linux](https://docs.docker.com/engine/installation/linux/linux-postinstall/) then you may call the script without `sudo`.

**INPUTFILES**
* any data that [OpenRefine supports](https://github.com/OpenRefine/OpenRefine/wiki/Importers). CSV, TSV and line-based files should work out of the box. XML, JSON, fixed-width, XSLX and ODS need one additional input parameter (see chapter [Options](https://github.com/felixlohmeier/openrefine-batch#options) below)
* multiple slices of data may be transformed into a into a single file [by providing a zip or tar.gz archive])
* you may use hard symlinks instead of cp: `ln INPUTFILE input/`

**CONFIGFILES**
* JSON files with [OpenRefine transformation rules)](http://kb.refinepro.com/2012/06/google-refine-json-and-my-notepad-or.html)

**OUTPUT/**
* path to directory where results and temporary data should be stored
* Transformed data will be stored in this directory in TSV (tab-separated values) format. Show results: `ls OUTPUT/*.tsv`
* OpenRefine stores data in directories like "1234567890123.project". You may have a look at the results by starting OpenRefine with this workspace. Delete the directories if you do not need them: `rm -r -f OUTPUT/*.project`

#### Example

clone or [download GitHub repository](https://github.com/felixlohmeier/openrefine-batch/archive/master.zip) to get example data

```
sudo ./openrefine-batch.sh \
examples/powerhouse-museum/input/ \
examples/powerhouse-museum/config/ \
examples/powerhouse-museum/output/ \
examples/powerhouse-museum/cross/ \
2G 2.7rc1 restartfile-false restarttransform-false export-true \
tsv --processQuotes=false --guessCellValueTypes=true
```

#### Options

```
sudo ./openrefine-batch.sh $inputdir $configdir $outputdir $crossdir $ram $version $restartfile $restarttransform $export $inputformat $inputoptions
```

1. inputdir: path to directory with source files (multiple files may be imported into a single project [by providing a zip or tar.gz archive](https://github.com/OpenRefine/OpenRefine/wiki/Importers))
2. configdir: path to directory with [OpenRefine transformation rules (json files)](http://kb.refinepro.com/2012/06/google-refine-json-and-my-notepad-or.html)
3. outputdir: path to directory for exported files (and OpenRefine workspace)
4. crossdir: path to directory with additional OpenRefine projects (will be copied to workspace before transformation step to support the [cross function](https://github.com/OpenRefine/OpenRefine/wiki/GREL-Other-Functions#crosscell-c-string-projectname-string-columnname))
5. ram: maximum RAM for OpenRefine java heap space (default: 4G)
6. version: OpenRefine version (2.7rc1, 2.6rc2, 2.6rc1, dev; default: 2.7rc1)
7. restartfile: restart docker after each project (e.g. input file) to clear memory (restartfile-true/restartfile-false; default: restartfile-true)
8. restarttransform: restart docker container after each transformation (e.g. config file) to clear memory (restarttransform-true/restarttransform-false; default: restarttransform-false)
9. export: toggle on/off (export-true/export-false; default: export-true)
8. inputformat: (csv, tsv, xml, json, line-based, fixed-width, xlsx, ods)
9. inputoptions: several options provided by [openrefine-client](https://hub.docker.com/r/felixlohmeier/openrefine-client/)

inputoptions (mandatory for xml, json, fixed-width, xslx, ods):
* `--recordPath=RECORDPATH` (xml, json): please provide path in multiple arguments without slashes, e.g. /collection/record/ should be entered like this: `--recordPath=collection --recordPath=record`
* `--columnWidths=COLUMNWIDTHS` (fixed-width): please provide widths separated by comma (e.g. 7,5)
* `--sheets=SHEETS` (xlsx, ods): please provide sheets separated by comma (e.g. 0,1), default: 0 (first sheet)

more inputoptions (optional, only together with inputformat):
* `--projectName=PROJECTNAME` (all formats)
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
[17:54 felix ~/openrefine-batch]$ sudo ./openrefine-batch.sh \
> examples/powerhouse-museum/input/ \
> examples/powerhouse-museum/config/ \
> examples/powerhouse-museum/output/ \
> examples/powerhouse-museum/cross/ \
> 2G 2.7rc1 restartfile-false restarttransform-false export-true \
> tsv --processQuotes=false --guessCellValueTypes=true
Input directory:         /home/felix/occcloud/Openness/Kunden+Projekte/OpenRefine/openrefine-batch/examples/powerhouse-museum/input
Input files:             phm-collection.tsv
Input format:            --format=tsv
Input options:           --processQuotes=false --guessCellValueTypes=true
Config directory:        /home/felix/occcloud/Openness/Kunden+Projekte/OpenRefine/openrefine-batch/examples/powerhouse-museum/config
Transformation rules:    phm-transform.json
Cross directory:         /home/felix/occcloud/Openness/Kunden+Projekte/OpenRefine/openrefine-batch/examples/powerhouse-museum/cross
Cross projects:          
OpenRefine heap space:   2G
OpenRefine version:      2.7rc1
OpenRefine workspace:    /home/felix/occcloud/Openness/Kunden+Projekte/OpenRefine/openrefine-batch/examples/powerhouse-museum/output
Export TSV to workspace: export-true
Docker container name:   6b622f38-bbdd-4a28-b590-0c7fdf9d577b
restart after file:      restartfile-false
restart after transform: restarttransform-false

begin: Mi 1. Mär 17:54:45 CET 2017

start OpenRefine server...
2d836891cbc79f730f18262c9f98b6406b5323ca9fd84636afb194a664abf66e

=== IMPORT ===

import phm-collection.tsv...
16:54:59.290 [                   refine] POST /command/core/create-project-from-upload (4748ms)
New project: 1831307645035
16:55:15.514 [                   refine] GET /command/core/get-rows (16224ms)
Number of rows: 75814
 STARTED     ELAPSED %MEM %CPU   RSS
17:54:46       00:31  9.7  109 788156

=== TRANSFORM / EXPORT ===

get project ids...
16:55:21.258 [                   refine] GET /command/core/get-all-project-metadata (5744ms)
 1831307645035: phm-collection.tsv

--- begin project 1831307645035 @ Mi 1. Mär 17:55:22 CET 2017 ---

transform phm-transform.json...
16:55:23.983 [                   refine] GET /command/core/get-models (2725ms)
16:55:24.002 [                   refine] POST /command/core/apply-operations (19ms)
 STARTED     ELAPSED %MEM %CPU   RSS
17:54:46       01:26 13.3  118 1076800

export to file 1831307645035.tsv...
16:56:14.909 [                   refine] GET /command/core/get-models (50907ms)
16:56:14.933 [                   refine] GET /command/core/get-all-project-metadata (24ms)
16:56:14.949 [                   refine] POST /command/core/export-rows/phm-collection.tsv.tsv (16ms)
 STARTED     ELAPSED %MEM %CPU   RSS
17:54:46       03:10 13.9 59.2 1130304

--- finished project 1831307645035 @ Mi 1. Mär 17:57:57 CET 2017 ---

output (number of lines / size in bytes):
  167017 60527726 /home/felix/occcloud/Openness/Kunden+Projekte/OpenRefine/openrefine-batch/examples/powerhouse-museum/output/1831307645035.tsv

cleanup...
16:58:00.158 [           ProjectManager] Saving all modified projects ... (105209ms)
16:58:07.242 [        project_utilities] Saved project '1831307645035' (7084ms)
6b622f38-bbdd-4a28-b590-0c7fdf9d577b
6b622f38-bbdd-4a28-b590-0c7fdf9d577b

finish: Mi 1. Mär 17:58:09 CET 2017
```

### Todo

- [ ] use getopts for parsing of arguments
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
