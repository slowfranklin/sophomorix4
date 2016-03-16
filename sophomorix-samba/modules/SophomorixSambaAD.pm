#!/usr/bin/perl -w
# This perl module SophomorixSambaAD is maintained by Rüdiger Beck
# It is Free Software (License GPLv3)
# If you find errors, contact the author
# jeffbeck@web.de  or  jeffbeck@linuxmuster.net

package Sophomorix::SophomorixSambaAD;
require Exporter;
#use File::Basename;
#use Time::Local;
#use Time::localtime;
#use Quota;
#use Sys::Filesystem ();


@ISA = qw(Exporter);

@EXPORT_OK = qw( );
@EXPORT = qw(
            AD_check_connection
            );



sub AD_check_connection {
    # check connection to Samba4 AD
    if($Conf::log_level>=3){
        print "   Checking Samba4 AD connection ...\n";
    }
    #my $ldap = Net::LDAP->new('ldaps://localhost')  or  die "$@";
    my $ldap = Net::LDAP->new('ldaps://localhost')  or  
         &Sophomorix::SophomorixBase::log_script_exit("No connection to Samba4 AD!",
         1,1,0,@arguments);
}




# END OF FILE
# Return true=1
1;
