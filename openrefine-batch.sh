#!/bin/bash
# openrefine-batch.sh, Felix Lohmeier, v0.6.1, 01.03.2017
# https://github.com/felixlohmeier/openrefine-batch

# user input
if [ -z "$1" ]
  then
    echo 1>&2 "please provide path to directory with source files (leave empty to transform only)"
    exit 2
  else
    inputdir=$(readlink -f $1)
    if [ ! -z "${inputdir// }" ] ; then
      inputfiles=($(find -L ${inputdir}/* -type f -printf "%f\n" 2>/dev/null))
    fi
fi
if [ -z "$2" ]
  then
    echo 1>&2 "please provide path to directory with config files (leave empty to import only)"
    exit 2
  else
    configdir=$(readlink -f $2)
    if [ ! -z "${configdir// }" ] ; then
      jsonfiles=($(find -L ${configdir}/* -type f -printf "%f\n" 2>/dev/null))
    fi
fi
if [ -z "$3" ]
  then
    echo 1>&2 "please provide path to output directory"
    exit 2
  else
    outputdir=$(readlink -m $3)
    mkdir -p ${outputdir}
fi
if [ -z "$4" ]
  then
    echo 1>&2 "please provide path to directory with additional OpenRefine projects for use with cross function (may be empty)"
    exit 2
  else
    crossdir=$(readlink -f $4)
    if [ ! -z "${crossdir// }" ] ; then
      crossprojects=($(find -L ${crossdir}/* -maxdepth 0 -type d -printf "%f\n" 2>/dev/null))
    fi
fi
if [ -z "$5" ]
  then
    ram="4G"
  else
    ram="$5"
fi
if [ -z "$6" ]
  then
    version="2.7rc1"
  else
    version="$6"
fi
if [ -z "$7" ]
  then
    restartfile="restartfile-true"
  else
    restartfile="$7"
fi
if [ -z "$8" ]
  then
    restarttransform="restarttransform-false"
  else
    restarttransform="$8"
fi
if [ -z "$9" ]
  then
    export="export-true"
  else
    export="$9"
fi
if [ -z "${10}" ]
  then
    inputformat=""
  else
    inputformat="--format=${10}"
fi
if [ -z "${11}" ]
  then
    inputoptions=""
  else
    inputoptions=( "${11}" "${12}" "${13}" "${14}" "${15}" "${16}" "${17}" "${18}" "${19}" "${20}" "${21}" "${22}" "${23}" "${24}" "${25}" )
fi

# variables
uuid=$(cat /proc/sys/kernel/random/uuid)
echo "Input directory:         $inputdir"
echo "Input files:             ${inputfiles[@]}"
echo "Input format:            $inputformat"
echo "Input options:           ${inputoptions[@]}"
echo "Config directory:        $configdir"
echo "Transformation rules:    ${jsonfiles[@]}"
echo "Cross directory:         $crossdir"
echo "Cross projects:          ${crossprojects[@]}"
echo "OpenRefine heap space:   $ram"
echo "OpenRefine version:      $version"
echo "OpenRefine workspace:    $outputdir"
echo "Export TSV to workspace: $export"
echo "Docker container name:   $uuid"
echo "restart after file:      $restartfile"
echo "restart after transform: $restarttransform"
echo ""

# time
echo "begin: $(date)"
echo ""

# launch server
echo "start OpenRefine server..."
docker run -d --name=${uuid} -v ${outputdir}:/data felixlohmeier/openrefine:${version} -i 0.0.0.0 -m ${ram} -d /data
# wait until server is available
until docker run --rm --link ${uuid} --entrypoint /usr/bin/curl felixlohmeier/openrefine-client --silent -N http://${uuid}:3333 | cat | grep -q -o "OpenRefine" ; do sleep 1; done
# show server logs
docker attach ${uuid} &
echo ""

# import all files
if [ -n "$inputfiles" ]; then
echo "=== IMPORT ==="
echo ""
    for inputfile in "${inputfiles[@]}" ; do
        echo "import ${inputfile}..."
        # run client with input command
        docker run --rm --link ${uuid} -v ${inputdir}:/data felixlohmeier/openrefine-client -H ${uuid} -c $inputfile $inputformat ${inputoptions[@]}
        # show statistics
        ps -o start,etime,%mem,%cpu,rss -C java --sort=start
        echo ""
        # restart server to clear memory
        if [ "$restartfile" = "restartfile-true" ]; then
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

echo "=== TRANSFORM / EXPORT ==="
echo ""

# get project ids
echo "get project ids..."
projects=($(docker run --rm --link ${uuid} felixlohmeier/openrefine-client -H ${uuid} -l | tee ${outputdir}/projects.tmp | cut -c 2-14))
cat ${outputdir}/projects.tmp && rm ${outputdir}/projects.tmp
echo ""

# provide additional OpenRefine projects for cross function
if [ -n "$crossprojects" ]; then
    echo "provide additional projects for cross function..."
    # copy given projects to workspace
    rsync -a --exclude='*.project/history' $crossdir/*.project $outputdir
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
for projectid in "${projects[@]}" ; do
    # time
    echo "--- begin project $projectid @ $(date) ---"
    echo ""

    # apply transformation rules
    if [ -n "$jsonfiles" ]; then
        for jsonfile in "${jsonfiles[@]}" ; do
            echo "transform ${jsonfile}..."
            # run client with apply command
            docker run --rm --link ${uuid} -v ${configdir}:/data felixlohmeier/openrefine-client -H ${uuid} -f ${jsonfile} ${projectid}
            # show statistics
            ps -o start,etime,%mem,%cpu,rss -C java --sort=start
            # restart server to clear memory
            if [ "$restarttransform" = "restarttransform-true" ]; then
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
    if [ "$export" = "export-true" ]; then
        echo "export to file ${projectid}.tsv..."
        # run client with export command
        docker run --rm --link ${uuid} -v ${outputdir}:/data felixlohmeier/openrefine-client -H ${uuid} -E --output=${projectid}.tsv ${projectid}
        # show statistics
        ps -o start,etime,%mem,%cpu,rss -C java --sort=start
        # restart server to clear memory
        if [ "$restartfile" = "restartfile-true" ]; then    
            echo "restart OpenRefine server..." 
            docker stop -t=5000 ${uuid}
            docker rm ${uuid}
            docker run -d --name=${uuid} -v ${outputdir}:/data felixlohmeier/openrefine:${version} -i 0.0.0.0 -m ${ram} -d /data
            until docker run --rm --link ${uuid} --entrypoint /usr/bin/curl felixlohmeier/openrefine-client --silent -N http://${uuid}:3333 | cat | grep -q -o "OpenRefine" ; do sleep 1; done
            docker attach ${uuid} &
        fi
        echo""
    fi

    # time
    echo "--- finished project $projectid @ $(date) ---"
    echo ""
done

# list output files
if [ "$export" = "export-true" ]; then
    echo "output (number of lines / size in bytes):"
    wc -c -l ${outputdir}/*.tsv
    echo ""
fi

# cleanup
echo "cleanup..."
docker stop -t=5000 ${uuid}
docker rm ${uuid}
rm -r -f ${outputdir}/workspace*.json
echo ""

# time
echo "finish: $(date)"
