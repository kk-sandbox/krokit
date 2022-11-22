#!/bin/bash

PKGNAME=Krokit
PKGVERSION=1.0-c

VERBOSE=0
GROKPKGFILE=X
TOMCAT=tomcat9
GROKROOT=/opengrok
CTAGSPKGNAME=ctags-universal
CTAGS=/usr/bin/$CTAGSPKGNAME
TOMCATAPPDIR=/var/lib/$TOMCAT/webapps
HOST_URL=http://localhost:8080/source

GROK_ETC=$GROKROOT/etc
GROK_SRC=$GROKROOT/src
GROK_DATA=$GROKROOT/data
GROK_DIST=$GROKROOT/dist
LOGCONFIG=$GROK_ETC/logging.properties

#------------------------------------------
# Krokit utility functions
#------------------------------------------

print_usage() {
	cat <<-USAGE
	Usage: krokit [options]... /path/to/project/source
	Krokit makes it easy to setup OpenGrok source code search engine.

	Options:
	    -a  --add    <project-path>     -- Generate index and add project to Opengrok
	    -d  --deploy <opengrok-package> -- Deploy Opengrok webapp to explore source code
	    -D  --delete <project-name>     -- Delete project from Opengrok indexing
	    -i  --init                      -- Initial setup to download and install dependencies
	    -l  --list                      -- List deployed projects in Opengrok
	    -r  --refresh                   -- Refresh Opengrok indexer
	    -V  --verbose                   -- Enable verbose mode
	    -v  --version                   -- Print package version
	    -h  --help                      -- Show this help menu

	Demo:
	    $ krokit --init                           # Initialize setup
	    $ krokit --deploy opengrok-1.5.12.tar.gz  # Deploy Opengrok package
	    $ krokit --add    <project-path>          # Added project to the webapp
	    $ krokit --list                           # List projects deployed in webapp
	    $ krokit --delete <project-name>          # Delete project from the webapp
	    $ krokit --refresh                        # Refresh Opengrok index

	  Visit $HOST_URL to explore the OpenGrok dashboard
	USAGE

	exit 1
}

print_version() {
	echo "$PKGNAME: Version $PKGVERSION - Tool to setup Opengrok"
	echo "Configured to deploy OpenGrok <= 1.5.12 with $TOMCAT servelet."
	exit 0
}

print_debug() {
	if [ $VERBOSE -eq 1 ]; then
		echo -e "$@"
	fi
}

#------------------------------------------
# Krokit core functions
#------------------------------------------

krokit_validate_deployment() {
	if [ ! -d $GROKROOT ]; then
		echo -e "\n$PKGNAME is not yet deployed !!!"
		echo -e "Run 'krokit --deploy' and try again.\n"
		exit 1
	fi

	if [ ! -d $TOMCATAPPDIR/source ]; then
		echo -e "\n$PKGNAME is not yet deployed !!!"
		echo -e "Run 'krokit --deploy' and try again.\n"
		exit 1
	fi
}

krokit_validate_groktools() {
	RETVAL=0
	PKGS=( opengrok-deploy opengrok-indexer )

	for PKG in "${PKGS[@]}"
	do
		type $PKG > /dev/null 2>&1
		if [ $? -ne 0 ]; then
			echo -e "\n$PKGNAME: '$PKG' is not installed !!!\n"
			exit 1
		fi
	done

	return $RETVAL
}

krokit_validate_setup() {
	RETVAL=0
	PKGS=( ctags-universal java )

	for PKG in "${PKGS[@]}"
	do
		type $PKG > /dev/null 2>&1
		if [ $? -ne 0 ]; then
			echo -e "\n$PKGNAME: '$PKG' is not installed !!!\n"
			RETVAL=1
		fi
	done

	return $RETVAL
}

krokit_setup_opengrok() {
	echo "$PKGNAME: Setting up OpenGrok ..."

	sudo apt update
	sudo apt install -y universal-ctags \
	                    python3-pip \
	                    $TOMCAT # Tomcat automatically install requied JAVA libraries
}

