#!/bin/bash
# openrefine-batch.sh, Felix Lohmeier, v1.13, 2019-08-06
# https://github.com/felixlohmeier/openrefine-batch

# declare download URLs for OpenRefine and OpenRefine client
openrefine_URL="https://github.com/OpenRefine/OpenRefine/releases/download/3.2/openrefine-linux-3.2.tar.gz"
client_URL="https://github.com/opencultureconsulting/openrefine-client/releases/download/v0.3.4/openrefine-client_0-3-4_linux-64bit"

# check system requirements
JAVA="$(which java 2> /dev/null)"
if [ -z "$JAVA" ] ; then
    echo 1>&2 "This action requires you to have 'Java JRE' installed. You can download it for free at https://java.com"
    exit 1
fi
# check if wget supports option --show-progress (since wget 1.16)
wget --help | grep -q '\--show-progress' && wget_opt="--show-progress" || wget_opt=""

# autoinstall OpenRefine
if [ ! -d "openrefine" ]; then
    echo "Download OpenRefine..."
    mkdir -p openrefine
    wget -q $wget_opt $openrefine_URL
    echo "Install OpenRefine in subdirectory openrefine..."
    tar -xzf "$(basename $openrefine_URL)" -C openrefine --strip 1 --totals
    rm -f "$(basename $openrefine_URL)"
    sed -i '$ a JAVA_OPTIONS=-Drefine.headless=true' openrefine/refine.ini
    sed -i 's/#REFINE_AUTOSAVE_PERIOD=60/REFINE_AUTOSAVE_PERIOD=1440/' openrefine/refine.ini
    sed -i 's/-Xms$REFINE_MIN_MEMORY/-Xms$REFINE_MEMORY/' openrefine/refine
    echo ""
fi

# autoinstall OpenRefine client
if [ ! -d "openrefine-client" ]; then
    echo "Download OpenRefine client..."
    mkdir -p openrefine-client
    wget -q -P openrefine-client $wget_opt $client_URL
    chmod +x openrefine-client/openrefine-client_0-3-4_linux-64bit
    echo ""
fi

# help screen
function usage () {
    cat <<EOF
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

./openrefine-batch.sh \
-a examples/powerhouse-museum/input/ \
-b examples/powerhouse-museum/config/ \
-c examples/powerhouse-museum/output/ \
-f tsv \
-i processQuotes=false \
-i guessCellValueTypes=true \
-RX

example 2 (input, transform, templating export)

./openrefine-batch.sh -a examples/powerhouse-museum/input/ -b examples/powerhouse-museum/config/ -c examples/powerhouse-museum/output/ -f tsv -i processQuotes=false -i guessCellValueTypes=true -RX -t template='{ "Record ID" : {{jsonize(cells["Record ID"].value)}}, "Object Title" : {{jsonize(cells["Object Title"].value)}}, "Registration Number" : {{jsonize(cells["Registration Number"].value)}}, "Description." : {{jsonize(cells["Description."].value)}}, "Marks" : {{jsonize(cells["Marks"].value)}}, "Production Date" : {{jsonize(cells["Production Date"].value)}}, "Provenance (Production)" : {{jsonize(cells["Provenance (Production)"].value)}}, "Provenance (History)" : {{jsonize(cells["Provenance (History)"].value)}}, "Categories" : {{jsonize(cells["Categories"].value)}}, "Persistent Link" : {{jsonize(cells["Persistent Link"].value)}}, "Height" : {{jsonize(cells["Height"].value)}}, "Width" : {{jsonize(cells["Width"].value)}}, "Depth" : {{jsonize(cells["Depth"].value)}}, "Diameter" : {{jsonize(cells["Diameter"].value)}}, "Weight" : {{jsonize(cells["Weight"].value)}}, "License info" : {{jsonize(cells["License info"].value)}} }' -t rowSeparator=',' -t prefix='{ "rows" : [ ' -t suffix='] }' -t splitToFiles=true
EOF
   exit 1
}

# defaults
ram="2048M"
port="3333"
restartfile="true"
restarttransform="true"
export="true"
exportformat="tsv"
inputdir=/dev/null
configdir=/dev/null
crossdir=/dev/null


# check input
NUMARGS=$#
if [ "$NUMARGS" -eq 0 ]; then
  usage
fi

