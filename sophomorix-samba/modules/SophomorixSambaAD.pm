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
use Unicode::Map8;
use Unicode::String qw(utf16);
use Net::LDAP;

@ISA = qw(Exporter);

@EXPORT_OK = qw( );
@EXPORT = qw(
            AD_bind_admin
            AD_unbind_admin
            AD_user_create
            get_forbidden_logins
            );


sub AD_get_passwd {
    my $smb_pwd="";
    my $smb_rootdn="DC=linuxmuster,DC=local";
    if (-e $DevelConf::file_samba_pwd) {
        open (SECRET, $DevelConf::file_samba_pwd);
        while(<SECRET>){
            $smb_pwd=$_;
            chomp($smb_pwd);
        }
        close(SECRET);
    } else {
        print "Password of samba Administrator must ",
               "be in $DevelConf::file_samba_pwd\n";
        exit;
    }
    return($smb_pwd,$smb_rootdn);
}


sub AD_bind_admin {
    my ($smb_pwd,$smb_rootdn)=&AD_get_passwd();
    my $admin_dn="CN=Administrator,CN=Users,".$smb_rootdn;
    # check connection to Samba4 AD
    if($Conf::log_level>=3){
        print "   Checking Samba4 AD connection ...\n";
    }
    #my $ldap = Net::LDAP->new('ldaps://localhost')  or  die "$@";
    my $ldap = Net::LDAP->new('ldaps://localhost')  or  
         &Sophomorix::SophomorixBase::log_script_exit(
                            "No connection to Samba4 AD!",
         1,1,0,@arguments);
    my $mesg = $ldap->bind($admin_dn, password => $smb_pwd);
    # show errors from bind
    $mesg->code && die $mesg->error;
    return $ldap;
}



sub AD_unbind_admin {
    my ($ldap) = @_;
    my $mesg = $ldap->unbind();
    #  show errors from unbind
    $mesg->code && die $mesg->error;
}



sub AD_user_create {
    my ($ldap,
        $user_count,
        $identifier,
        $login,
        $class_group,
        $firstname,
        $surname,
        $birthdate,
        $plain_password,
        $unid,
        $wunsch_id,
        $wunsch_gid,
#        $epoche_jetzt,
#       $time_stamp_AD,
       ) = @_;

    #calculate
    my $shell="/bin/false";
    my $display_name = $firstname." ".$surname;
    my $user_principal_name = $login."\@"."linuxmuster.local";
    my $dn = "cn=".$login.", CN=Users, DC=linuxmuster,DC=local";
    # password generation
    # build the conversion map from your local character set to Unicode    
    my $charmap = Unicode::Map8->new('latin1')  or  die;
    # surround the PW with double quotes and convert it to UTF-16
    my $uni_password = $charmap->tou('"'.$plain_password.'"')->byteswap()->utf16();

    if($Conf::log_level>=1){
        print "\n";
        &Sophomorix::SophomorixBase::print_title("Creating User $user_count :");
        print("Surname:            $surname\n");
        print("Firstname:          $firstname\n");
        print("Birthday:           $birthdate\n");
        print("Identifier:         $identifier\n");
        print("AdminClass:         $class_group\n"); # lehrer oder klasse
        print("Unix-gid:           $wunsch_gid\n"); # lehrer oder klasse
        #print("GECOS:              $gecos\n");
        #print("Login (to check):   $login_name_to_check\n");
        print("Login (check OK):   $login\n");
        print("Password:           $plain_password\n");
        print("Unid:               $unid\n");
        print("Unix-id:            $wunsch_id\n");
        if ($class_group eq ${DevelConf::teacher}) {
            # Es ist ein Lehrer
            print("Shell (teachers):   $shell\n"); 
        } else {
            # Es ist ein Schüler
            print("Shell (students):   $shell\n"); 
        }
    }
    my $result = $ldap->add( $dn,
                   attr => [
                   'sAMAccountName' => $login,
                   'givenName'   => $firstname,
                   'sn'   => $surname,
                   'displayName'   => [$display_name],
                   'userPrincipalName' => $user_principal_name,
                   'unicodePwd' => $uni_password, 
                   'userAccountControl' => '512',
                   'objectclass' => ['top', 'person',
                                     'organizationalPerson',
                                     'user' ],
                           ]
                           );
    $result->code && warn "failed to add entry: ", $result->error ;
}



sub  get_forbidden_logins{
    my ($ldap) = @_;
    my %forbidden_logins = %DevelConf::forbidden_logins;
 
    # users from ldap
    $mesg = $ldap->search( # perform a search
                   base   => "CN=Users,DC=linuxmuster,DC=local",
                   scope => 'sub',
                   filter => '(objectClass=user)',
                   attr => ['sAMAccountName']
                         );
    my $max_user = $mesg->count; 
    for( my $index = 0 ; $index < $max_user ; $index++) {
        my $entry = $mesg->entry($index);
        my @values = $entry->get_value( 'sAMAccountName' );
        foreach my $login (@values){
            $forbidden_logins{$login}="login in AD";
        }
    }

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

    # groups from ldap
    $mesg = $ldap->search( # perform a search
                   base   => "CN=Users,DC=linuxmuster,DC=local",
                   scope => 'sub',
                   filter => '(objectClass=group)',
                   attr => ['sAMAccountName']
                         );
    my $max_group = $mesg->count; 
    for( my $index = 0 ; $index < $max_group ; $index++) {
        my $entry = $mesg->entry($index);
        my @values = $entry->get_value( 'sAMAccountName' );
        foreach my $group (@values){
            $forbidden_logins{$group}="group in AD";
        }
    }

    # groups in /etc/group
    if (-e "/etc/group"){
        open(GROUP, "/etc/group");
        while(<GROUP>) {
            my ($group)=split(/:/);
            $forbidden_logins{$group}="group in /etc/group";
        }
        close(GROUP);
    }

    # output forbidden logins:
    if($Conf::log_level>=3){
        print("Login-Name:                    ",
              "                                   Status:\n");
        print("================================",
              "===========================================\n");
        while (($k,$v) = each %forbidden_logins){
            printf "%-50s %3s\n","$k","$v";
        }
    }
    return %forbidden_logins;
}







# END OF FILE
# Return true=1
1;
