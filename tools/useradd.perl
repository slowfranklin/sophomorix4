#!/usr/bin/perl -w
use Net::LDAP;
use Unicode::Map8;
use Unicode::String qw(utf16);
use Data::Dumper;
$Data::Dumper::Indent = 1;
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Useqq = 1;
$Data::Dumper::Terse = 1; 

# config these values
my $firstname="Rüdiger";
my $surname="Beck";
my $login="beckro19";
my $plain_password="Muster!";


# calculate from config
my $display_name = $firstname." ".$surname;
my $user_principal_name = $login."\@"."linuxmuster.local";
# dn is login... (other than samba-tool default: firstname surname)
my $dn = "cn=".$login.", CN=Users, DC=linuxmuster,DC=local";
#my $dn = "cn=".$login.", CN=Users, OU=Base-School";

# password generation
# build the conversion map from your local character set to Unicode
my $charmap = Unicode::Map8->new('latin1')  or  die;
# surround the PW with double quotes and convert it to UTF-16
my $uni_password = $charmap->tou('"'.$plain_password.'"')->byteswap()->utf16();


my $ldap = Net::LDAP->new('ldaps://localhost')  or  die "$@";
# bind as Administrator
my $mesg = $ldap->bind('CN=Administrator,CN=Users,DC=linuxmuster,DC=local',
                         password => 'Muster!');
# show errors from bind
$mesg->code && die $mesg->error;




# add user
my $result = $ldap->add( $dn,
                       attr => [
                         'sAMAccountName' => $login,
                         'givenName'   => $firstname,
                         'sn'   => $surname,
                         'displayName'   => [$display_name],
                         'userPrincipalName' => $user_principal_name,
                         'unicodePwd' => $uni_password,
                         'sophomorixExitAdminClass' => "12345678", 
                         'userAccountControl' => '512',
                         'objectclass' => ['top', x'person',
                                           'organizationalPerson',
                                           'user' ],
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
