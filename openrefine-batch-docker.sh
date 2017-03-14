#!/bin/bash
# openrefine-batch.sh, Felix Lohmeier, v1.0, 14.03.2017
# https://github.com/felixlohmeier/openrefine-batch

# check system requirements
DOCKER="$(which docker 2> /dev/null)"
if [ -z "$DOCKER" ] ; then
    echo 1>&2 "This action requires you to have 'docker' installed and present in your PATH. You can download it for free at http://www.docker.com/"
    exit 1
fi
DOCKERINFO="$(docker info 2>/dev/null | grep 'Server Version')"
if [ -z "$DOCKERINFO" ] ; then
    echo 1>&2 "This action requires you to start the docker daemon. Try 'sudo systemctl start docker' or 'sudo start docker'. If the docker daemon is already running then maybe some security privileges are missing to run docker commands. Try to run the script with 'sudo ./openrefine-batch-docker.sh ...'"
    exit 1
fi

# help screen
function usage () {
    cat <<EOF
Usage: ./openrefine-batch-docker.sh [-a INPUTDIR] [-b TRANSFORMDIR] [-c OUTPUTDIR] ...

== basic arguments ==
    -a INPUTDIR      path to directory with source files (leave empty to transform only ; multiple files may be imported into a single project by providing a zip or tar.gz archive, cf. https://github.com/OpenRefine/OpenRefine/wiki/Importers )
    -b TRANSFORMDIR  path to directory with OpenRefine transformation rules (json files, cf. http://kb.refinepro.com/2012/06/google-refine-json-and-my-notepad-or.html ; leave empty to transform only)
    -c OUTPUTDIR     path to directory for exported files (and OpenRefine workspace)

== options ==
    -d CROSSDIR      path to directory with additional OpenRefine projects (will be copied to workspace before transformation step to support the cross function, cf. https://github.com/OpenRefine/OpenRefine/wiki/GREL-Other-Functions )
    -f INPUTFORMAT   (csv, tsv, xml, json, line-based, fixed-width, xlsx, ods)
    -i INPUTOPTIONS  several options provided by openrefine-client, see below...
    -m RAM           maximum RAM for OpenRefine java heap space (default: 2048M)
    -v VERSION       OpenRefine version (2.7rc2, 2.7rc1, 2.6rc2, 2.6rc1, dev; default: 2.7rc2)
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

./openrefine-batch-docker.sh \
-a examples/powerhouse-museum/input/ \
-b examples/powerhouse-museum/config/ \
-c examples/powerhouse-museum/output/ \
-f tsv \
-i processQuotes=false \
-i guessCellValueTypes=true

clone or download GitHub repository to get example data:
https://github.com/felixlohmeier/openrefine-batch/archive/master.zip

EOF
   exit 1
}

# defaults
ram="2048M"
version="2.7rc2"
restartfile="true"
restarttransform="true"
export="true"
inputdir=/dev/null
configdir=/dev/null
crossdir=/dev/null

# check input
NUMARGS=$#
if [ "$NUMARGS" -eq 0 ]; then
  usage
fi

# get user input
options="a:b:c:d:f:i:m:p:ERXh"
while getopts $options opt; do
   case $opt in
   a )  inputdir=$(readlink -f ${OPTARG}); if [ -n "${inputdir// }" ] ; then inputfiles=($(find -L "${inputdir}"/* -type f -printf "%f\n" 2>/dev/null)); fi ;;
   b )  configdir=$(readlink -f ${OPTARG}); if [ -n "${configdir// }" ] ; then jsonfiles=($(find -L "${configdir}"/* -type f -printf "%f\n" 2>/dev/null)); fi ;;
   c )  outputdir=$(readlink -m ${OPTARG}); mkdir -p "${outputdir}" ;;
   d )  crossdir=$(readlink -f ${OPTARG}); if [ -n "${crossdir// }" ] ; then crossprojects=($(find -L "${crossdir}"/* -maxdepth 0 -type d -printf "%f\n" 2>/dev/null)); fi ;;
   f )  format="${OPTARG}" ; inputformat="--format=${OPTARG}" ;;
   i )  inputoptions+=("--${OPTARG}") ;;
   m )  ram=${OPTARG} ;;
   v )  version=${OPTARG} ;;
   E )  export="false" ;;
   R )  restarttransform="false" ;;
   X )  restartfile="false" ;;
   h )  usage ;;
   \? ) echo 1>&2 "Unknown option: -$OPTARG"; usage; exit 1;;
   :  ) echo 1>&2 "Missing option argument for -$OPTARG"; usage; exit 1;;
   *  ) echo 1>&2 "Unimplemented option: -$OPTARG"; usage; exit 1;;
   esac
done
shift $(($OPTIND - 1))

# check for mandatory options
if [ -z "$outputdir" ]; then
    echo 1>&2 "please provide path to directory for exported files (and OpenRefine workspace)"
    echo 1>&2 "example: ./openrefine-batch-docker.sh -c output/"
    exit 1
fi
if [ "$format" = "xml" ] || [ "$format" = "json" ] && [ -z "$inputoptions" ]; then
    echo 1>&2 "error: you specified the inputformat $format but did not provide mandatory input options"
    echo 1>&2 "please provide recordpath in multiple arguments without slashes"
    echo 1>&2 "example: ./openrefine-batch-docker.sh ... -f $format -i recordPath=collection -i recordPath=record"
    exit 1
fi
if [ "$format" = "fixed-width" ] && [ -z "$inputoptions" ]; then
    echo 1>&2 "error: you specified the inputformat $format but did not provide mandatory input options"
    echo 1>&2 "please provide column widths separated by comma (e.g. 7,5)"
    echo 1>&2 "example: ./openrefine-batch-docker.sh ... -f $format -i columnWidths=7,5"
    exit 1
fi
if [ "$format" = "xlsx" ] || [ "$format" = "ods" ] && [ -z "$inputoptions" ]; then
    echo 1>&2 "error: you specified the inputformat $format but did not provide mandatory input options"
    echo 1>&2 "please provide sheets separated by comma (e.g. 0,1), default: 0 (first sheet)"
    echo 1>&2 "example: ./openrefine-batch-docker.sh ... -f $format -i sheets=0"
    exit 1
fi

# print variables
uuid=$(cat /proc/sys/kernel/random/uuid)
echo "Input directory:         $inputdir"
echo "Input files:             ${inputfiles[*]}"
echo "Input format:            $inputformat"
echo "Input options:           ${inputoptions[*]}"
echo "Config directory:        $configdir"
echo "Transformation rules:    ${jsonfiles[*]}"
echo "Cross directory:         $crossdir"
echo "Cross projects:          ${crossprojects[*]}"
echo "OpenRefine heap space:   $ram"
echo "OpenRefine version:      $version"
echo "OpenRefine workspace:    $outputdir"
echo "Export TSV to workspace: $export"
echo "Docker container name:   $uuid"
echo "restart after file:      $restartfile"
echo "restart after transform: $restarttransform"
echo ""

# declare additional variables
checkpoints=${#checkpointdate[@]}
checkpointdate[$(($checkpoints + 1))]=$(date +%s)
checkpointname[$(($checkpoints + 1))]="Start process"

# launch server
checkpoints=${#checkpointdate[@]}
checkpointdate[$(($checkpoints + 1))]=$(date +%s)
checkpointname[$(($checkpoints + 1))]="Launch OpenRefine"
echo "=== $checkpoints. ${checkpointname[$(($checkpoints + 1))]} ==="
echo ""
echo "starting time: $(date --date=@${checkpointdate[$(($checkpoints + 1))]})"
echo ""
docker run -d --name=${uuid} -v ${outputdir}:/data felixlohmeier/openrefine:${version} -i 0.0.0.0 -m ${ram} -d /data
# wait until server is available
until docker run --rm --link ${uuid} --entrypoint /usr/bin/curl felixlohmeier/openrefine-client --silent -N http://${uuid}:3333 | cat | grep -q -o "OpenRefine" ; do sleep 1; done
# show server logs
docker attach ${uuid} &
echo ""

# import all files
if [ -n "$inputfiles" ]; then
    checkpoints=${#checkpointdate[@]}
    checkpointdate[$(($checkpoints + 1))]=$(date +%s)
    checkpointname[$(($checkpoints + 1))]="Import all files"
    echo "=== $checkpoints. ${checkpointname[$(($checkpoints + 1))]} ==="
    echo ""
    echo "starting time: $(date --date=@${checkpointdate[$(($checkpoints + 1))]})"
    echo ""
    for inputfile in "${inputfiles[@]}" ; do
        echo "import ${inputfile}..."
        # run client with input command
        docker run --rm --link ${uuid} -v ${inputdir}:/data felixlohmeier/openrefine-client -H ${uuid} -c $inputfile $inputformat ${inputoptions[@]}
        # show allocated system resources
        ps -o start,etime,%mem,%cpu,rss -C java --sort=start
        echo ""
        # restart server to clear memory
        if [ "$restartfile" = "true" ]; then
            echo "save project and restart OpenRefine server..." 
            docker stop -t=5000 ${uuid}
            docker rm ${uuid}
            docker run -d --name=${uuid} -v ${outputdir}:/data felixlohmeier/openrefine:${version} -i 0.0.0.0 -m ${ram} -d /data
            until docker run --rm --link ${uuid} --entrypoint /usr/bin/curl felixlohmeier/openrefine-client --silent -N http://${uuid}:3333 | cat | grep -q -o "OpenRefine" ; do sleep 1; done
            docker attach ${uuid} &
            echo ""
        fi
    done
fi

# transform and export files
if [ -n "$jsonfiles" ] || [ "$export" = "true" ]; then
    checkpoints=${#checkpointdate[@]}
    checkpointdate[$(($checkpoints + 1))]=$(date +%s)
    checkpointname[$(($checkpoints + 1))]="Prepare transform & export"
    echo "=== $checkpoints. ${checkpointname[$(($checkpoints + 1))]} ==="
    echo ""
    echo "starting time: $(date --date=@${checkpointdate[$(($checkpoints + 1))]})"
    echo ""
    
    # get project ids
    echo "get project ids..."
    docker run --rm --link ${uuid} felixlohmeier/openrefine-client -H ${uuid} -l > "${outputdir}/projects.tmp"
    projectids=($(cat "${outputdir}/projects.tmp" | cut -c 2-14))
    projectnames=($(cat "${outputdir}/projects.tmp" | cut -c 17-))
    cat "${outputdir}/projects.tmp" && rm "${outputdir:?}/projects.tmp"
    echo ""
    
    # provide additional OpenRefine projects for cross function
    if [ -n "$crossprojects" ]; then
        echo "provide additional projects for cross function..."
        # copy given projects to workspace
        rsync -a --exclude='*.project/history' "${crossdir}"/*.project "${outputdir}"
        # restart server to advertise copied projects
        echo "restart OpenRefine server to advertise copied projects..." 
        docker stop -t=5000 ${uuid}
        docker rm ${uuid}
        docker run -d --name=${uuid} -v ${outputdir}:/data felixlohmeier/openrefine:${version} -i 0.0.0.0 -m ${ram} -d /data
        until docker run --rm --link ${uuid} --entrypoint /usr/bin/curl felixlohmeier/openrefine-client --silent -N http://${uuid}:3333 | cat | grep -q -o "OpenRefine" ; do sleep 1; done
        docker attach ${uuid} &
        echo ""
    fi
    
    # loop for all projects
    for ((i=0;i<${#projectids[@]};++i)); do
        
        # apply transformation rules
        if [ -n "$jsonfiles" ]; then
            checkpoints=${#checkpointdate[@]}
            checkpointdate[$(($checkpoints + 1))]=$(date +%s)
            checkpointname[$(($checkpoints + 1))]="Transform ${projectnames[i]}"
            echo "=== $checkpoints. ${checkpointname[$(($checkpoints + 1))]} ==="
            echo ""
            echo "starting time: $(date --date=@${checkpointdate[$(($checkpoints + 1))]})"
            echo ""
            for jsonfile in "${jsonfiles[@]}" ; do
                echo "transform ${jsonfile}..."
                # run client with apply command
                docker run --rm --link ${uuid} -v ${configdir}:/data felixlohmeier/openrefine-client -H ${uuid} -f ${jsonfile} ${projectids[i]}
                # allocated system resources
                ps -o start,etime,%mem,%cpu,rss -C java --sort=start
                echo ""
                # restart server to clear memory
                if [ "$restarttransform" = "true" ]; then
                  echo "save project and restart OpenRefine server..." 
                  docker stop -t=5000 ${uuid}
                  docker rm ${uuid}
                  docker run -d --name=${uuid} -v ${outputdir}:/data felixlohmeier/openrefine:${version} -i 0.0.0.0 -m ${ram} -d /data
                  until docker run --rm --link ${uuid} --entrypoint /usr/bin/curl felixlohmeier/openrefine-client --silent -N http://${uuid}:3333 | cat | grep -q -o "OpenRefine" ; do sleep 1; done
                  docker attach ${uuid} &
                fi
                echo ""
            done
        fi
        
        # export project to workspace
        if [ "$export" = "true" ]; then
            checkpoints=${#checkpointdate[@]}
            checkpointdate[$(($checkpoints + 1))]=$(date +%s)
            checkpointname[$(($checkpoints + 1))]="Export ${projectnames[i]}"
            echo "=== $checkpoints. ${checkpointname[$(($checkpoints + 1))]} ==="
            echo ""
            echo "starting time: $(date --date=@${checkpointdate[$(($checkpoints + 1))]})"
            echo ""
            # get filename without extension
            filename=${projectnames[i]%.*}
            echo "export to file ${filename}.tsv..."
            # run client with export command
            docker run --rm --link ${uuid} -v ${outputdir}:/data felixlohmeier/openrefine-client -H ${uuid} -E --output="${filename}.tsv" ${projectids[i]}
            # show allocated system resources
            ps -o start,etime,%mem,%cpu,rss -C java --sort=start
            echo ""
        fi
        
        # restart server to clear memory
        if [ "$restartfile" = "true" ]; then    
              echo "restart OpenRefine server..." 
              docker stop -t=5000 ${uuid}
              docker rm ${uuid}
              docker run -d --name=${uuid} -v ${outputdir}:/data felixlohmeier/openrefine:${version} -i 0.0.0.0 -m ${ram} -d /data
              until docker run --rm --link ${uuid} --entrypoint /usr/bin/curl felixlohmeier/openrefine-client --silent -N http://${uuid}:3333 | cat | grep -q -o "OpenRefine" ; do sleep 1; done
              docker attach ${uuid} &
        fi
        echo ""        

    done
    
    # list output files
    if [ "$export" = "true" ]; then
        echo "output (number of lines / size in bytes):"
        wc -c -l "${outputdir}"/*.tsv
        echo ""
    fi
fi

# cleanup
echo "cleanup..."
docker stop -t=5000 ${uuid}
docker rm ${uuid}
rm -r -f "${outputdir:?}"/workspace*.json
# delete duplicates from copied projects
if [ -n "$crossprojects" ]; then
    for i in "${crossprojects[@]}" ; do rm -r -f "${outputdir}/${i}" ; done
fi
echo ""

# calculate and print checkpoints
echo "=== Statistics ==="
echo ""
checkpoints=${#checkpointdate[@]}
checkpointdate[$(($checkpoints + 1))]=$(date +%s)
checkpointname[$(($checkpoints + 1))]="End process"
echo "starting time and run time of each step:"
checkpoints=${#checkpointdate[@]}
checkpointdate[$(($checkpoints + 1))]=$(date +%s)
for i in $(seq 1 $checkpoints); do
    diffsec="$((${checkpointdate[$(($i + 1))]} - ${checkpointdate[$i]}))"
    printf "%35s $(date --date=@${checkpointdate[$i]}) ($(date -d@${diffsec} -u +%H:%M:%S))\n" "${checkpointname[$i]}"
done
echo ""
diffsec="$((${checkpointdate[$checkpoints]} - ${checkpointdate[1]}))"
echo "total run time: $(date -d@${diffsec} -u +%H:%M:%S) (hh:mm:ss)"