krokit_generate_index() {
	echo "$PKGNAME: Generating index ..."
	krokit_validate_setup
	krokit_validate_groktools
	krokit_validate_deployment

	sudo opengrok-indexer -J=-Djava.util.logging.config.file=$LOGCONFIG \
	                      -a $GROK_DIST/lib/opengrok.jar -- \
	                      -c $CTAGS \
	                      -s $GROK_SRC \
	                      -d $GROK_DATA \
	                      -W $GROK_ETC/configuration.xml \
	                      -U $HOST_URL -H -P -S -G \
	                      -i '*.out' -i '*.swo' -i '*.swp' \
	                      -i '*.a' -i '*.d' -i '*.o' -i '*.so' -i '*.so.*' \
	                      -i d:__ktags -i d:obj -i d:dist -i d:sandbox -i d:codereview -i d:'*-build'

	if [ $? -ne 0 ]; then
		echo -e "\n$PKGNAME: failed to deploy OpenGrok !!!\n"
		exit 1
	fi

	return $?
}

krokit_add_project() {
	if [ $# -lt 1 ]; then
		echo -e "\n$PKGNAME: missing file operand (project-name) !!!\n"
		exit 1
	elif [ $# -gt 1 ]; then
		echo "$PKGNAME:  too many arguments !!!"
		exit 1
	fi

	PROJECT=$1

	krokit_validate_setup
	krokit_validate_deployment

	if [ ! -d $PROJECT ]; then
		echo -e "$PKGNAME: '$PROJECT' file does'nt exist !!!"
		exit 1
	fi

	echo "$PKGNAME: Adding project '$PROJECT' ..."
	sudo cp -rf $PROJECT $GROK_SRC
	if [ $? -ne 0 ]; then
		echo -e "\n$PKGNAME: failed to add '$PROJECT' !!!\n"
	fi

	krokit_generate_index

	return $?
}


krokit_remove_file() {
	FILE=$1
	echo "    Removing ... '$FILE'"
	sudo rm -rf $FILE
	if [ $? -ne 0 ]; then
		echo -e "\n$PKGNAME: failed to delete '$FILE' !!!\n"
		return 1
	fi

	return 0
}

krokit_delete_project() {
	if [ $# -lt 1 ]; then
		echo -e "\n$PKGNAME: missing file operand (project-name) !!!\n"
		exit 1
	elif [ $# -gt 1 ]; then
		echo "$PKGNAME:  too many arguments !!!"
		exit 1
	fi

	PROJECT=$1

	krokit_validate_setup

	if [ ! -d "$GROK_SRC/$PROJECT" ]; then
		echo "$PKGNAME: '$PROJECT' not found !!!"
		exit 1
	fi

	echo "$PKGNAME: Deleting project '$PROJECT' ..."

	GROK_FILES=( $GROK_SRC/$PROJECT $GROK_DATA/xref/$PROJECT $GROK_DATA/index/$PROJECT $GROK_DATA/historycache/$PROJECT )
	for GROK_FILE in "${GROK_FILES[@]}"
	do
		krokit_remove_file $GROK_FILE
	done

	krokit_generate_index

	return $?
}

krokit_list_projects() {
	echo "$PKGNAME: listing projects deployed at '$GROK_SRC'"
	for ENTRY in $(ls -A "$GROK_SRC")
	do
		if [ -d $GROK_SRC/$ENTRY ]; then
			echo "	$ENTRY"
		else
			echo "	FILE: $ENTRY"
		fi
	done
}

krokit_deploy_opengrok() {
	if [ $# -lt 1 ]; then
		echo -e "\n$PKGNAME: missing file operand (opengrok-package) !!!"
		echo -e "  Get the package from 'https://github.com/oracle/opengrok/releases/download/1.5.12/opengrok-1.5.12.tar.gz'\n"
		exit 1
	elif [ $# -gt 1 ]; then
		echo "$PKGNAME:  too many arguments !!!"
		exit 1
	fi

	GROKPKGFILE=$1
	GROKPKGNAME=$(basename $GROKPKGFILE)

	if [ ! -f $GROKPKGFILE ]; then
		echo -e "\n$PKGNAME: '$GROKPKGFILE' file doesn't exist !!!\n"
		exit 1
	fi

	krokit_validate_setup

	echo "$PKGNAME: Deploying OpenGrok ..."
	sudo mkdir -p $GROKROOT/{src,data,dist,etc,log}
	if [ $? -ne 0 ]; then
		echo -e "\n$PKGNAME: failed to create directories !!!\n"
		exit 1
	fi

	sudo tar -C $GROK_DIST --strip-components=1 -xzf $GROKPKGFILE
	if [ $? -ne 0 ]; then
		echo -e "\n$PKGNAME: failed to extract '$GROKPKGNAME' to '$GROK_DIST' !!!\n"
		exit 1
	fi

	cat <<-GROKLOGCONFIG > /tmp/opengrok-logger.cfg
	handlers= java.util.logging.FileHandler, java.util.logging.ConsoleHandler

	java.util.logging.FileHandler.pattern = /opengrok/log/opengrok%g.%u.log
	java.util.logging.FileHandler.append = false
	java.util.logging.FileHandler.limit = 0
	java.util.logging.FileHandler.count = 30
	java.util.logging.FileHandler.level = ALL
	java.util.logging.FileHandler.formatter = org.opengrok.indexer.logger.formatter.SimpleFileLogFormatter

	java.util.logging.ConsoleHandler.level = INFO
	java.util.logging.ConsoleHandler.formatter = org.opengrok.indexer.logger.formatter.SimpleFileLogFormatter

	org.opengrok.level = FINE
	GROKLOGCONFIG
	sudo mv /tmp/opengrok-logger.cfg $LOGCONFIG
	if [ $? -ne 0 ]; then
		echo -e "\n$PKGNAME: failed to copy '$LOGCONFIG' to '$GROK_ETC' !!!\n"
		exit 1
	fi

	cd $GROK_DIST/tools
	sudo pip3 install opengrok-tools.tar.gz
	if [ $? -ne 0 ]; then
		echo -e "\n$PKGNAME: failed to install Opengrok tools !!!\n"
		exit 1
	fi

	krokit_validate_groktools
	sudo opengrok-deploy  -c $GROKROOT/etc/configuration.xml $GROKROOT/dist/lib/source.war $TOMCATAPPDIR

	ITER=1
	while [ $ITER -le 10 ]
	do
		if [ -d $TOMCATAPPDIR/source ]; then
			break
		fi

		ITER=$(( $ITER + 1 ))
		sleep 1
	done

	if [ $ITER -eq 10 ]; then
		echo "$PKGNAME: Timeout !!! delay in extraction of '$TOMCATAPPDIR/source.war'."
	fi

	krokit_generate_index

	if [ $? -ne 0 ]; then
		echo -e "\n$PKGNAME: failed to deploy OpenGrok !!!\n"
		exit 1
	fi
}

krokit_worker() {
	case "$MODE" in
		add)
			krokit_add_project $@
			;;
		deploy)
			krokit_deploy_opengrok $@
			;;
		delete)
			krokit_delete_project $@
			;;
		list)
			krokit_list_projects
			;;
		refresh)
			krokit_generate_index
			;;
		setup)
			krokit_setup_opengrok
			;;
	esac

	return $?
}

