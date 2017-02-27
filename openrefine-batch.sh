#!/bin/bash
# openrefine-batch.sh, Felix Lohmeier, v0.1, 27.02.2017
# https://github.com/felixlohmeier/openrefine-batch

# user input
if [ -z "$1" ]
  then
    echo 1>&2 "please provide path to directory with source files"
    exit 2
  else
    inputdir=$(readlink -f $1)
    inputfiles=($(basename -a ${inputdir}/*))
fi
if [ -z "$2" ]
  then
    echo 1>&2 "please provide path to directory with config files"
    exit 2
  else
    configdir=$(readlink -f $2)
    jsonfiles=($(basename -a ${configdir}/*))
fi
if [ -z "$3" ]
  then
    echo 1>&2 "please provide path to output directory"
    exit 2
  else
    outputdir=$(readlink -f $3)
    mkdir -p ${outputdir}
fi
if [ -z "$4" ]
  then
    ram="4G"
  else
    ram="$4"
fi
if [ -z "$5" ]
  then
    inputformat=""
  else
    inputformat="--format=${5}"
fi
if [ -z "$6" ]
  then
    inputoptions=""
  else
    inputoptions=( "$6" "$7" "$8" "$9" "${10}" "${11}" "${12}" "${13}" "${14}" "${15}" )
fi

# variables
version="2.7rc1"
uuid=$(cat /proc/sys/kernel/random/uuid)
echo "Input dir:              $inputdir"
echo "Input files:            ${inputfiles[@]}"
echo "Input format:           $inputformat"
echo "Input options:          ${inputoptions[@]}"
echo "Transformation rules:   ${jsonfiles[@]}"
echo "OpenRefine heap space:  $ram"
echo "OpenRefine version:     $version"
echo "Docker container:       $uuid"
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

# get project ids
projects=($(sudo docker run --rm --link ${uuid} felixlohmeier/openrefine-client -H ${uuid} -l | cut -c 2-14))

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
        # restart server to clear memory
        echo "save project and restart OpenRefine server..." 
        sudo docker stop -t=5000 ${uuid}
        sudo docker rm ${uuid}
        sudo docker run -d --name=${uuid} -v ${outputdir}:/data felixlohmeier/openrefine:${version} -i 0.0.0.0 -m ${ram} -d /data
        until sudo docker run --rm --link ${uuid} --entrypoint /usr/bin/curl felixlohmeier/openrefine-client --silent -N http://${uuid}:3333 | cat | grep -q -o "OpenRefine" ; do sleep 1; done
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

# cleanup
echo "cleanup..."
sudo docker stop -t=5000 ${uuid}
sudo docker rm ${uuid}
sudo rm -r -f ${outputdir}/*.project
sudo rm -r -f ${outputdir}/workspace*.json
echo ""

# list output files
echo "output (number of lines / size in bytes):"
wc -c -l ${outputdir}/*.tsv
echo ""

# time
echo "finish: $(date)"
