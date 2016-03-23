#!/usr/bin/perl -w
use Net::LDAP;
use Unicode::Map8;
use Unicode::String qw(utf16);
use Data::Dumper;
$Data::Dumper::Indent = 1;
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Useqq = 1;
$Data::Dumper::Terse = 1; 

my $ou="ou=BSZLEO,DC=linuxmuster,DC=local";


my $ldap = Net::LDAP->new('ldaps://localhost')  or  die "$@";
# bind as Administrator
my $mesg = $ldap->bind('CN=Administrator,CN=Users,DC=linuxmuster,DC=local',
                         password => 'Muster!');
# show errors from bind
$mesg->code && die $mesg->error;




# add entry
my $result = $ldap->add( $ou, 
                       attr => [
                         'objectclass' => ['top', 
                                           'organizationalUnit'],
                       ]
);

$result->code && warn "failed to add entry: ", $result->error ;




## select data
#$mesg = $ldap->search( # perform a search
#                        base   => "DC=linuxmuster,DC=local",
#                        filter => "(sn=Lord)"
#                      );
#
#$mesg->code && die $mesg->error;
#print Dumper(\$mesg);


# unbind
$mesg = $ldap->unbind();
#  show errors from unbind
$mesg->code && die $mesg->error;
