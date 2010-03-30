#!/usr/bin/perl

# Module: dhcpdv6-config.pl
#
# **** License ****
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# A copy of the GNU General Public License is available as
# `/usr/share/common-licenses/GPL' in the Debian GNU/Linux distribution
# or on the World Wide Web at `http://www.gnu.org/copyleft/gpl.html'.
# You can also obtain it by writing to the Free Software Foundation,
# Free Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston,
# MA 02110-1301, USA.
#
# This code was originally developed by Vyatta, Inc.
# Portions created by Vyatta are Copyright (C) 2010 Vyatta, Inc.
# All Rights Reserved.
#
# Author: Bob Gilligan
# Date: March 2010
# Description: Script to setup DHCPv6 server
#
# **** End License ****

use strict;
use lib "/opt/vyatta/share/perl5/";

use Getopt::Long;
use Vyatta::Config;

# Globals
my $debug_flag;
my $config_filename = "/opt/vyatta/etc/dhcpdv6.conf";

GetOptions(
    "debug"	=> \$debug_flag,
    "config-file=s" =>	\$config_filename,
);

sub log_msg {
    my $message = shift;

    print "DEBUG: $message" if $debug_flag;
}

# Return true if user's param string $param matches
# $match item for item, allowing wild-card string
# in $match.
#
sub param_match {
    my ($match, $param) = @_;

    my @match_array = split(" ", $match);
    my @param_array = split(" ", $param);

    if (scalar(@match_array) != scalar(@param_array)) {
	# match and param arrays don't even have the same number
	# of members.  Can't match.
	return 0;
    }

    my $index = 0;
    foreach my $match_item (@match_array) {
	my $param_item = @param_array[$index];
	$index++;
	if (!($match_item eq "*") &&
	    !($match_item eq $param_item)) {
	    # no wildcard or exact match
	    return 0;
	}
    }
    return 1;
}

# Substitue references of the form $1, $2, etc. in $string with
# values in $param_template string array.  $param_template is the
# Vyatta parameter string that the user configured.
#
sub param_substitute {
    my ($input_string, $param_template) = @_;

    # Turn $param_template into an array of items so that we can
    # reference individual items by number.
    my @param_template_array = split(" ", $param_template);

    my $index = 1;
    foreach my $param (@param_template_array) {
	if ($input_string =~ m/VAR-${index}/) {
	    log_msg("param_substitue: substituting $param for VAR-${index} \n");
	    $input_string =~ s/VAR-${index}/$param/;
	}
	$index++;
    }
    return $input_string;
}


#
# Functions that are used in the "action arrays"
#
my @temp_list = ();

sub write_cf {
    my ($string) = @_;
    printf(CONF_FILE "$string");
}

#
# A simple list is written out to the config file with each item
# separated by commas.
#
sub write_list {
   my ($string) = @_;

   my $num_items = scalar(@temp_list);
   if ($num_items > 0) {
       printf(CONF_FILE "$string ");
       my $item_count = 0;
       foreach my $item (@temp_list) {
	   if ($item_count > 0) {
	       printf(CONF_FILE ", ");
	   }
	   printf(CONF_FILE "$item");
	   $item_count++;
       }
       printf(CONF_FILE ";\n");
   }
   @temp_list = ();
}


# A domain list differs from a simple list in that each
# element must be enclosed in double-quotes, then
# separated by commas.
#
sub write_domain_list {
   my ($string) = @_;

   my $num_items = scalar(@temp_list);
   if ($num_items > 0) {
       printf(CONF_FILE "$string ");
       my $item_count = 0;
       foreach my $item (@temp_list) {
	   if ($item_count > 0) {
	       printf(CONF_FILE ", ");
	   }
	   printf(CONF_FILE "\"$item\"");
	   $item_count++;
       }
       printf(CONF_FILE ";\n");
   }
   @temp_list = ();
}


sub push_list {
   my ($string) = @_;
   push(@temp_list, $string);
}

#
# We have one "action array" for each of the three transitions:
# Pushing to a new non-leaf level, reach a leaf node with a value, and 
# poping back to non-lef level.  Each entry in an action array has
# three elements:  1) a string to match against the parameter string; 
# 2) A function to call if it matches, and 3) a string to pass to that
# function.  The first string supports the use of "*" as a wildcard match.
# The third string supports a variable substitution syntax that
# substitues a value from the user's parameter string into the
# string to be passed into the function.
#

my @push_arr = (
    [ "shared-network *", \&write_cf,  "shared-network VAR-2 {\n" ], 
    [ "shared-network * subnet *", \&write_cf, "    subnet6 VAR-4 {\n" ],
    [ "shared-network * subnet * static-mapping *", \&write_cf,
      "        host VAR-6 {\n" ],
    [ "shared-network * subnet * address-range prefix *", \&write_cf,
      "        range6 VAR-7" ],
);

my @pop_arr = (
    [ "shared-network *", \&write_cf, "}\n" ],
    [ "shared-network * subnet *", \&write_cf, "    }\n" ],
    [ "shared-network * subnet * name-server", \&write_list, 
      "        option dhcp6.name-servers" ],
    [ "shared-network * subnet * domain-search", \&write_domain_list, 
      "        option dhcp6.domain-search" ],
    [ "shared-network * subnet * sip-server-address", \&write_list, 
      "        option dhcp6.sip-servers-addresses" ],
    [ "shared-network * subnet * sip-server-name", \&write_domain_list, 
      "        option dhcp6.sip-servers-names" ],
    [ "shared-network * subnet * nis-server", \&write_list, 
      "        option dhcp6.nis-servers" ],
    [ "shared-network * subnet * nisplus-server", \&write_list, 
      "        option dhcp6.nisp-servers" ],
    [ "shared-network * subnet * sntp-server", \&write_list, 
      "        option dhcp6.sntp-servers" ],
    [ "shared-network * subnet * address-range start *", \&write_cf, 
      ";\n" ],
    [ "shared-network * subnet * address-range prefix *", \&write_cf, 
      ";\n" ],
    [ "shared-network * subnet * static-mapping *", \&write_cf,
      "        }\n" ],

);

