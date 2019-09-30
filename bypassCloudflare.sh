#!/bin/bash

if [ -z $1 ]
then
    echo "root url missing"
    exit 1
fi
# this is the url on which you perform the initial GET request
rootUrl=$1
# we create a working folder to store files used in this script
rootFolder="tmp_"$(date +%Y%m%d-%H%M%S)
# host extracted from rootUrl
host=$(echo $rootUrl | awk -F "://" '{print $2}' | awk -F "/" '{print $1}')
# used to calculate jschl_answer value
tLength=${#host}
# the page returned by the first request
controlPage="controlPage.html"
# JavaScript extracted from the control page
controlScript="controlScript.js"
# final script containing only useful statements
finalScript="finalScript.js"
# to store the clearance cookie
clearanceCookie="clearanceCookie.txt"
# to check if the cookie file contains the expected cookie name
clearanceCookieName="cf_clearance"
# final page returned after the control
page="page.html"
# to check if clearance cookie is returned, and try again if it fails
clearanceCookieOk=false

########################## Customize as you wish ##########################
maxIterations=5
waitBeforeAttempts=4
##########################

echo "tLength = $tLength"
echo "working in folder $rootFolder"

mkdir $rootFolder
cd $rootFolder

iteration=0
while [ $clearanceCookieOk == false ] && ((iteration < maxIterations))
do
    rm -f $controlPage
    rm -f $finalScript
    rm -f $clearanceCookie
    rm -f $page
    ((iteration++))
    echo "getting control page..."
    curl "$rootUrl" -H "Host: $host" -H 'User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:54.0) Gecko/20100101 Firefox/54.0' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8' -H 'Accept-Language: en-US,en;q=0.5' --compressed -H 'DNT: 1' -H 'Connection: keep-alive' -H 'Upgrade-Insecure-Requests: 1' -o $controlPage -s
    echo "building js file to evaluate jschl_answer value..."
    grep -A 22 "setTimeout(function(){" $controlPage | tail -22 > $controlScript

    i=0
    while read line
    do
        ((i++))
        if [ $i -eq 22 ]
        then
            echo $line | sed "s/t.length/$tLength/" | sed "s/'; 121'/;/" | sed "s/a.value/var test/" >> $finalScript
        elif [ $i -eq 1 ]
        then
            echo $line >> $finalScript
        fi
    done < $controlScript
    echo "console.log(Number(test).toFixed(10));" >> $finalScript

    s=$(grep "name=\"s\"" $controlPage | awk -F "value=\"" '{print $2}' | awk -F "\"" '{print $1}')
    jschl_vc=$(grep "jschl_vc" $controlPage | awk -F "value=\"" '{print $2}' | awk -F "\"" '{print $1}')
    pass=$(grep "pass" $controlPage | awk -F "value=\"" '{print $2}' | awk -F "\"" '{print $1}' | sed "s/+/%2b/g" | sed "s/\//%2f/g" | sed "s/\./%2e/g" | sed "s/-/%2d/g")
    jschl_answer=$(node $finalScript)

    echo "jschl_vc=$jschl_vc"
    echo "pass=$pass"
    echo "jschl_answer=$jschl_answer"
    echo "s=$s"

    echo "sleeping 4 seconds to simulate JavaScript setTimeout..."
    sleep 4

    echo "getting clearance cookie..."

    curl "$rootUrl/cdn-cgi/l/chk_jschl?s=$s&jschl_vc=$jschl_vc&pass=$pass&jschl_answer=$jschl_answer" -H "Host: $host" -H "User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:54.0) Gecko/20100101 Firefox/54.0" -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" -H "Accept-Language: en-US,en;q=0.5" -H "Connection: keep-alive" -H "Upgrade-Insecure-Requests: 1" -c $clearanceCookie -s -L -o $page

    echo "checking clearance cookie..."
    if grep -q $clearanceCookieName $clearanceCookie
    then
        echo "clearance cookie ok"
        clearanceCookieOk=true
        # SUCCESS ! now we got clearance cookie in a file and we can use it to perform any request as a browser with curl -b $clearanceCookie !
        exit 0
    else
        echo "failure while getting clearance cookie (attempt #$iteration)"
        echo "waiting $waitBeforeAttempts seconds before next attempt ..."
        sleep $waitBeforeAttempts
        continue
    fi
done

if [ $clearanceCookieOk == false ]
then
    echo "error while getting clearance cookie : failure after $iteration attempts"
    exit 1
fi


