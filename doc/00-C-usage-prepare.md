# Usage and prepare
[back](00-A-documentation.md)
Before you start answer the following questions:

* Where is the location of the markdown files you want to import to mediawiki?
* Which prefix 'namespace' should have all the markdown documentation in the mediawiki?
This is required, otherwise you can't remove the content automaticly from the mediawiki.

# kob-mdutil-mediawiki.sh
The command 'kob-mdutil-mediawiki.sh' has as the first option the command. The second one give the configuration file to use.

## help
The command 'kob-mdutil-mediawiki.sh' has the option 'help'
```
 kob-mdutil-mediawiki.sh help
```
that show you the possible commands:
```
Help(ing) for /kob/mon/bin/kob-mdutil-mediawiki.sh
help - this help output
info - info about all variables and paths
check - check everything is fine to run the script
get-conf - gives the conf file
head-mwt - get the head template for mediawiki
foot-mwt - get the foot template for mediawiki
create-mw-files - creates the mediawiki files from the markup files
fix-mw-files - fix the mediawiki files, like links, name ending md
import-mw-files - import the mw files into mediawiki
create-fix-mw-files - do the commandc 'create-mw-files' then 'fix-mw-files'
create-fix-import-mw-files - do 'create-fix-mw-files' then 'import-mw-files'
remove - remove all wiki pages under the namespace
```
## info
The command option 'info' show you some informations about the variables and paths.

## check 
This options checks if 
* Temp path exist and is writeable
* Path to mediawiki is set
* PHP exist and is executeable
* Can call the mediawiki sql interface from commandline
* pandoc exist and is executeable. This programm make the real hard work.

## get-conf
Give the configuration. This is a good startpoint when defining a new configuration file.

## head-mwt
Give a mediawiki snippet that is insert on the top of every page.

## foot-mwt
Give a mediawiki snippet that is insert on the bottom of every page. This is usually the category of the files. Default put all pages into the category MD-IMPORT.

## create-mw-files
Creates all the mediawiki files in the definied temp directory. This add the head-mwt and the foot-mwt on every page.

## fix-mw-files
Fixes the created mediawiki files. These are links and remove the suffix '.md' from the links to the files.

## import-mw-files
Imports the created mediawiki files into mediawiki

## create-fix-mw-files
Run the command create-mw-files and then fix-mw-files. This is simply a helper for a combination of all the commands.

## create-fix-import-mw-files
Run the command create-fix-mw-files and then import-mw-files. This is simply a helper for the combination create-mw-files, fix-mw-files and import-mw-files.

## remove
Remove all pages from the defined namespace. Be carefull that you allways have a separate namespace in the mediawiki. This command will remove all pages from this.