# get user input
options="a:b:c:d:e:f:i:m:p:t:ERXh"
while getopts $options opt; do
   case $opt in
   a )  inputdir=$(readlink -f ${OPTARG}); if [ -n "${inputdir// }" ] ; then inputfiles=($(find -L "${inputdir}"/* -type f -printf "%f\n" 2>/dev/null)); fi ;;
   b )  configdir=$(readlink -f ${OPTARG}); if [ -n "${configdir// }" ] ; then jsonfiles=($(find -L "${configdir}"/* -type f -printf "%f\n" 2>/dev/null)); fi ;;
   c )  outputdir=$(readlink -m ${OPTARG}); mkdir -p "${outputdir}" ;;
   d )  crossdir=$(readlink -f ${OPTARG}); if [ -n "${crossdir// }" ] ; then crossprojects=($(find -L "${crossdir}"/* -maxdepth 0 -type d -printf "%f\n" 2>/dev/null)); fi ;;
   e )  format="${OPTARG}" ; exportformat="${OPTARG}" ;;
   f )  format="${OPTARG}" ; inputformat="--format=${OPTARG}" ;;
   i )  inputoptions+=("--${OPTARG}") ;;
   m )  ram=${OPTARG} ;;
   p )  port=${OPTARG} ;;
   t )  templating+=("--${OPTARG}") ; exportformat="txt" ;;
   E )  export="false" ;;
   R )  restarttransform="false" ;;
   X )  restartfile="false" ;;
   h )  usage ;;
   \? ) echo 1>&2 "Unknown option: -$OPTARG"; usage; exit 1;;
   :  ) echo 1>&2 "Missing option argument for -$OPTARG"; usage; exit 1;;
   *  ) echo 1>&2 "Unimplemented option: -$OPTARG"; usage; exit 1;;
   esac
done
shift $((OPTIND - 1))

# check for mandatory options
if [ -z "$outputdir" ]; then
    echo 1>&2 "please provide path to directory for exported files (and OpenRefine workspace)"
    echo 1>&2 "example: ./openrefine-batch.sh -c output/"
    exit 1
fi
if [ "$(ls -A "$outputdir" 2>/dev/null)" ];then
    echo 1>&2 "path to directory for exported files (and OpenRefine workspace) is not empty"
    echo 1>&2 "$outputdir"
    exit 1
fi
if [ "$format" = "xml" ] || [ "$format" = "json" ] && [ -z "$inputoptions" ]; then
    echo 1>&2 "error: you specified the inputformat $format but did not provide mandatory input options"
    echo 1>&2 "please provide recordpath in multiple arguments without slashes"
    echo 1>&2 "example: ./openrefine-batch.sh ... -f $format -i recordPath=collection -i recordPath=record"
    exit 1
fi
if [ "$format" = "fixed-width" ] && [ -z "$inputoptions" ]; then
    echo 1>&2 "error: you specified the inputformat $format but did not provide mandatory input options"
    echo 1>&2 "please provide column widths separated by comma (e.g. 7,5)"
    echo 1>&2 "example: ./openrefine-batch.sh ... -f $format -i columnWidths=7,5"
    exit 1
fi
if [ "$format" = "xlsx" ] || [ "$format" = "ods" ] && [ -z "$inputoptions" ]; then
    echo 1>&2 "error: you specified the inputformat $format but did not provide mandatory input options"
    echo 1>&2 "please provide sheets separated by comma (e.g. 0,1), default: 0 (first sheet)"
    echo 1>&2 "example: ./openrefine-batch.sh ... -f $format -i sheets=0"
    exit 1
fi

# print variables
echo "Input directory:         $inputdir"
echo "Input files:             ${inputfiles[*]}"
echo "Input format:            $inputformat"
echo "Input options:           ${inputoptions[*]}"
echo "Config directory:        $configdir"
echo "Transformation rules:    ${jsonfiles[*]}"
echo "Cross directory:         $crossdir"
echo "Cross projects:          ${crossprojects[*]}"
echo "OpenRefine heap space:   $ram"
echo "OpenRefine port:         $port"
echo "OpenRefine workspace:    $outputdir"
echo "Export to workspace:     $export"
echo "Export format:           $exportformat"
echo "Templating options:      ${templating[*]}"
echo "restart after file:      $restartfile"
echo "restart after transform: $restarttransform"
echo ""

# declare additional variables
checkpoints=${#checkpointdate[@]}
checkpointdate[$((checkpoints + 1))]=$(date +%s)
checkpointname[$((checkpoints + 1))]="Start process"
memoryload=()

# safe cleanup handler
cleanup()
{
  echo "cleanup..."
  kill ${pid}
  wait
  rm -r -f "${outputdir:?}"/workspace*.json
  # delete duplicates from copied projects
  if [ -n "$crossprojects" ]; then
      for i in "${crossprojects[@]}" ; do rm -r -f "${outputdir}/${i}" ; done
  fi
}
trap "cleanup;exit" SIGHUP SIGINT SIGQUIT SIGTERM

# launch server
checkpoints=${#checkpointdate[@]}
checkpointdate[$((checkpoints + 1))]=$(date +%s)
checkpointname[$((checkpoints + 1))]="Launch OpenRefine"
echo "=== $checkpoints. ${checkpointname[$((checkpoints + 1))]} ==="
echo ""
echo "starting time: $(date --date=@${checkpointdate[$((checkpoints + 1))]})"
echo ""
openrefine/refine -p ${port} -d "${outputdir}" -m ${ram} &
pid=$!
# wait until server is available
until wget -q -O - http://localhost:${port} | cat | grep -q -o "OpenRefine" ; do sleep 1; done
echo ""

# import all files
if [ -n "$inputfiles" ]; then
    checkpoints=${#checkpointdate[@]}
    checkpointdate[$((checkpoints + 1))]=$(date +%s)
    checkpointname[$((checkpoints + 1))]="Import all files"
    echo "=== $checkpoints. ${checkpointname[$((checkpoints + 1))]} ==="
    echo ""
    echo "starting time: $(date --date=@${checkpointdate[$((checkpoints + 1))]})"
    echo ""
    for inputfile in "${inputfiles[@]}" ; do
        echo "import ${inputfile}..."
        # run client with input command
        openrefine-client/openrefine-client_0-3-4_linux-64bit -P ${port} -c ${inputdir}/${inputfile} $inputformat "${inputoptions[@]}"
        # show allocated system resources
        ps -o start,etime,%mem,%cpu,rss -p ${pid} --sort=start
        memoryload+=($(ps --no-headers -o rss -p ${pid}))
        echo ""
        # restart server to clear memory
        if [ "$restartfile" = "true" ]; then
            echo "save project and restart OpenRefine server..." 
            kill ${pid}
            wait
            echo ""
            openrefine/refine -p ${port} -d "${outputdir}" -m ${ram} &
            pid=$!
            until wget -q -O - http://localhost:${port} | cat | grep -q -o "OpenRefine" ; do sleep 1; done
            echo ""
        fi
    done
fi

# transform and export files
if [ -n "$jsonfiles" ] || [ "$export" = "true" ]; then
    checkpoints=${#checkpointdate[@]}
    checkpointdate[$((checkpoints + 1))]=$(date +%s)
    checkpointname[$((checkpoints + 1))]="Prepare transform & export"
    echo "=== $checkpoints. ${checkpointname[$((checkpoints + 1))]} ==="
    echo ""
    echo "starting time: $(date --date=@${checkpointdate[$((checkpoints + 1))]})"
    echo ""
    
    # get project ids
    echo "get project ids..."
    openrefine-client/openrefine-client_0-3-4_linux-64bit -P ${port} -l > "${outputdir}/projects.tmp"
    projectids=($(cut -c 2-14 "${outputdir}/projects.tmp"))
    projectnames=($(cut -c 17- "${outputdir}/projects.tmp"))
    cat "${outputdir}/projects.tmp" && rm "${outputdir:?}/projects.tmp"
    echo ""
    
    # provide additional OpenRefine projects for cross function
    if [ -n "$crossprojects" ]; then
        echo "provide additional projects for cross function..."
        # copy given projects to workspace
        rsync -a --exclude='*.project/history' "${crossdir}"/*.project "${outputdir}"
        # restart server to advertise copied projects
        echo "restart OpenRefine server to advertise copied projects..." 
        kill ${pid}
        wait
        echo ""
        openrefine/refine -p ${port} -d "${outputdir}" -m ${ram} &
        pid=$!
        until wget -q -O - http://localhost:${port} | cat | grep -q -o "OpenRefine" ; do sleep 1; done
        echo ""
    fi
    
    # loop for all projects
    for ((i=0;i<${#projectids[@]};++i)); do
        
        # apply transformation rules
        if [ -n "$jsonfiles" ]; then
            checkpoints=${#checkpointdate[@]}
            checkpointdate[$((checkpoints + 1))]=$(date +%s)
            checkpointname[$((checkpoints + 1))]="Transform ${projectnames[i]}"
            echo "=== $checkpoints. ${checkpointname[$((checkpoints + 1))]} ==="
            echo ""
            echo "starting time: $(date --date=@${checkpointdate[$((checkpoints + 1))]})"
            echo ""
            for jsonfile in "${jsonfiles[@]}" ; do
                echo "transform ${jsonfile}..."
                # run client with apply command
                openrefine-client/openrefine-client_0-3-4_linux-64bit -P ${port} -f ${configdir}/${jsonfile} ${projectids[i]}
                # allocated system resources
                ps -o start,etime,%mem,%cpu,rss -p ${pid} --sort=start
                memoryload+=($(ps --no-headers -o rss -p ${pid}))
                echo ""
                # restart server to clear memory
                if [ "$restarttransform" = "true" ]; then
                    echo "save project and restart OpenRefine server..." 
                    kill ${pid}
                    wait
                    echo ""
                    openrefine/refine -p ${port} -d "${outputdir}" -m ${ram} &
                    pid=$!
                    until wget -q -O - http://localhost:${port} | cat | grep -q -o "OpenRefine" ; do sleep 1; done
                fi
                echo ""
            done
        fi
        
        # export project to workspace
        if [ "$export" = "true" ]; then
            checkpoints=${#checkpointdate[@]}
            checkpointdate[$((checkpoints + 1))]=$(date +%s)
            checkpointname[$((checkpoints + 1))]="Export ${projectnames[i]}"
            echo "=== $checkpoints. ${checkpointname[$((checkpoints + 1))]} ==="
            echo ""
            echo "starting time: $(date --date=@${checkpointdate[$((checkpoints + 1))]})"
            echo ""
            # get filename without extension
            filename=${projectnames[i]%.*}
            echo "export to file ${filename}.${exportformat}..."
            # run client with export command
            openrefine-client/openrefine-client_0-3-4_linux-64bit -P ${port} -E --output="${outputdir}/${filename}.${exportformat}" "${templating[@]}" ${projectids[i]}
            # show allocated system resources
            ps -o start,etime,%mem,%cpu,rss -p ${pid} --sort=start
            memoryload+=($(ps --no-headers -o rss -p ${pid}))
            echo ""
        fi
        
        # restart server to clear memory
        if [ "$restartfile" = "true" ]; then    
            echo "restart OpenRefine server..." 
            kill ${pid}
            wait
            echo ""
            openrefine/refine -p ${port} -d "${outputdir}" -m ${ram} &
            pid=$!
            until wget -q -O - http://localhost:${port} | cat | grep -q -o "OpenRefine" ; do sleep 1; done
        fi
        echo ""        

    done
    
    # list output files
    if [ "$export" = "true" ]; then
        echo "output (number of lines / size in bytes):"
        wc -c -l "${outputdir}"/*.${exportformat}
        echo ""
    fi
fi

# run cleanup function
cleanup
echo ""

# calculate and print checkpoints
echo "=== Statistics ==="
echo ""
checkpoints=${#checkpointdate[@]}
checkpointdate[$((checkpoints + 1))]=$(date +%s)
checkpointname[$((checkpoints + 1))]="End process"
echo "starting time and run time of each step:"
checkpoints=${#checkpointdate[@]}
checkpointdate[$((checkpoints + 1))]=$(date +%s)
for i in $(seq 1 $checkpoints); do
    diffsec="$((${checkpointdate[$((i + 1))]} - ${checkpointdate[$i]}))"
    printf "%35s $(date --date=@${checkpointdate[$i]}) ($(date -d@${diffsec} -u +%H:%M:%S))\n" "${checkpointname[$i]}"
done
echo ""
diffsec="$((checkpointdate[$checkpoints] - checkpointdate[1]))"
echo "total run time: $(date -d@${diffsec} -u +%H:%M:%S) (hh:mm:ss)"

# calculate and print memory load
max=${memoryload[0]}
for n in "${memoryload[@]}" ; do
    ((n > max)) && max=$n
done
echo "highest memory load: $((max / 1024)) MB"