my @leaf_arr = (
    [ "shared-network * subnet * name-server * address *", \&push_list,
      "VAR-8" ],
    [ "shared-network * subnet * domain-search * name *", \&push_list,
      "VAR-8" ],
    [ "shared-network * subnet * sip-server-address * address *", \&push_list,
      "VAR-8" ],
    [ "shared-network * subnet * sip-server-name * name *", \&push_list,
      "VAR-8" ],
    [ "shared-network * subnet * nis-server * address *", \&push_list,
      "VAR-8" ],
    [ "shared-network * subnet * nisplus-server * address *", \&push_list,
      "VAR-8" ],
    [ "shared-network * subnet * nis-domain *", \&write_cf,
      "        option dhcp6.nis-domain-name \"VAR-6\";\n" ],
    [ "shared-network * subnet * nisplus-domain *", \&write_cf,
      "        option nisp-domain-name \"VAR-6\";\n" ],
    [ "shared-network * subnet * sntp-server * address *", \&push_list,
      "VAR-8" ],
    [ "shared-network * subnet * lease-time maximum *", \&write_cf,
      "        max-lease-time VAR-7;\n" ],
    [ "shared-network * subnet * lease-time minimum *", \&write_cf,
      "        min-lease-time VAR-7;\n" ],
    [ "shared-network * subnet * lease-time default *", \&write_cf,
      "        default-lease-time VAR-7;\n" ],
    [ "shared-network * subnet * address-range start * stop *", \&write_cf,
      "        range6 VAR-7 VAR-9" ],
    [ "shared-network * subnet * address-range prefix * temporary", \&write_cf,
      " temporary" ],
    [ "shared-network * subnet * static-mapping * ipv6-address *", \&write_cf,
      "            fixed-address6 VAR-8;\n" ],
    [ "shared-network * subnet * static-mapping * mac-address *", \&write_cf,
      "            hardware ethernet VAR-8;\n" ],
);


#
# Walk through the action array passed in by reference. If an entry is
# found in that array whose first string passes the users's parameter
# string passed in, then perform parameter substitution on the third
# string in the entry, and call the function identified by the second
# element of the entry.
#
sub action_func {
    my ($action_arr_ref, $param) = @_;

    my @action_arr = @$action_arr_ref;

    foreach my $row (0 .. scalar(@action_arr) - 1) {
	my $match = $action_arr[$row][0];

	if (param_match ($match, $param)) {
	    my $func = $action_arr[$row][1];
	    my $arg = $action_arr[$row][2];

	    my $action_string = param_substitute($arg, $param);
	    &$func($action_string);
	}
    }
}

# 
# Recursive walk of the config tree starting at $level. $vc is the
# config pointer.  $depth records the current tree depth, primarily
# for debugging.  The final three args are references to the three
# "action arrays" discussed above.
#
sub walk_tree {
    my ($vc, $level, $depth, $push_arr_ref, $pop_arr_ref, $leaf_arr_ref) = @_;
    
    log_msg("in walk_tree at depth $depth level is: $level \n");

    my @values = $vc->returnValues($level);
    my $num_values = scalar(@values);
    if ($num_values > 0) {
	foreach my $value (sort (@values)) {
	    my $leaf_value = $level . " " . $value;
	    log_msg("Leaf: $leaf_value\n");

	    action_func($leaf_arr_ref, $leaf_value);
	}
    } else {
	log_msg("Push to: $level\n");
	action_func($push_arr_ref, $level);

	my @node_array = $vc->listNodes($level);

	foreach my $node (sort (@node_array)) {
	    log_msg("node at depth $depth is $node\n");
	    walk_tree ($vc, $level . " " . $node, $depth + 1, 
		       $push_arr_ref, $pop_arr_ref, $leaf_arr_ref);
	}
        log_msg("Pop to: $level\n");
	action_func($pop_arr_ref, $level);
    }
}

#
# Main section
#

my $vcDHCP = new Vyatta::Config();

# Do we need to perform any cross-parameter validation checks?
# This might include:
#  - Subnet prefix overlap
#  - Range overlaps

# Open the config file
# 
if (! open(CONF_FILE, ">$config_filename")) {
    printf("Can't open config file for writing: $config_filename\n");
    exit 1;
}

# Write some comments so people know where it came from.
# 
printf(CONF_FILE "# This file is auto-generated by the Vyatta configuration sub-system.\n");
printf(CONF_FILE "# Do not edit it by hand.\n");
my $iam = `whoami`;
chomp ($iam);
printf(CONF_FILE "# Auto-generated by: $iam\n");
my $date_time = `date`;
chomp ($date_time);
printf(CONF_FILE "# Auto-generated on: $date_time\n");
printf(CONF_FILE "#\n");


# Walk the config tree
# 
if ($vcDHCP->exists('service dhcpv6-server') ) {
    $vcDHCP->setLevel('service dhcpv6-server');
    log_msg("Initial call to walk_tree.\n");
    walk_tree($vcDHCP, "", 0, \@push_arr, \@pop_arr, \@leaf_arr);
}

# Close the config file, we're done!
# 
close(CONF_FILE);
