#!/bin/bash
# Author: Uwe Ebel (kobmaki)
# Copyright: Uwe Ebel
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
KOBMDUTIL_PANDOC_BIN=${KOBMDUTIL_PANDOC_BIN-`which pandoc 2>/dev/null`}

# which php should we use?
KOBMDUTIL_PHP_BIN=${KOBMDUTIL_PHP_BIN-`which php6 2>/dev/null || which php5 2>/dev/null || which php 2>/dev/null`}

# what is the namespace in the mediawiki
KOBMDUTIL_MW_NAMESPACE=${KOBMDUTIL_MW_NAMESPACE-MD-IMPORT}
KOBMDUTIL_MW_CATEGORIES=${KOBMDUTIL_MW_CATEGORIES-""}

# template header
KOBMDUTIL_MW_HEAD=${KOBMDUTIL_MW_HEAD-mw-head.mwt}

# template footer
KOBMDUTIL_MW_FOOT=${KOBMDUTIL_MW_FOOT-mw-foot.mwt}

function decho (){
    #
    # print out, only when the variable DEBUG is not empty
    #          
    if [ "${DEBUG}" != "" ]; then
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
    echo -n "fixing name space links ..."
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
# Start of configuration for $(basename ${0})
# Created: $(date)
# by: $(id -un) on $(hostname -f)

# Where is the pandoc binary?
KOBMDUTIL_PANDOC_BIN=${KOBMDUTIL_PANDOC_BIN}

# Directory location of the markdown files.
KOBMDUTIL_MD_SOURCE=${KOBMDUTIL_MD_SOURCE}

# Directory location for the created mediawiki file to save in.
KOBMDUTIL_MW_TARGET=${KOBMDUTIL_MW_TARGET}

# Where is the mediawiki installed?
KOBMDUTIL_MW_PATH=${KOBMDUTIL_MW_PATH}

# Which namespace should we use?
KOBMDUTIL_MW_NAMESPACE=${KOBMDUTIL_MW_NAMESPACE} 

# Which global additional head should be used?
KOBMDUTIL_MW_HEAD=${KOBMDUTIL_MW_HEAD}

# Which global additional footer should be used?
KOBMDUTIL_MW_FOOT=${KOBMDUTIL_MW_FOOT}

#End of configuration for $(basename ${0})
EOF
}

KOBMDUTIL_CONF=${KOBMDUTIL_CONF-${2}}

# derive the full name from the conf file
KOBMDUTIL_CONF_FULL=$(pwd `dirname ${KOBMDUTIL_CONF} 2>/dev/null`)/$(basename ${KOBMDUTIL_CONF} 2>/dev/null)

# 2nd parameter is the configuration file, we ignore fails
.  "${2}" 2>/dev/null