parse_cmdline_options() {
	GETOPTS=$(getopt -o adDhilrvV --long add,deploy,delete,init,help,list,refresh,verbose,version -- "$@")
	if [ "$?" != "0" ]; then
		echo "Try 'krokit --help' for more information."
		exit 1
	fi

	eval set -- "$GETOPTS"
	while :
	do
		case "$1" in
			-a | --add)
				MODE=add
				shift
				;;
			-d | --deploy)
				MODE=deploy
				shift
				;;
			-i | --init)
				MODE=setup
				shift
				;;
			-D | --delete)
				MODE=delete
				shift
				;;
			-l | --list)
				MODE=list
				shift
				;;
			-r | --refresh)
				MODE=refresh
				shift
				;;
			-V | --verbose)
				VERBOSE=1
				shift
				;;
			-v | --version)
				print_version
				shift
				;;
			-h | --help)
				print_usage
				shift
				;;
			--) shift; break ;; # -- means the End of the arguments
			*) echo "Unexpected option: $1" # will not hit here
		esac
	done

	PROJECT=$@ # assuming remaining arguments are projecta

	if [ "$MODE" == "" ]; then
		echo "$PKGNAME: No options selected !!!"
		echo "Try 'krokit --help' for more information."
		exit 1
	fi

	return $?
}

#----------------------------------
# Main procedure starts here
#----------------------------------

krokit_main() {
	if [ $# -lt 1 ]; then
		print_usage
		exit 1
	fi

	parse_cmdline_options $@

	if [ $VERBOSE -eq 1 ]; then
		set -x
	fi

	krokit_worker $PROJECT

	return $?
}

krokit_main $@

exit 0

#EOF
