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
my $login="beckro6";
my $password="Muster!";


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
my $uni_password = $charmap->tou('"'.$password.'"')->byteswap()->utf16();


my $ldap = Net::LDAP->new('ldaps://localhost')  or  die "$@";
# bind as Administrator
my $mesg = $ldap->bind('CN=Administrator,CN=Users,DC=linuxmuster,DC=local',
                         password => 'Muster!');
# show errors from bind
$mesg->code && die $mesg->error;


## select users
############################################################
$mesg = $ldap->search( # perform a search
                base   => "CN=Users,DC=linuxmuster,DC=local",
                scope => 'sub',
                filter => '(objectClass=user)',
                attr => ['sAMAccountName']
                      );
my $max = $mesg->count; 
print "$max User entries:\n";
for( my $index = 0 ; $index < $max ; $index++) {
    my $entry = $mesg->entry($index);
    my @values = $entry->get_value( 'sAMAccountName' );
    foreach my $attr (@values){
        print "   * $attr\n";
    }
}

## select users
############################################################
$mesg = $ldap->search( # perform a search
                base   => "CN=Users,DC=linuxmuster,DC=local",
                scope => 'sub',
                filter => '(objectClass=group)',
                attr => ['sAMAccountName']
                      );
my $max = $mesg->count; 
print "$max Group entries\n";
for( my $index = 0 ; $index < $max ; $index++) {
    my $entry = $mesg->entry($index);
    my @values = $entry->get_value( 'sAMAccountName' );
    foreach my $attr (@values){
        print "   * $attr\n";
    }
}


#
#$mesg->code && die $mesg->error;
#print Dumper(\$mesg);


# unbind
$mesg = $ldap->unbind();
#  show errors from unbind
$mesg->code && die $mesg->error;
