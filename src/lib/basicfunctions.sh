#!/bin/bash
#===============================================================================
#
#          FILE: basicfunctions.sh
# 
#   DESCRIPTION: yaourt's basic functions
# 
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR:   Julien MISCHKOWITZ (wain@archlinux.fr) 
#       VERSION:  1.0
#===============================================================================


# set misc path
initpath(){
	PACMANROOT=`LC_ALL=C pacman --verbose | grep 'DB Path' | awk '{print $4}'| sed "s/\/$//"`
	LOCKFILE="$PACMANROOT/db.lck"
	mkdir -p "$YAOURTTMPDIR"
}

# Load library but never reload twice the same lib
loadlibrary(){
	eval alreadyload=\$$1
	[ ! -z "$alreadyload" ] && return 0
	if [ ! -f "/usr/lib/yaourt/$1.sh" ]; then
		error "$1.sh file is missing"
		die 1
	fi
	source "/usr/lib/yaourt/$1.sh" || warning "problem in $1.sh library"
	eval $1=1
}

# ask 
userinput() 
{ 
	[ -z $1 ] && _key="YN" || _key=$1
	read -en $NOENTER
	echo $REPLY | tr '[[:lower:]]' '[[:upper:]]'  | tr "$(eval_gettext $_key)" "$_key"
}

_translate_me()
{
	# Used to detect string with poedit
	eval_gettext "YN"  # Yes, No
	eval_gettext "YAN" # Yes, All, No
	eval_gettext "YNA" # Yes, No, Abort
	eval_gettext "YNVC" # Yes, No, View package, Check package with namcap
	eval_gettext "YNVM" # Yes, No, View more infos, Manualy select packages
}

yes_no ()
{
	case $1 in
	  1) 
		  echo $(eval_gettext "[Y/n]")
			;;
	  2)
		  echo $(eval_gettext "[y/N]")
			;;
	  *)
		  echo $(eval_gettext "[y/n]")
			;;
	esac
}
		  
isnumeric(){
	if let $1 2>/dev/null; then return 0; else return 1; fi
}

is_x_gt_y(){
	[ $(vercmp "$1" "$2" 2> /dev/null) -gt 0 ]
}

