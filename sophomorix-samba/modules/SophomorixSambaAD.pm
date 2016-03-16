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
            get_forbidden_logins
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




sub  get_forbidden_logins{
    my %forbidden_logins = %DevelConf::forbidden_logins;
 
  #my $dbh=&db_connect();

   # # users in db
   # my $sth= $dbh->prepare( "SELECT uid FROM userdata" );
   # $sth->execute();
   # my $array_ref = $sth->fetchall_arrayref();
   # foreach my $row (@$array_ref){
   #    my ($login) = @$row;
   #    $forbidden_logins{$login}="login in db";

   # }

   # users in /etc/passwd
    if (-e "/etc/passwd"){
        open(PASS, "/etc/passwd");
        while(<PASS>) {
            my ($login)=split(/:/);
            $forbidden_logins{$login}="login in /etc/passwd";
        }
        close(PASS);
    }

    # future groups in schueler.txt
    my $schueler_file=$DevelConf::path_conf_user."/schueler.txt";
    if (-e "$schueler_file"){
        open(STUDENTS, "$schueler_file");
        while(<STUDENTS>) {
            my ($group)=split(/;/);
            chomp($group);
            if ($group ne ""){
                $forbidden_logins{$group}="future group in schueler.txt";
   	    }
         }
         close(STUDENTS);
    }

   # # groups in db
   # my $sth2= $dbh->prepare( "SELECT gid FROM classdata" );
   # $sth2->execute();
   # my $array_ref_2 = $sth2->fetchall_arrayref();

   # foreach my $row (@$array_ref_2){
   #    my ($group) = @$row;
   #    $forbidden_logins{$group}="unix group in db";

   # }

   # # project longnames in db
   # my $sth3= $dbh->prepare( "SELECT longname FROM projectdata" );
   # $sth3->execute();
   # my $array_ref_3 = $sth3->fetchall_arrayref();

   # foreach my $row (@$array_ref_3){
   #    my ($longname) = @$row;
   #    $forbidden_logins{$longname}="project longname in db";

   # }

   # groups in /etc/group
    if (-e "/etc/group"){
        open(GROUP, "/etc/group");
        while(<GROUP>) {
            my ($group)=split(/:/);
            $forbidden_logins{$group}="group in /etc/group";
        }
        close(GROUP);
    }

   # &db_disconnect($dbh);
   # output forbidden logins:
   if($Conf::log_level>=3){
       print("Login-Name:                    ",
             "                                   Status:\n");
       print("================================",
             "===========================================\n");
       while (($k,$v) = each %forbidden_logins){
           printf "%-60s %3s\n","$k","$v";
       }
   }

   return %forbidden_logins;
}







# END OF FILE
# Return true=1
1;
