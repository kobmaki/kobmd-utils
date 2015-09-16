#!/bin/bash
# Author: Uwe Ebel (kobmaki)
# Copyright by Uwe Ebel
# License: GPL v2
# Info: Helper skript for converting markup 
# Info: into mediawiki language 


# 2nd parameter is the configuration file, we ignore fails
.  "${2}" 2>/dev/null

myVersion="1.0"
PROVIDES=${PROVIDES-kob-mdutil-mediawiki}

#
# all Variables have the PREFIX KOBMDUTIL
#

# where is pandoc?
KOBMDUTIL_PANDOC_BIN=${KOBMDUTIL_PANDOC_BIN-`which pandoc`}

# which php should we use?
KOBMDUTIL_PHP_BIN=${KOBMDUTIL_PHP_BIN-`which php6 || which php5 || which php`}

# what is the namespace in the mediawiki
KOBMDUTIL_MW_NAMESPACE=${KOBMDUTIL_MW_NAMESPACE-MD-IMPORT:}


# template header
KOBMDUTIL_MW_HEAD=${KOBMDUTIL_MW_HEAD-mw-head.mwt}

# template footer
KOBMDUTIL_MW_FOOT=${KOBMDUTIL_MW_FOOT-mw-foot.mwt}

function decho (){
    #
    # print out, only when the variable DEBUG is not empty
    #          
    if [ "${DEBUG}"!="" ]; then
	echo $@
    fi
}

function kob_status (){
    #
    # output with color
    # 0 = green
    # 1 = red
    #
    local _kob_status_ret=$?
    case ${_kob_status_ret} in
	0) echo -n  "$(tput setaf 2 2>/dev/null)$1$(tput sgr0 2>/dev/null)"
	   [[ -z $1 ]] ||  echo
	   ;;
	1) echo -n  "$(tput setaf 1 2>/dev/null)$2$(tput sgr0 2>/dev/null)"
	   [[  -z $2 ]] || echo
	   ;;
	*)
	    echo "UNKNOWN $_kob_status_ret "$3
	    ;;
    esac
    return $_kob_status_ret
}

function kob_show (){
    #
    # helper functions for showing variable value
    #
    echo -n ${1}": "
    kob_status ${!1}
    test -z ${!1} && echo
}


