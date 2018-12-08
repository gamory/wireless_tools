#!/usr/bin/perl

# Bluetooth enum tools - 0.0.1 - Kain Research (2002-2018)

my $max_errors = "";
my $log_file = "";
my $source_dev = "";
my $target_dev = "";
my $numArgs = $#ARGV + 1;
my $index = 0;
while ($index < $numArgs) {
    if ($ARGV[$index] eq "-v" || $ARGV[$index] eq "--version") {
        print "bt_emun - 0.0.1\n";
        print "Written by Rick Burris\n";
        print "Kain Research (2002-2018), all rights reserved\n";
        print "\n";
        exit;
    }
    if ($ARGV[$index] eq "-h" || $ARGV[$index] eq "--help") {
        print "bt_enum - Help Listing\n";
        print "\n";
        print "-e <number>      Max errors before quitting (default 5)\n";
        print "--errors <num>   \n";
        print "-h               Print this help info\n";
        print "--help           \n";
        print "-l <file>        Log to specified file\n";
        print "--log <file>     \n";
        print "-s <dev>         Source device (local device)\n";
        print "--source <dev>   \n";
        print "-t <MAC>         Target device MAC address\n";
        print "--target <MAC>   \n";
        print "-v               Print version data\n";
        print "--version        \n";
        exit;
    }
    if ($ARGV[$index] eq "-e" || $ARGV[$index] eq "--errors") {
        ++$index;
        $max_errors = $ARGV[$index];
    }
    if ($ARGV[$index] eq "-l" || $ARGV[$index] eq "--log") {
        ++$index;
        $log_file = $ARGV[$index];
    }
    if ($ARGV[$index] eq "-s" || $ARGV[$index] eq "--source") {
        ++$index;
        $source_dev = $ARGV[$index];
    }
    if ($ARGV[$index] eq "-t" || $ARGV[$index] eq "--target") {
        ++$index;
        $target_dev = $ARGV[$index];
    }
    ++$index;
}
print "bt_enum - 0.0.1\n";
print "\n";
if ($log_file ne "") {
    print "Opening log file for writing...";
    open(OUTFILE, ">$log_file") || die "Error while opening outfile \n";
}
if ($max_errors eq "") {
    $max_errors = 5;
}
cprint("bt_enum - 0.0.1\n");
cprint("\n");
cprint("Arguments provided:\n");
cprint("Log file : $log_file\n");
cprint("Errors   : $max_errors\n");
cprint("Source   : $source_dev\n");
cprint("Target   : $target_dev\n");
cprint("\n");
$errors_found = 0;
my $src_dev_arg = "";
if ($source_dev ne "") {
    $src_dev_arg = " -i $source_dev ";
}
my $working_data = "";
my $working_cmd = "";
cprint("Grabbing primary data...\n");
$working_cmd = "sudo gatttool $src_dev_arg -t random -b $target_dev --primary";
$working_data = `$working_cmd 2>&1`;
if ($working_data =~ /.*connect error.*/) {
    ++$errors_found;
    cprint("Failed to grab primary data (err counter $errors_found)\n");
}
else {
    cprint("\"$working_data\"");
}
cprint("Grabbing available handles...\n");
$working_cmd = "sudo gatttool $src_dev_arg -t random -b $target_dev --characteristics";
$working_data = `$working_cmd 2>&1`;
if ($working_data =~ /.*connect error.*/) {
    ++$errors_found;
    cprint("Failed to grab handle data (err counter $errors_found)\n");
}
else {
    cprint("$working_data");
}
cprint("Starting read enumeration...\n");
$index = 0;
my $hexval;
while ($errors_found < $max_errors) {
    $hexval = sprintf("0x%04x", $index);
    cprint("Trying with $hexval\n");
    $working_cmd = "sudo gatttool $src_dev_arg -t random -b $target_dev --char-read -a $hexval";
    $working_data = `$working_cmd 2>&1`;
    if ($working_data =~ /.*connect error.*/) {
        ++$errors_found;
        cprint("Failed to read value (err counter $errors_found)\n");
    }
    if ($working_data =~ /.*Characteristic value\/descriptor read failed: Invalid handle.*/) {
	++$errors_found;
	cprint("Failed to read from handle (err counter $errors_found)\n");
    }
    else {
        cprint("$working_data");
    }
    ++$index;
}
close(OUTFILE);
sub cprint {
    my $input = shift;
    if ($log_file ne "") {
        print OUTFILE $input;
    }
    print $input;
}
