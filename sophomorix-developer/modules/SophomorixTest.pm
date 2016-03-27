#!/usr/bin/perl -w
# This perl module SophomorixTest is maintained by Rüdiger Beck
# It is Free Software (License GPLv3)
# If you find errors, contact the author
# jeffbeck@web.de  or  jeffbeck@linuxmuster.net

package Sophomorix::SophomorixTest;
require Exporter;
#use File::Basename;
#use Time::Local;
#use Time::localtime;
#use Quota;
#use Sys::Filesystem ();
use Unicode::Map8;
use Unicode::String qw(utf16);
use Net::LDAP;
use Sophomorix::SophomorixConfig;
use Test::More "no_plan";
use Data::Dumper;
$Data::Dumper::Indent = 1;
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Useqq = 1;
$Data::Dumper::Terse = 1; 

@ISA = qw(Exporter);

@EXPORT_OK = qw( );
@EXPORT = qw(
            AD_test_object_exist
            );




sub AD_test_object_exist {
    # verifies an object and Attributes in ldap
    my ($arg_ref) = @_;
    my $ldap = $arg_ref->{ldap};
    my $dn = $arg_ref->{dn};

    # user
    my $display_name = $arg_ref->{displayName};
    my $name = $arg_ref->{name};
    my $given_name = $arg_ref->{givenName};
    my $sam_account =$arg_ref->{sAMAccountname};
    my $sn =$arg_ref->{sn};

    # sophomorix user
    my $s_admin_class = $arg_ref->{sophomorixAdminClass};
    my $s_first_password = $arg_ref->{sophomorixFirstPassword};
    my $s_firstname_ascii = $arg_ref->{sophomorixFirstnameASCII};
    my $s_surname_ascii = $arg_ref->{sophomorixSurnameASCII};
    my $s_role = $arg_ref->{sophomorixRole};
    my $s_school_prefix = $arg_ref->{sophomorixSchoolPrefix};
    my $s_school_name = $arg_ref->{sophomorixSchoolname};

    my $base=&Sophomorix::SophomorixSambaAD::AD_get_base();
    my $filter="(cn=*)";
    my $mesg = $ldap->search(
                      base   => $dn,
                      scope => 'base',
                      filter => $filter,
                            );
    #print Dumper(\$mesg);
    my ($entry,@entries) = $mesg->entries;
    my $count = $mesg->count;

    # Testing object existence
    is ($count,1, "*** Found 1 Object: $dn");
   
    if ($count==1){
        # Testing attributes
        if (defined $display_name){
            is ($entry->get_value ('DisplayName'),$display_name,
                                   "  * displayName is $display_name");
        }
        if (defined $given_name){
            is ($entry->get_value ('givenName'),$given_name,
                                   "  * givenName is $given_name")
        }
        if (defined $name){
            is ($entry->get_value ('name'),$name,
                                   "  * name is $name")
        }
        if (defined $sam_account){
            is ($entry->get_value ('sAMAccountName'),$sam_account,
                                   "  * sAMAccountName is $sam_account")
        }
        if (defined $sn){
            is ($entry->get_value ('sn'),$sn,
                                   "  * sn is $sn")
        }
        if (defined $s_admin_class){
            is ($entry->get_value ('sophomorixAdminClass'),$s_admin_class,
                                   "  * sophomorixAdminClass is $s_admin_class")
        }
        if (defined $s_first_password){
            is ($entry->get_value ('sophomorixFirstPassword'),$s_first_password,
                                   "  * sophomorixFirstPassword is $s_first_password")
        }
        if (defined $s_firstname_ascii){
            is ($entry->get_value ('sophomorixFirstnameASCII'),$s_firstname_ascii,
                                   "  * sophomorixFirstnameASCII is $s_firstname_ascii")
        }
        if (defined $s_surname_ascii){
            is ($entry->get_value ('sophomorixSurnameASCII'),$s_surname_ascii,
                                   "  * sophomorixSurnameASCII is $s_surname_ascii")
        }
        if (defined $s_role){
            is ($entry->get_value ('sophomorixRole'),$s_role,
                                   "  * sophomorixRole is $s_role")
        }
        if (defined $s_school_prefix){
            is ($entry->get_value ('sophomorixSchoolPrefix'),$s_school_prefix,
                                   "  * sophomorixSchoolPrefix is $s_school_prefix")
        }
        if (defined $s_school_name){
            is ($entry->get_value ('sophomorixSchoolname'),$s_school_name,
                                   "  * sophomorixSchoolname is $s_school_name")
        }
    } else {
        print "\nWARNING: Skipping a lot of tests\n\n";
    }
}




# END OF FILE
# Return true=1
1;
