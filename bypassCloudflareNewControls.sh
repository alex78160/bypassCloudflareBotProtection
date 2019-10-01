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
# the page returned by the first request
controlPage="controlPage.html"
# JavaScript extracted from the control page
controlScript="controlScript.js"
# final script containing only useful statements
finalScript="finalScript.js"
# initial cookie
initialCookie="initCookie.txt"
# to store the clearance cookie
clearanceCookie="clearanceCookie.txt"
# to check if the cookie file contains the expected cookie name
clearanceCookieName="cf_clearance"
# final page returned after the control
page="page.html"
# calcul dans le div
divcalc="divcalc.js"
# lastLine.js
lastLine="lastLine.js"
# to check if clearance cookie is returned, and try again if it fails
clearanceCookieOk=false
torstring="--socks5 127.0.0.1:9150"

########################## Customize as you wish ##########################
maxIterations=5
waitBeforeAttempts=4
##########################

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
	rm -rf cookie0.txt *.js clcookie.txt *.html
    ((iteration++))
    echo "getting control page..."
	curl $torstring "$rootUrl" -H 'upgrade-insecure-requests: 1' -H 'user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/76.0.3809.132 Safari/537.36 OPR/63.0.3368.94' -H 'sec-fetch-mode: navigate' -H 'accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8' -H 'sec-fetch-site: none' -H 'accept-encoding: gzip, deflate, br' -H 'accept-language: fr-FR,fr;q=0.9,en-US;q=0.8,en;q=0.7' --compressed --silent --output $controlPage -c $initialCookie
    echo "building js file to evaluate jschl_answer value..."

	grep -A 22 "setTimeout(function(){" $controlPage | tail -22 > $controlScript
	echo "var d1=" > $divcalc
	grep -A 20 "<form id=\"challenge" $controlPage | grep "<div style=\"display:none;visibility:hidden;\"" | awk -F '</div>' '{print $1}' | awk -F '>' '{print $NF}' >> $divcalc
	echo "console.log(d1);" >> $divcalc
	rm -rf $finalScript
	echo "t=\"$host\"" > $finalScript
    
    i=0
    while read line
    do
        ((i++))
        if [ $i -eq 2 ]
        then
            continue
        elif [ $i -eq 3 ]
        then
            continue
        elif [ $i -eq 1 ]
        then
            echo $line >> $finalScript
        elif [ $i -ge 4 ] && [ $i -le 15 ]
        then
            echo $line >> $finalScript
        elif [ $i -eq 22 ]
        then
            echo $line | sed "s/a.value/var test/" > $lastLine
        fi
    done < $controlScript

	cat $lastLine | awk -v dur="$(node $divcalc)" -F ';' '{for(i=2; i<=NF-2; i++){if (i==1){} else if (index($i,"var p") > 0) {print substr($i,0,index($i, "function")-1)dur";"; i++} else {print $i";"}}}' >> $finalScript
	echo "console.log(test);" >> $finalScript
	
	v1=$(grep "jschl_vc" $controlPage | awk -F "value=\"" '{print $2}' | awk -F "\"" '{print $1}')
	v2=$(grep "pass" $controlPage | awk -F "value=\"" '{print $2}' | awk -F "\"" '{print $1}' | sed "s/+/%2B/g" | sed "s/\//%2F/g" | sed "s/=/%3D/g")
	ss=$(grep "\"s\"" $controlPage | awk -F "value=\"" '{print $2}' | awk -F "\"" '{print $1}' | awk -F "\"" '{print $1}' | sed "s/+/%2B/g" | sed "s/\//%2F/g" | sed "s/=/%3D/g")
	v3=$(node $finalScript | awk -F "\"" '{print $1}')

    echo "sleeping 3 seconds to simulate JavaScript setTimeout..."
    sleep 3

    echo "getting clearance cookie..."
	
	urlcook=$rootUrl"cdn-cgi/l/chk_jschl"
	params=$urlcook"?s=$ss&jschl_vc=$v1&pass=$v2&jschl_answer=$v3"
	
	h1="'authority: $host'"
	h2="'upgrade-insecure-requests: 1'"
	h3="'user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/76.0.3809.132 Safari/537.36 OPR/63.0.3368.94'"
	h4="'sec-fetch-mode: navigate'"
	h5="'accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8'"
	h6="'sec-fetch-site: same-origin'"
	h7="'referer: $rootUrl'"
	h8="'accept-encoding: gzip, deflate, br'"
	h9="'accept-language: fr-FR,fr;q=0.9,en-US;q=0.8,en;q=0.7'"
	headers_get_commun=" -H "$h1" -H "$h2" -H "$h3" -H "$h4" -H "$h5" -H "$h6" -H "$h7" -H "$h8" -H "$h9

	commande="curl "$torstring" "\"$params\"" "$headers_get_commun" --compressed -b $initialCookie -c $clearanceCookie -s -o $page"
	echo "command : $commande"
	eval $commande
	echo "clearanceCookie : "
	cat $clearanceCookie
    
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



