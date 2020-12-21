#! /usr/bin/perl -w

# Note, you may have to adjust this path:
# use lib "/usr/lib/amanda/perl";                   # 1:3.3.6-4 & earlier (??)
use lib "/usr/lib/x86_64-linux-gnu/amanda/perl/"; # 1:3.4.3-1

use strict;
use Amanda::Config qw( :init :getconf );

my $config_name = shift @ARGV;
config_init($CONFIG_INIT_EXPLICIT_NAME, $config_name);
# apply_config_overrides($config_overrides);
my ($cfgerr_level, @cfgerr_errors) = config_errors();
if ($cfgerr_level >= $CFGERR_WARNINGS) {
  config_print_errors();
  if ($cfgerr_level >= $CFGERR_ERRORS) {
    die("errors processing config file");
  }
}

# tapedev and chg-disk seem to be the preferred variables for 3.4.3.

my $tapeDev = getconf($CNF_TAPEDEV);
if (length ($tapeDev) == 0) {
  $tapeDev = getconf($CNF_TPCHANGER);
}
$tapeDev =~ s/^chg-disk://g;
$tapeDev =~ s/^file://g;

print $tapeDev;
