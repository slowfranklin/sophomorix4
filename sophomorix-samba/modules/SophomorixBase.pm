#!/usr/bin/perl -w
# This perl module SophomorixBase is maintained by Rüdiger Beck
# It is Free Software (License GPLv3)
# If you find errors, contact the author
# jeffbeck@web.de  or  jeffbeck@linuxmuster.net

package Sophomorix::SophomorixBase;
require Exporter;
#use File::Basename;
#use Time::Local;
#use Time::localtime;
#use Quota;
#use Sys::Filesystem ();


@ISA = qw(Exporter);

@EXPORT_OK = qw( 
               );
@EXPORT = qw(
            print_line
            print_title
            time_stamp_AD
            time_stamp_file
            unlock_sophomorix
            lock_sophomorix
            check_options
            );




# formatted printout
######################################################################

sub print_line {
   print "========================================",
         "========================================\n";
}


sub print_title {
   my ($a) = @_;
   if($Conf::log_level>=2){
   print  "\n#########################################", 
                            "#######################################\n";
   printf " # %-70s # ",$a;
   print  "\n########################################",
                            "########################################\n";
   } else {
         printf "#### %-69s####\n",$a;
   }
}


# time stamps
######################################################################

# use this timestamp for the sophomorix-schema in AD
sub time_stamp_AD {
  my $timestamp = `date '+%Y-%m-%d %H:%M:%S'`;
  chomp($timestamp);
  return $timestamp;
}

# use this timestamp for filenames
sub time_stamp_file {
   my $zeit = `date +%Y-%m-%d_%H-%M-%S`;
   chomp($zeit);
   return $zeit;
}


# sophomorix locking
######################################################################
sub unlock_sophomorix{
    &title("Removing lock in $DevelConf::lock_file");
    my $timestamp=&time_stamp_file();
    my $unlock_dir=$DevelConf::lock_logdir."/".$timestamp."_unlock";
    # make sure logdir exists
    if (not -e "$DevelConf::lock_logdir"){
        system("mkdir $DevelConf::lock_logdir");
    }

    if (-e $DevelConf::lock_file){
        # create timestamped dir
        if (not -e "$unlock_dir"){
            system("mkdir $unlock_dir");
        }
        
        # save sophomorix.lock
        system("mv $DevelConf::lock_file $unlock_dir");

        # saving last lines of command.log
        $command="tail -n 100  ${DevelConf::log_command} ".
	         "> ${unlock_dir}/command.log.tail";
        if($Conf::log_level>=3){
   	    print "$command\n";
        }
	system("$command");

        print "Created log data in ${unlock_dir}\n";
    } else {
        &title("Lock $DevelConf::lock_file did not exist");
    }
}


sub lock_sophomorix {
    my ($type,$pid,@arguments) = @_;
    # $type: lock (lock when not existing)
    # $type, steal when existing
    # $pid: steal only when this pid is in the lock file

    # prepare datastring to write into lockfile
    my $timestamp = `date '+%Y-%m-%d %H:%M:%S'`;
    chomp($timestamp);
    my $lock="lock::${timestamp}::creator::$0";
    foreach my $arg (@arguments){
        if ($arg eq "--skiplock"){
            $skiplock=1;
        }
        if ($arg eq ""){
   	    $lock=$lock." ''";
        } else {
	    $lock=$lock." ".$arg ;
        }
    }
    $lock=$lock."::$$"."::\n";

    if ($type eq "lock"){
        # lock , only when nonexisting
        if (not -e $DevelConf::lock_file){
           &title("Creating lock in $DevelConf::lock_file");
           open(LOCK,">$DevelConf::lock_file") || die "Cannot create lock file \n";;
           print LOCK "$lock";
           close(LOCK);
        } else {
           print "Cold not create lock file (file exists already!)\n";
           exit;
        }
    } elsif ($type eq "steal"){
        # steal, only when existing with pid $pid
        my ($l_script,$l_pid)=&read_lockfile();
	if (-e $DevelConf::lock_file
           and $l_pid==$pid){
           &title("Stealing lock in $DevelConf::lock_file");
           open(LOCK,">$DevelConf::lock_file") || die "Cannot create lock file \n";;
           print LOCK "$lock";
           close(LOCK);
           return 1;
       } else {
           print "Coldnt steal lock file (file vanished! or pid changed)\n";
           exit;
       }
    }
}




# others
######################################################################
# error, when options are not given correctly
sub  check_options{
   my ($parse_ergebnis) = @_;
   if (not $parse_ergebnis==1){
      my @list = split(/\//,$0);
      my $scriptname = pop @list;
      print "\nYou have made a mistake, when specifying options.\n"; 
      print "See error message above. \n\n";
      print "... $scriptname is terminating.\n\n";
      exit;
   } else {
      if($Conf::log_level>=3){
         print "All options  were recognized.\n";
      }
   }
}



# END OF FILE
# Return true=1
1;
