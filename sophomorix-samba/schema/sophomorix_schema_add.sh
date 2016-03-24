#!/bin/bash
#
# Prepare and apply Sophomorix AD schema extensions to Samba 4 AD
#
# Copyright (C) Björn Baumbach <bb@sernet.de> 2012-2013
# Copyright (C) Ralph Böhme <slow@samba.org>  2016
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

SCHEMA_FILES="$(ls -x *.ldif)"

echo "Applying schema files: $SCHEMA_FILES"

print_usage()
{
	echo "Usage:"
	echo "  $0 <domain dn> <path to sophomorix ldf directory> <options>"
	echo "		-H <url>                     Database URL"
	echo "		-U <username>%<password>     Set the network username"
	echo "		-v			     verbose"
	echo "		-writechanges		     without this option we"
	echo "					     do not make any changes"
	echo "					     on the database"
	echo "		-dontclean		     do not cleanup temporary"
	echo "					     files"
	echo ""
	echo "Examples:"
	echo "  $0 DC=SAMDOM,DC=EXAMPLE,DC=PRIVATE \\
		./ \\
		-v \\
		-H /usr/local/samba/private/sam.ldb"
	echo "  $0 DC=samdom2,DC=example,DC=private \\
		/home/jesus/myZarafaLDF_Files \\
		-H ldap://mydc.samdom2.example.private \\
		-U Administrator%sTR0ngPassWD \\
		-writechanges"
}

verbose()
{
	test "x$verbose" = "x0" && {
		return 0
	}

	return 1
}

dontclean()
{
	test "x$dontclean" = "x0" && {
		return 0
	}

	return 1
}


domaindn="$1" # e.g. DC=S4DOM,DC=TESTDOM,DC=PRIVATE
test "x$domaindn" = "x" && {
        echo "Error: Please select domain dn"
	print_usage
        exit 1
}

readlink="$(which readlink)"
test "x$readlink" = "x" && {
	echo "Error: Can not find readlink"
	exit 1
}

ldf_dir="$(readlink -e $2)"
test "x$ldf_dir" = "x" && {
	echo "Error: Please select a ldf directory"
	print_usage
	exit 1
}

test -d "$ldf_dir" || {
	echo "Error: $ldf_dir is not a directory"
	print_usage
	exit 1
}

ldbmodify="$(which ldbmodify)"
test "x$ldbmodify" = "x" && {
	echo "Error: Can not find ldbmodify"
	echo "       Please check your PATH variable"
	exit 1
}
ldbmodsuff=$($ldbmodify --help | grep -- --option | grep smb.conf)
test -z "$ldbmodsuff" && {
	echo "Error: installed version ldbmodify is not supported"
	exit 1
}

ldbsearch="$(which ldbsearch)"
test "x$ldbsearch" = "x" && {
	echo "Error: Can not find ldbsearch" >&2
	echo "       Please check your PATH variable" >&2
	exit 1
}

writechanges="no"
writecount=0
verbose=1
dontclean=1
argno=1
for arg in "$@" ; do
	case $arg in
	"-U")
		userpass="-U `eval echo '$'$[$argno+1]`"
		;;
	"-H")
		url="-H `eval echo '$'$[$argno+1]`"
		;;
	"-writechanges")
		writechanges="yes"
		;;
	"-v")
		verbose=0
		;;
	"-dontclean")
		dontclean=0
		;;
	"-h")
		print_usage
		exit 0
		;;
	*)
		;;
	esac
	argno=$[$argno + 1]
done

#
# Replace and add some information (see description)
#
for file in $SCHEMA_FILES ; do
    cat "$file" | sed -e "s/<SchemaContainerDN>/CN=Schema,CN=Configuration,${domaindn}/" > "$file.sed"

    verbose && echo "Writing $file changes to $url ..."
    test "x$writechanges" = "xyes" && {
	cat "$file.sed" | $ldbmodify $url $userpass --option="dsdb:schema update allowed=yes"
	test "x$?" = "x0" || {
	    echo "Error: ldbmodify reported an error"
	    exit 1
	}
    }
    writecount=$[$writecount + 1]
    dontclean || rm -f "$ldf_file.sed"
done

echo -e "\nApplied $writecount LDIF change files to $url"
