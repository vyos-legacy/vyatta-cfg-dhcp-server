#!/usr/bin/perl

use strict;
use warnings;

use File::Path;
use Getopt::Long;

# Set to 1 to enable debug output.
#
my $debug_flag = 0;

my $source_file = "src/templates.in";
my $generated_templates_subdir = "generated-templates/";

GetOptions(
    "debug"     => \$debug_flag,
    "source-file=s" =>  \$source_file,
);

sub log_msg {
    my $message = shift;

    print "DEBUG: $message" if $debug_flag;
}


# Main section

if (! open(TPL_SRC, "<$source_file")) {
    printf("Can't open template source file: $source_file\n");
    exit 1;
}

my $tpl_file_open = 0;

my $line;
while ($line = <TPL_SRC>) {
    chomp($line);

    if ($line =~ /^file: /) {
	my $tpl_filename = $line;
	$tpl_filename =~ s/^file: //;
	
	$tpl_filename = $generated_templates_subdir . $tpl_filename;
	my $tpl_dirs = $tpl_filename;
	$tpl_dirs =~ s/\/node.def$//;

	log_msg("Creating directory: $tpl_dirs\n");
	mkpath($tpl_dirs);
	# Check error returns?

	log_msg("Opening template file: $tpl_filename\n");
	if (! open(TPL_FILE, ">$tpl_filename")) {
	    printf("Can't open template file: $tpl_filename\n");
	    exit 1;
	}

	$tpl_file_open++;
    } elsif ($line =~ /^\#\#/) {
	next;
    } else {
	if ($tpl_file_open > 0) {
	    printf(TPL_FILE "$line\n");
	}
    }
}

printf("Wrote $tpl_file_open template files.\n");