readconfigfile(){
# defautconfig
EDITPKGBUILD=1
DEVEL=0
EXPORTDIR=""
EXPORT=0
TERMINALTITLE=1
NOCONFIRM=0
FORCE=0
AURCOMMENT=1
AURUPGRADE=0
AURVOTE=1
AURSEARCH=1
AUTOSAVEBACKUPFILE=0
MAXCOMMENTS=5
NOENTER=1
ORDERBY="asc"
PACMANBIN="/usr/bin/pacman"
INENGLISH=""
sfmirror=""

while [ "$#" -ne "0" ]; do
	lowcasearg=`echo $2 | tr A-Z a-z`
	case $lowcasearg in
		yes) value=1
		;;
		no) value=0
		;;
		*)value=-1
		;;
	esac

	case "`echo $1 | tr A-Z a-z`" in
		noconfirm)
			if [ $value -gt -1 ]; then
				NOCONFIRM=$value; shift
				[ $NOCONFIRM -eq 1 ] && EDITPKGBUILD=0
			fi
			;;
		alwaysforce)
			if [ $value -gt -1 ]; then
				FORCE=$value; shift
			fi
	  		;;	
		autosavebackupfile)
			if [ $value -gt -1 ]; then
				AUTOSAVEBACKUPFILE=$value; shift
			fi
	  		;;	
		forceenglish)
			if [ $value -gt -1 ]; then
				shift
				if [ $value -eq 1 ]; then
					INENGLISH="LC_ALL=C"
				fi
			fi
	  		;;	
		editpkgbuild)
			if [ $value -gt -1 ]; then
				EDITPKGBUILD=$value; shift
			fi
	  		;;	
		showaurcomment)
			if [ $value -gt -1 ]; then
				AURCOMMENT=$value; shift
			fi
	  		;;	
		alwaysupgradedevel)
			if [ $value -gt -1 ]; then
				DEVEL=$value; shift
			fi
	  		;;	
		dontneedtopressenter)
			if [ $value -gt -1 ]; then
				NOENTER=$value; shift
			fi
	  		;;	
		alwaysupgradeaur)
			if [ $value -gt -1 ]; then
				AURUPGRADE=$value; shift
			fi
	  		;;	
		aurvotesupport)
			if [ $value -gt -1 ]; then
				AURVOTE=$value; shift
			fi
	  		;;	
		searchinaurunsupported)
			if [ $value -gt -1 ]; then
				AURSEARCH=$value; shift
			fi
	  		;;	
		updateterminaltitle)
			if [ $value -gt -1 ]; then
				TERMINALTITLE=$value; shift
			fi
	  		;;	
		exporttolocalrepository)
			if [ -d "$2" ]; then
				EXPORT=1; EXPORTDIR="$2"; shift
			else
				error "ExportToLocalRepository is not a directory"
			fi
	  		;;	
		tmpdirectory)
			if [ -d "$2" ]; then
				cd "$2"
				YAOURTTMPDIR="`pwd`/yaourt-tmp-`id -un`"
				cd - 1>/dev/null; shift
			else
				error "TmpDirectory is not a directory"
			fi
	  		;;	
		sourceforgemirror)
				sfmirror="$2"; shift
				;;
		lastcommentsnumber)
			if `isnumeric $2`; then
			       MAXCOMMENTS=$2; shift
		        else
				error "Wrong value for LastCommentsNumber"
		        fi
			;;	       
		lastcommentsorder)
			if [ "$lowcasearg" = "asc" -o "$lowcasearg" = "desc" ]; then
			       ORDERBY=$lowcasearg; shift
			else
				error "Wrong value for LastCommentsOrder"
		        fi
			;;	       
		pkgbuildeditor)
			if [ `type -p "$2"` ]; then
				EDITOR="$2"; shift
			else
				error "PkgbuildEditor not found"
			fi
	  		;;	
		pacmanbin)
			if [ -f "$2" ]; then
				PACMANBIN="$2"; shift
			else
				error "PACMANBIN: $2 is incorrect"
			fi
			;;
		colormod)
			case $lowcasearg in
				lightbackground)
					COLORMODE="--lightbg"; shift
				;;
				nocolor)
					COLORMODE="--nocolor"; shift
				;;
				textonly)
					COLORMODE="--textonly"; shift
				;;
				normal)	shift ;;
			esac
			;;
		*)
		echo "$1 "$(eval_gettext "no recognized in config file")
		sleep 4
		;;
	esac
	shift
done

PACMANBIN="$INENGLISH $PACMANBIN"
	
}


urlencode(){
echo $@ | LANG=C awk '
    BEGIN {
        split ("1 2 3 4 5 6 7 8 9 A B C D E F", hextab, " ")
        hextab [0] = 0
        for ( i=1; i<=255; ++i ) ord [ sprintf ("%c", i) "" ] = i + 0
    }
    {
        encoded = ""
        for ( i=1; i<=length ($0); ++i ) {
            c = substr ($0, i, 1)
            if ( c ~ /[a-zA-Z0-9.-]/ ) {
                encoded = encoded c             # safe character
            } else if ( c == " " ) {
                encoded = encoded "+"   # special handling
            } else {
                # unsafe character, encode it as a two-digit hex-number
                lo = ord [c] % 16
                hi = int (ord [c] / 16);
                encoded = encoded "%" hextab [hi] hextab [lo]
            }
        }
            print encoded
    }
    END {
    }
'
}




###################################
### MAIN OF INIT PROGRAM        ###
###################################

YAOURTTMPDIR="/tmp/yaourt-tmp-$(id -un)"
if [ -f ~/.yaourtrc ]; then
	configfile="$HOME/.yaourtrc"
else
	configfile="/etc/yaourtrc"
fi

loadlibrary color
readconfigfile `grep "^\s*[a-zA-Z]" $configfile`
#initcolor
initpath
