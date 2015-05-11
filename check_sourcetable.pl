#!/usr/bin/perl -w
#
# check_sourcetable.pl 
#
# - reads in "sourcetable.dat" 
# - downloads sourcetable from server
# - generates geoJSON file of mountpoint status
# - syntax : check_sourcetable.pl [sourcetable.dat]
#
# - this script is called by cron
#

use strict;
use warnings;

use LWP::Simple;

### File Locations
#

my $sourcetable = $ARGV[0]; 
die "! Error: cannot find sourcetable" if (! $sourcetable);
my $geoJSON = "/Users/ryan/Dropbox/Public/mount_status.json";

my $second_server = "http://192.104.43.27:2101";
my $first_server = "http://192.104.43.25:2101";

### Variables
#

my ($type,$mountpoint,$identifier,$format,$format_details,$carrier,$nav_system,$network,$country,$latitude,$longitude,$nmea,$solution,$generator,$compression,$auth,$fee,$bitrate,$operator);
my $current_time=localtime;

my %STATIONS= ();

my $num_mounts = 0;

my $icon;
my $red_icon = "https://storage.googleapis.com/support-kms-prod/SNP_2752125_en_v0";
my $green_icon = "https://storage.googleapis.com/support-kms-prod/SNP_2752129_en_v0";

### Create "JSON"
#

open(SOURCE,"$sourcetable") || die "! Error: cannot open sourcetable '$sourcetable'\n";
open(OUT,">$geoJSON") || die "! Error: cannot create client authentication file '$geoJSON'\n";

# File Header

print OUT "gnssfeed_callback(\n";
print OUT "{\n";
print OUT "  \"type\": \"FeatureCollection\",\n";
print OUT "  \"features\": [\n";

while (<SOURCE>) {
   ($type,$mountpoint,$identifier,$format,$format_details,$carrier,$nav_system,$network,$country,$latitude,$longitude,$nmea,$solution,$generator,$compression,$auth,$fee,$bitrate,$operator) = split (/;/,$_);
   
   if ($type =~ m/STR/ && $format =~ m/RTCM/) {

#     print "$mountpoint\n";

     $STATIONS{$mountpoint}{'latitude'}=$latitude;
     $STATIONS{$mountpoint}{'longitude'}=$longitude;
     $STATIONS{$mountpoint}{'status'}=0;

     $num_mounts = $num_mounts + 1;

    
  }
}

my $contents = get($second_server) or print "server not up\n"; 
if ($contents) {
for (split /^/, $contents) {

  ($type,$mountpoint,$identifier,$format,$format_details,$carrier,$nav_system,$network,$country,$latitude,$longitude,$nmea,$solution,$generator,$compression,$auth,$fee,$bitrate,$operator) = split (/;/,$_);
  
  if ($type =~ m/STR/ && $format =~ m/RTCM/) {
   
    $STATIONS{$mountpoint}{'status'}=1;
 
  } 

}
}


my $i=0;

foreach my $station (sort keys %STATIONS) {

  $i = $i + 1;
 
  if ($STATIONS{$station}{'status'} == 1) {
    $icon = $green_icon;
  } else {
    $icon = $red_icon;
  }

  print OUT "  {\n";
  print OUT "    \"type\": \"Feature\",\n";
  print OUT "    \"geometry\": { \"type\": \"Point\", \"coordinates\": [ $STATIONS{$station}{'longitude'}, $STATIONS{$station}{'latitude'} ] },\n";
  print OUT "    \"properties\": { \"name\": \"$station\", \"icon\": \"$icon\", \"status\": \"$STATIONS{$station}{'status'}\" }\n";
  print OUT "  },\n" if $i < $num_mounts;
  print OUT "  }\n" if $i == $num_mounts;
  
}

print OUT "   ]\n";
print OUT "});";

close(SOURCE);
close(OUT);
