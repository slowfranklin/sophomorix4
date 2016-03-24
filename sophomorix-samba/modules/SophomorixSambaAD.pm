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
#use Sophomorix::SophomorixBase;
use Data::Dumper;
$Data::Dumper::Indent = 1;
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Useqq = 1;
$Data::Dumper::Terse = 1; 

@ISA = qw(Exporter);

@EXPORT_OK = qw( );
@EXPORT = qw(
            AD_bind_admin
            AD_unbind_admin
            AD_user_create
            AD_user_kill
            AD_group_create
            AD_group_addmembers
            AD_group_removemembers
            AD_get_group_by_token
            get_forbidden_logins
            AD_ou_add
            );

sub AD_get_passwd {
    my $smb_pwd="";
    my $smb_rootdn=&AD_get_base();
    #my $smb_rootdn="DC=linuxmuster,DC=local";
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


sub AD_user_kill {
    my ($arg_ref) = @_;
    my $ldap = $arg_ref->{ldap};
    my $login = $arg_ref->{login};
    my $identifier = $arg_ref->{identifier};

    my $count=&AD_user_test_exist($ldap,$login);
    if ($count > 0){
        my $command="samba-tool user delete ". $login;
        print "   # $command\n";
        system($command);
        return;
    } else {
        print "   * User $login nonexisting ($count results)\n";
        return;
    }
}

sub AD_user_create {
    my ($arg_ref) = @_;
    my $ldap = $arg_ref->{ldap};
    my $user_count = $arg_ref->{user_count};
    my $identifier = $arg_ref->{identifier};
    my $login = $arg_ref->{login};
    my $group = $arg_ref->{group};
    my $firstname_ascii = $arg_ref->{firstname_ascii};
    my $surname_ascii = $arg_ref->{surname_ascii};
    my $firstname_utf8 = $arg_ref->{firstname_utf8};
    my $surname_utf8 = $arg_ref->{surname_utf8};
    my $birthdate = $arg_ref->{birthdate};
    my $plain_password = $arg_ref->{plain_password};
    my $unid = $arg_ref->{unid};
    my $wunsch_id = $arg_ref->{wunsch_id};
    my $wunsch_gid = $arg_ref->{wunsch_gid};
    my $ou = $arg_ref->{ou};
    my $school_token = $arg_ref->{school_token};
    my $role = $arg_ref->{role};
    my $creationdate = $arg_ref->{creationdate};

    #calculate
    my $shell="/bin/false";
    my $display_name = $firstname_utf8." ".$surname_utf8;
    my $user_principal_name = $login."\@"."linuxmuster.local";
    # dn
    my $base=&AD_get_base();
    my $group_token=&AD_get_group_by_token($group,$school_token);
    my $container=&AD_get_container_by_role($role,$group_token);

    my $dn_class = $container."OU=".$ou.",".$base;
    my $dn = "cn=".$login.",".$container."OU=".$ou.",".$base;
 
    # password generation
    # build the conversion map from your local character set to Unicode    
    my $charmap = Unicode::Map8->new('latin1')  or  die;
    # surround the PW with double quotes and convert it to UTF-16
    my $uni_password = $charmap->tou('"'.$plain_password.'"')->byteswap()->utf16();

    if($Conf::log_level>=1){
        print "\n";
        &Sophomorix::SophomorixBase::print_title("Creating User $user_count :");
        print("DN:                 $dn\n");
        print("DN (Parent):        $dn_class\n");
        print("Surname (ASCII):    $surname_ascii\n");
        print("Surname (UTF8):     $surname_utf8\n");
        print("Firstname (ASCII):  $firstname_ascii\n");
        print("Firstname (UTF8):   $firstname_utf8\n");
        print("Birthday:           $birthdate\n");
        print("Identifier:         $identifier\n");
        print("OU:                 $ou\n"); # Organisatinal Unit
        print("School Token:       $school_token\n"); # Organisatinal Unit
        print("Role:               $role\n");
        print("AdminClass:         $group ($group_token)\n"); # lehrer oder klasse
        print("Unix-gid:           $wunsch_gid\n"); # lehrer oder klasse
        #print("GECOS:              $gecos\n");
        #print("Login (to check):   $login_name_to_check\n");
        print("Login (check OK):   $login\n");
        print("Password:           $plain_password\n");
        # sophomorix stuff


        print("Creationdate:       $creationdate\n");

        print("Unid:               $unid\n");
        print("Unix-id:            $wunsch_id\n");
    }

    $ldap->add($dn_class,attr => ['objectclass' => ['top', 'container']]);
    my $result = $ldap->add( $dn,
                   attr => [
                   'sAMAccountName' => $login,
                   'givenName'   => $firstname_utf8,
                   'sn'   => $surname_utf8,
                   'displayName'   => [$display_name],
                   'userPrincipalName' => $user_principal_name,
                   'unicodePwd' => $uni_password,
                   'sophomorixExitAdminClass' => "unknown", 
                   'sophomorixUnid' => $unid,
                   'sophomorixStatus' => "U",
                   'sophomorixAdminClass' => $group_token,    
                   'sophomorixFirstPassword' => $plain_password, 
                   'sophomorixFirstnameASCII' => $firstname_ascii,
                   'sophomorixSurnameASCII'  => $surname_ascii,
    #               'sophomorixCreationDate' => $creationdate, 
                   'userAccountControl' => '512',
                   'objectclass' => ['top', 'person',
                                     'organizationalPerson',
                                     'user' ],
                           ]
                           );
    $result->code && warn "failed to add entry: ", $result->error ;
}


sub AD_get_base {
    # ?????
    return "DC=linuxmuster,DC=local";
}


sub AD_get_group_by_token {
    my ($group,$school_token) = @_;
    my $groupname="";
    if ($school_token eq "---" or $school_token eq ""){
        $groupname=$group;
    } else {
        $groupname=$school_token."-".$group;
    }
    return $groupname;
}


sub AD_get_container_by_role {
    # returns empty string or container followed by comma
    # i.e. >< OR >CN=Students,< 
    my ($role,$group) = @_;
    my $group_strg="CN=".$group.",";
    my $container="";
    if ($role eq "student"){
        $container=$group_strg.$DevelConf::AD_student_cn;
    }  elsif ($role eq "teacher"){
        $container=$DevelConf::AD_teacher_cn;
    }  elsif ($role eq "class"){
        $container=$DevelConf::AD_class_cn;
    }  elsif ($role eq "project"){
        $container=$DevelConf::AD_project_cn;
    }  elsif ($role eq "workstation"){
        $container=$DevelConf::AD_workstation_cn;
    }  elsif ($role eq "management"){
        $container=$DevelConf::AD_management_cn;
    }  elsif ($role eq "printer"){
        $container=$DevelConf::AD_printer_cn;
    }
    # add the comma if necessary
    if ($container ne ""){
        $container=$container.",";
    }
}


sub AD_ou_add {
    # if $result->code is not given, the add is silent
    my ($ldap,$ou) = @_;
    my $base=&AD_get_base();
    my $dn="OU=".$ou.",".$base;
    # provide that a ou exists
    my $result = $ldap->add($dn,attr => ['objectclass' => ['top', 'organizationalUnit']]);
    #$result->code && warn "failed to add entry: ", $result->error ;
    my $student=$DevelConf::AD_student_cn.",".$dn;
    $result = $ldap->add($student,attr => ['objectclass' => ['top', 'container']]);
    my $teacher=$DevelConf::AD_teacher_cn.",".$dn;
    $result = $ldap->add($teacher,attr => ['objectclass' => ['top', 'container']]);
    my $class=$DevelConf::AD_class_cn.",".$dn;
    $result = $ldap->add($class,attr => ['objectclass' => ['top', 'container']]);
    my $project=$DevelConf::AD_project_cn.",".$dn;
    $result = $ldap->add($project,attr => ['objectclass' => ['top', 'container']]);
    my $workstation=$DevelConf::AD_workstation_cn.",".$dn;
    $result = $ldap->add($workstation,attr => ['objectclass' => ['top', 'container']]);
    my $management=$DevelConf::AD_management_cn.",".$dn;
    $result = $ldap->add($management,attr => ['objectclass' => ['top', 'container']]);
    my $printer=$DevelConf::AD_printer_cn.",".$dn;
    $result = $ldap->add($printer,attr => ['objectclass' => ['top', 'container']]);
    my $custom=$DevelConf::AD_custom_cn.",".$dn;
    $result = $ldap->add($custom,attr => ['objectclass' => ['top', 'container']]);
}



sub AD_user_test_exist {
    my ($ldap,$user) = @_;
    # check if user exists
    my $filter="(&(objectclass=user) (cn=".$user."))"; # (&(objectclass=user)(cn=pete)
    my $base=&AD_get_base();
    my $mesg = $ldap->search( # perform a search
                      base   => $base,
                      scope => 'sub',
                      filter => $filter,
                            );
    #print Dumper(\$mesg);
    my $count = $mesg->count;
    if ($count > 0){
        return $count;
    } else {
        return 0;
    }
}


sub AD_group_test_exist {
    my ($ldap,$group) = @_;
    # check if group exists
    my $filter="(&(objectclass=group) (cn=".$group."))"; # (&(objectclass=group)(cn=7a)
    my $base=&AD_get_base();
    $mesg = $ldap->search( # perform a search
                   base   => $base,
                   scope => 'sub',
                   filter => $filter,
                         );
    #print Dumper(\$mesg);
    my $count = $mesg->count; 
    if ($count>0){
        return $count;
    } else {
        return 0;
    }
}



sub AD_group_create {
    my ($arg_ref) = @_;
    my $ldap = $arg_ref->{ldap};
    my $group = $arg_ref->{group};
    my $ou = $arg_ref->{ou};
    my $role = $arg_ref->{role};
    my $school_token = $arg_ref->{school_token};

    my $group_token=&AD_get_group_by_token($group,$school_token);

    # calculate missing Attributes
    my $base=&AD_get_base();
    my $container=&AD_get_container_by_role($role,$group_token);
    my $dn = "cn=".$group_token.",".$container."OU=".$ou.",".$base;

    if ($count=&AD_group_test_exist($ldap,$group_token) > 0){
        print "   * Group $group_token exists already ($count results)\n";
        return;
    }

    # adding the group
    &Sophomorix::SophomorixBase::print_title("Creating Group:");
    print("   Group:    $group_token\n");
    print("   Role:     $role\n");
    print("   dn:       $dn\n");
    my $result = $ldap->add( $dn,
                           attr => [
                             'cn'   => $group_token,
                             'sAMAccountName' => $group_token,
                             'objectclass' => ['top',
                                               'group' ],
                                   ]
                           );
    $result->code && warn "failed to add entry: ", $result->error ;
    return;
}



sub AD_group_addmembers {
    my ($arg_ref) = @_;
    my $ldap = $arg_ref->{ldap};
    my $group = $arg_ref->{group};
    my $user = $arg_ref->{addmembers};
    my $school_token = $arg_ref->{school_token};

    $group=&AD_get_group_by_token($group,$school_token);

    my $count=&AD_user_test_exist($ldap,$user);
    if ($count > 0){
        print "   * User $user exists ($count results)\n";
        print "Adding $user to group $group\n";
        my $command="samba-tool group addmembers ". $group." ".$user;
        print "   # $command\n";
        system($command);
        return;
    } else {
        print "   * User $user nonexisting ($count results)\n";
        return;
    }
}



sub AD_group_removemembers {
    my ($arg_ref) = @_;
    my $ldap = $arg_ref->{ldap};
    my $group = $arg_ref->{group};
    my $user = $arg_ref->{removemembers};
    my $school_token = $arg_ref->{school_token};

    $group=&AD_get_group_by_token($group,$school_token);

    my $count=&AD_user_test_exist($ldap,$user);
    if ($count > 0){
        print "   * User $user exists ($count results)\n";
        print "Removing $user from group $group\n";
        my $command="samba-tool group removemembers ". $group." ".$user;
        print "   # $command\n";
        system($command);
        return;
    } else {
        print "   * User $user nonexisting ($count results)\n";
        return;
    }
}



sub  get_forbidden_logins{
    my ($ldap) = @_;
    my %forbidden_logins = %DevelConf::forbidden_logins;

    my $base=&AD_get_base();
 
    # users from ldap
    $mesg = $ldap->search( # perform a search
                   base   => $base,
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
                   base   => $base,
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
