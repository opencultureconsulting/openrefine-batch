#!/bin/bash
# openrefine-batch.sh, Felix Lohmeier, v0.4, 27.02.2017
# https://github.com/felixlohmeier/openrefine-batch

# user input
if [ -z "$1" ]
  then
    echo 1>&2 "please provide path to directory with source files (leave empty to transform only)"
    exit 2
  else
    inputdir=$(readlink -f $1)
    inputfiles=($(find -L ${inputdir}/* -type f -printf "%f\n"))
fi
if [ -z "$2" ]
  then
    echo 1>&2 "please provide path to directory with config files (leave empty to import only)"
    exit 2
  else
    configdir=$(readlink -f $2)
    jsonfiles=($(find -L ${configdir}/* -type f -printf "%f\n"))
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
    crossprojects=($(find -L ${crossdir}/* -maxdepth 0 -type d -printf "%f\n"))
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
    restart="restart-true"
  else
    restart="$7"
fi
if [ -z "$8" ]
  then
    inputformat=""
  else
    inputformat="--format=${8}"
fi
if [ -z "$9" ]
  then
    inputoptions=""
  else
    inputoptions=( "$9" "${10}" "${11}" "${12}" "${13}" "${14}" "${15}" "${16}" "${17}" "${18}" "${19}" "${20}" )
fi

# variables
uuid=$(cat /proc/sys/kernel/random/uuid)
echo "Input directory:        $inputdir"
echo "Input files:            ${inputfiles[@]}"
echo "Input format:           $inputformat"
echo "Input options:          ${inputoptions[@]}"
echo "Config directory:       $configdir"
echo "Transformation rules:   ${jsonfiles[@]}"
echo "Cross directory:        $crossdir"
echo "Cross projects:         ${crossprojects[@]}"
echo "OpenRefine heap space:  $ram"
echo "OpenRefine version:     $version"
echo "Docker container:       $uuid"
echo "Docker restart:         $restart"
echo "Output directory:       $outputdir"
echo ""

# time
echo "begin: $(date)"
echo ""

# launch openrefine server
echo "start OpenRefine server..."
sudo docker run -d --name=${uuid} -v ${outputdir}:/data felixlohmeier/openrefine:${version} -i 0.0.0.0 -m ${ram} -d /data
until sudo docker run --rm --link ${uuid} --entrypoint /usr/bin/curl felixlohmeier/openrefine-client --silent -N http://${uuid}:3333 | cat | grep -q -o "OpenRefine" ; do sleep 1; done
echo ""

if [ -n "$inputfiles" ]; then
    # import all files
    for inputfile in "${inputfiles[@]}" ; do
        echo "import ${inputfile}..."
        # import
        sudo docker run --rm --link ${uuid} -v ${inputdir}:/data felixlohmeier/openrefine-client -H ${uuid} -c $inputfile $inputformat ${inputoptions[@]}
        # show server logs
        sudo docker attach ${uuid} &
        # statistics
        ps -o start,etime,%mem,%cpu,rss -C java
        # restart server to clear memory
        echo "save project and restart OpenRefine server..." 
        sudo docker stop -t=5000 ${uuid}
        sudo docker rm ${uuid}
        sudo docker run -d --name=${uuid} -v ${outputdir}:/data felixlohmeier/openrefine:${version} -i 0.0.0.0 -m ${ram} -d /data
        until sudo docker run --rm --link ${uuid} --entrypoint /usr/bin/curl felixlohmeier/openrefine-client --silent -N http://${uuid}:3333 | cat | grep -q -o "OpenRefine" ; do sleep 1; done
        echo ""
    done
fi

if [ -n "$jsonfiles" ]; then
    # get project ids
    projects=($(sudo docker run --rm --link ${uuid} felixlohmeier/openrefine-client -H ${uuid} -l | cut -c 2-14))

    # copy existing projects for use with OpenRefine cross function
    if [ -n "$crossprojects" ]; then
        cp -r $crossdir/*.project $outputdir/
    fi
    
    # loop for all projects
    for projectid in "${projects[@]}" ; do
        echo "begin project $projectid @ $(date)"
        # apply transformation rules
        for jsonfile in "${jsonfiles[@]}" ; do
            echo "transform ${jsonfile}..."
            # show server logs
            sudo docker attach ${uuid} &
            # apply
            sudo docker run --rm --link ${uuid} -v ${configdir}:/data felixlohmeier/openrefine-client -H ${uuid} -f ${jsonfile} ${projectid}
            # statistics
            ps -o start,etime,%mem,%cpu,rss -C java
            if [ "$restart" = "restart-true" ]; then
                # restart server to clear memory
                echo "save project and restart OpenRefine server..." 
                sudo docker stop -t=5000 ${uuid}
                sudo docker rm ${uuid}
                sudo docker run -d --name=${uuid} -v ${outputdir}:/data felixlohmeier/openrefine:${version} -i 0.0.0.0 -m ${ram} -d /data
                until sudo docker run --rm --link ${uuid} --entrypoint /usr/bin/curl felixlohmeier/openrefine-client --silent -N http://${uuid}:3333 | cat | grep -q -o "OpenRefine" ; do sleep 1; done
            fi
        done
        # export files
        echo "export to file ${projectid}.tsv..."
        # show server logs
        sudo docker attach ${uuid} &
        # export
        sudo docker run --rm --link ${uuid} -v ${outputdir}:/data felixlohmeier/openrefine-client -H ${uuid} -E --output=${projectid}.tsv ${projectid}
        # statistics
        ps -o start,etime,%mem,%cpu,rss -C java
        # restart server to clear memory
        echo "restart OpenRefine server..." 
        sudo docker stop -t=5000 ${uuid}
        sudo docker rm ${uuid}
        sudo docker run -d --name=${uuid} -v ${outputdir}:/data felixlohmeier/openrefine:${version} -i 0.0.0.0 -m ${ram} -d /data
        until sudo docker run --rm --link ${uuid} --entrypoint /usr/bin/curl felixlohmeier/openrefine-client --silent -N http://${uuid}:3333 | cat | grep -q -o "OpenRefine" ; do sleep 1; done
        # time
        echo "finished project $projectid @ $(date)"
        echo ""
    done
    # list output files
    echo "output (number of lines / size in bytes):"
    wc -c -l ${outputdir}/*.tsv
    echo ""
fi

# cleanup
echo "cleanup..."
sudo docker stop -t=5000 ${uuid}
sudo docker rm ${uuid}
sudo rm -r -f ${outputdir}/workspace*.json
echo ""

# time
echo "finish: $(date)"