case ${1} in
    info)
	echo "Info(ing) ${PROVIDES}"
	for par in KOBMDUTIL_CONF KOBMDUTIL_CONF_FULL KOBMDUTIL_PANDOC_BIN KOBMDUTIL_PHP_BIN KOBMDUTIL_MD_SOURCE KOBMDUTIL_MW_NAMESPACE KOBMDUTIL_MW_CATEGORIES KOBMDUTIL_MW_PATH  KOBMDUTIL_MW_TARGET KOBMDUTIL_MW_HEAD KOBMDUTIL_MW_FOOT; do
	    kob_show ${par}
	done

	true
	;;

    remove)
	echo "Remov(ing) ${PROVIDES}"
	echo "select page_title  from page where page_title like '${KOBMDUTIL_MW_NAMESPACE}:%';" | ${KOBMDUTIL_PHP_BIN} ${KOBMDUTIL_MW_PATH}/maintenance/sql.php 2>/dev/null| grep "\[page_title\]" | sed s/".*=> "//g > ${KOBMDUTIL_MW_TARGET}/pages.txt
	${KOBMDUTIL_PHP_BIN} ${KOBMDUTIL_MW_PATH}/maintenance/deleteBatch.php  ${KOBMDUTIL_MW_TARGET}/pages.txt
	;;
    
    conf-get)
	getConf
	;;

    head-mwt)
	# not nice if no head, but we don't show an error
	cat ${KOBMDUTIL_MW_HEAD} 2>/dev/null # || echo "<noinclude>no KOBMDUTIL_MW_HEAD definiend</noinclude>" 
	;;

    foot-mwt)
	cat ${KOBMDUTIL_MW_FOOT} 2>/dev/null || echo "[[Category:${KOBMDUTIL_MW_NAMESPACE}]]"
	;;
    
    create-mw-files)
	kob_status "Create mediawiki-files"
	cd ${KOBMDUTIL_MD_SOURCE} || kob_status "" "ERROR could not change to ${KOBMDUTIL_MD_SOURCE} "
	mkdir ${KOBMDUTIL_MW_TARGET} 2>/dev/null
	for i in $(ls -1 *.md|sed s/"\.md$"//g); do
	    echo -n "copy "${i}" ";
	    ${KOBMDUTIL_PANDOC_BIN} -t mediawiki $i.md -o ${KOBMDUTIL_MW_TARGET}/${i}.$$.mw;
	    ${0} head-mwt ${KOBMDUTIL_CONF_FULL} > ${KOBMDUTIL_MW_TARGET}/${i}.mw
	    cat ${KOBMDUTIL_MW_TARGET}/$i.$$.mw >> ${KOBMDUTIL_MW_TARGET}/${i}.mw
	    ${0} foot-mwt ${KOBMDUTIL_CONF_FULL} >> ${KOBMDUTIL_MW_TARGET}/${i}.mw
	    rm ${KOBMDUTIL_MW_TARGET}/${i}.$$.mw
	    kob_status "OK" "ERROR"
	done
	kob_status "finished create mediawiki-files"
	;;

    fix-mw-files)
	kob_status "Fixing created mediawiki files"
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
	kob_status "finished"
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
	kob_status "Importing files to mediawiki via edit.php"
	cd ${KOBMDUTIL_MW_TARGET}
	for i in $(ls -1 *mw| sed s/".mw$"//g); do
	    echo -n $i" ";
	    cat $i.mw | ${KOBMDUTIL_PHP_BIN} ${KOBMDUTIL_MW_PATH}/maintenance/edit.php ${KOBMDUTIL_MW_NAMESPACE}":"$i;
	done;
	kob_status "finished importing"
	;;

    help)
	echo "Help(ing) for $0"
	echo "help - this help output"
	echo "info - info about all variables and paths"
	echo "check - check everything is fine to run the script"
	echo "get-conf - gives the conf file"
	echo "head-mwt - get the head template for mediawiki"
	echo "foot-mwt - get the foot template for mediawiki"
	echo "create-mw-files - creates the mediawiki files from the markup files"
	echo "fix-mw-files - fix the mediawiki files, like links, name ending md"
	echo "import-mw-files - import the mw files to mediawiki"
	echo "create-fix-mw-files - do create-mw-files then fix-mw-files"
	echo "create-fix-import-mw-files - do create-fix-mw-files then import-mw-files"
	echo "remove - remove wiki pages under the namespace"
	;;
    example)
	echo "Example"
	;;
    check)
	echo "Check(ing)"

	echo -n "Test temp. mediawiki page target dir: "
	test -d ${KOBMDUTIL_MW_TARGET}
	kob_status "OK directory '${KOBMDUTIL_MW_TARGET}' exist" "Error directory '${KOBMDUTIL_MW_TARGET}' not exist"

	echo -n "Test mediawiki dir: "
	test -w ${KOBMDUTIL_MW_PATH}
	kob_status "OK directory '${KOBMDUTIL_MW_PATH}' writeable" "Error directory '${KOBMDUTIL_MW_TARGET}' not writeable"

	echo -n "Test php exist: "
	test -x ${KOBMDUTIL_PHP_BIN}
	kob_status "OK php '${KOBMDUTIL_PHP_BIN}' is executable" "Error no php available"

	echo -n "Test mediawiki/maintenance/sql.php:"
	echo "show tables;"| ${KOBMDUTIL_PHP_BIN} ${KOBMDUTIL_MW_PATH}/maintenance/sql.php >/dev/null 2>/dev/null
	kob_status "OK mediawiki sql.php" "Error"

	echo -n "Test pandoc: "
	test -x ${KOBMDUTIL_PANDOC_BIN}
        kob_status "OK pandoc '${KOBMDUTIL_PANDOC_BIN}' is executable" "Error no pandoc available or not executable"
	;;
    *)
	echo "Usage: "${0}" [help|info|check|conf-get|example|create-mw-files|fix-mw-files|import-mw-files|create-fix-mw-files|create-fix-import-mw-files|head-mwt|foot-mwt] [--conf=CONF-FILE] [--mw-path=PathToMediawiki]"
	;;
esac