function mwFixNameSpaceLinks () {
    #
    # fix links to namespace
    #
    echo -n "fixing name space links "
    local aText
    local aReplace
    local i
    cd ${KOBMDUTIL_MW_TARGET} || return false
    for i in $(ls -1 *.mw|sed s/".mw"//g); do
	echo -n "."
	aText='\[\['${i}.md;
	decho "aText:${aText}"
	aReplace='\[\['${KOBMDUTIL_MW_NAMESPACE}:${i};
	decho "aReplace:"${aReplace}
	sed --follow-symlinks -i s/"${aText}"/"${aReplace}"/g *.mw
    done;
}

function getConf () {
cat <<EOF
#
# Configuration for ${0}
# Created: $(date)
# by: $(id -un) on $(hostname -f)
KOBMDUTIL_PANDOC_BIN=${KOBMDUTIL_PANDOC_BIN}

# directory location of the markup files
KOBMDUTIL_MD_SOURCE=${KOBMDUTIL_MD_SOURCE}

# directory location for the created mediawiki file
KOBMDUTIL_MW_TARGET=${KOBMDUTIL_MW_TARGET}
# where is the mediawiki installed?
KOBMDUTIL_MW_PATH=${KOBMDUTIL_MW_PATH}
# which namespace should we use?
KOBMDUTIL_MW_NAMESPACE=${KOBMDUTIL_MW_NAMESPACE} 

KOBMDUTIL_MW_HEAD=${KOBMDUTIL_MW_HEAD}
KOBMDUTIL_MW_FOOT=${KOBMDUTIL_MW_FOOT}
#

EOF
}

KOBMDUTIL_CONF=${KOBMDUTIL_CONF-${2}}


# 2nd parameter is the configuration file, we ignore fails
.  "${2}" 2>/dev/null


case ${1} in
    info)
	echo "Info(ing) ${PROVIDES}"
	for par in KOBMDUTIL_CONF KOBMDUTIL_PANDOC_BIN KOBMDUTIL_PHP_BIN KOBMDUTIL_MD_SOURCE KOBMDUTIL_MW_NAMESPACE KOBMDUTIL_MW_PATH  KOBMDUTIL_MW_TARGET KOBMDUTIL_MW_HEAD KOBMDUTIL_MW_FOOT; do
	    kob_show ${par}
	done
	true
	;;

    conf-get)
	getConf
	;;

    head-mwt)
	cat ${KOBMDUTIL_MW_FOOT} 2>/dev/null || echo "<noinclude>no KOBMDUTIL_MW_FOOT definiend</noinclude>"
	;;

    foot-mwt)
	cat ${KOBMDUTIL_MW_FOOT} 2>/dev/null || echo "[[Category:${KOBMDUTIL_MW_NAMESPACE}]]"
	;;
    
    create-mw-files)
	cd ${KOBMDUTIL_MD_SOURCE} || kob_status "" "ERROR could not change to ${KOBMDUTIL_MD_SOURCE} "
	mkdir ${KOBMDUTIL_MW_TARGET} 2>/dev/null
	for i in $(ls -1 *.md|sed s/"\.md$"//g); do
	    echo -n ${i}" ";
	    ${KOBMDUTIL_PANDOC_BIN} -t mediawiki $i.md -o ${KOBMDUTIL_MW_TARGET}/${i}.$$.mw;
	    ${0} head-mwt ${2} > ${KOBMDUTIL_MW_TARGET}/${i}.mw
	    cat ${KOBMDUTIL_MW_TARGET}/$i.$$.mw >> ${KOBMDUTIL_MW_TARGET}/${i}.mw
	    ${0} foot-mwt ${2} >> ${KOBMDUTIL_MW_TARGET}/${i}.mw
	    rm ${KOBMDUTIL_MW_TARGET}/${i}.$$.mw
	    kob_status "OK" "ERROR"
	    done
	;;

    fix-mw-files)
	echo -n "Fixing files"
	cd ${KOBMDUTIL_MW_TARGET}
	cd ${KOBMDUTIL_MW_TARGET} || kob_status "" "ERROR could not change to ${KOBMDUTIL_MW_TARGET}"
	sed --follow-symlinks -i 's/^= <a.*a>/=/g' *.mw
	echo -n "."
	sed --follow-symlinks -i 's/== <a.*a>/==/g' *.mw 
	echo -n "."
	sed --follow-symlinks -i 's/"=== <a.*a>/===/g' *.mw 
	echo -n "."
	sed --follow-symlinks -i s/"^{|$"/"\{\| class=\"wikitable zebra sortable\""/g *.mw
	echo -n "."
	mwFixNameSpaceLinks
	for i in $(ls -1 *.mw|sed s/".mw$"//g); do
	    echo -n "." #$i" ";
	    #           cat ${KOBMDUTIL_MW_FOOT} >>  ${KOBMDUTIL_MW_TARGET}/$i.mw
	    sed --follow-symlinks -i "s/\[\[${i}.md/${KOBMDUTIL_MW_NAMESPACE}:${i}/" ${KOBMDUTIL_MW_TARGET}/$i.mw

	    done
	echo " finished"
	;;
    
    create-fix-mw-files)
	shift
	$0 create-mw-files $@
	$0 fix-mw-files $@
	;;
    
    create-fix-import-mw-files)
	shift
	$0 create-fix-mw-files $@
	$0 import-mw-files $@
	;;

    import-mw-files)
	echo "Importing"
	cd ${KOBMDUTIL_MW_TARGET}
	for i in $(ls -1 *mw| sed s/".mw$"//g); do
	    echo -n $i" ";
	    cat $i.mw | php ${KOBMDUTIL_MW_PATH}/maintenance/edit.php ${KOBMDUTIL_MW_NAMESPACE}":"$i;
	done;
	;;

    help)
	echo "Help(ing) for $0"
	echo "help - this help output"
	echo "info - info about all variables and paths"
	echo "check - check everything is fine to run the script"
	echo "get-conf - gives the conf file"
	echo "create-mw-files - creates the mediawiki files from the markup files"
	echo "fix-mw-files - fix the mediawiki files, like links, name ending md"
	echo "import-mw-files - import the mw files to mediawiki"
	echo "create-fix-mw-files - do create-mw-files then fix-mw-files"
	echo "create-fix-import-mw-files - do create-fix-mw-files then import-mw-files"
	;;
    example)
	echo "Example"
	;;
    check)
	echo "Check(ing)"
	test -d ${KOBMDUTIL_MW_TARGET}
	kob_status "OK directory '${KOBMDUTIL_MW_TARGET}' exist" "Error directory '${KOBMDUTIL_MW_TARGET}' not exist"
	test -w ${KOBMDUTIL_MW_TARGET}
	kob_status "OK directory '${KOBMDUTIL_MW_TARGET}' writeable" "Error directory '${KOBMDUTIL_MW_TARGET}' not writeable"
	;;
    *)
	echo "Usage: "${0}" [help|info|check|conf-get|example|create-mw-files|fix-mw-files|import-mw-files|create-fix-mw-files|create-fix-import-mw-files|head-mwt|foot-mwt] [--conf=CONF-FILE] [--mw-path=PathToMediawiki]"
	;;
esac