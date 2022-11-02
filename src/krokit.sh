#!/bin/bash

PKGNAME=Krokit
PKGVERSION=1.0

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
LOGSETTINGS=$GROK_DIST/doc/logging.properties

#------------------------------------------
# Krokit utility functions
#------------------------------------------

print_usage() {
	cat <<-USAGE
	Usage: krokit [options]... /path/to/project/source
	Krokit makes it easy to setup OpenGrok source code search engine.

	Initialize setup with '--init' option before deploying your projects.

	Requirements: OpenGrok <= 1.5.12, OpenJRE-8 and Tomcat-9 servelet

	Options:
	    -a  --add    <project-path>     -- Generate index and add project to opengrok
	    -d  --deploy <opengrok-package> -- Deploy Opengrok before adding projects
	    -r  --delete <project-name>     -- Delete project from Opengrok indexing
	    -i  --init                      -- Initial setup to download and install dependencies
	    -V  --verbose                   -- Enable verbose mode
	    -v  --version                   -- Print Krokit version
	    -h  --help                      -- Show this help menu
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

	sudo opengrok-indexer -J=-Djava.util.logging.config.file=$LOGSETTINGS \
	                      -a $GROK_DIST/lib/opengrok.jar -- \
	                      -c $CTAGS \
	                      -s $GROK_SRC \
	                      -d $GROK_DATA \
	                      -W $GROK_ETC/configuration.xml \
	                      -U $HOST_URL -H -P -S -G

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
	sudo rm -r $GROK_SRC/$PROJECT
	if [ $? -ne 0 ]; then
		echo -e "\n$PKGNAME: failed to delete '$PROJECT' !!!\n"
	fi

	krokit_generate_index

	return $?
}

krokit_deploy_opengrok() {
	if [ $# -lt 1 ]; then
		echo -e "\n$PKGNAME: missing file operand (opengrok-package) !!!\n"
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

	sudo cp $LOGSETTINGS $GROK_ETC
	if [ $? -ne 0 ]; then
		echo -e "\n$PKGNAME: failed to copy '$LOGSETTINGS' to '$GROK_ETC' !!!\n"
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
		setup)
			krokit_setup_opengrok
			;;
	esac

	return $?
}

parse_cmdline_options() {
	GETOPTS=$(getopt -o adhirvV --long add,deploy,delete,setup,help,verbose,version -- "$@")
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
			-r | --delete)
				MODE=delete
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
