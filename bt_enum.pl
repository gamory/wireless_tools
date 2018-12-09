#!/usr/bin/perl

use strict;
use DBI;

# Bluetooth enum tool - 0.0.1 - Kain Research (2002-2018)
# Written by Richard Burris

my $max_errors = "";
my $log_file = "";
my $source_dev = "";
my $target_dev = "";
my $numArgs = $#ARGV + 1;
my $index = 0;
my $db_server = "";
my $db_port = "";
my $db_user = "";
my $db_pass = "";
my $dbh = "";
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
        print "-db <address>    Specify a Postgres database to use\n";
        print "--database <addr> \n";
        print "-dbu <user>      Specify username for database connection\n";
        print "--dbuser <user>  \n";
        print "-dbp <pass>      Specify password for database connection\n";
        print "--dbpass <pass>  \n";
        print "--dbport <port>  Specify port for database connection (default 5432)\n";
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
    if ($ARGV[$index] eq "-db" || $ARGV[$index] eq "--database") {
        ++$index;
        $db_server = $ARGV[$index];
    }
    if ($ARGV[$index] eq "-dbu" || $ARGV[$index] eq "--dbuser") {
        ++$index;
        $db_user = $ARGV[$index];
    }
    if ($ARGV[$index] eq "-dbp" || $ARGV[$index] eq "--dbpass") {
        ++$index;
        $db_pass = $ARGV[$index];
    }
    if ($ARGV[$index] eq "--dbport") {
        ++$index;
        $db_port = $ARGV[$index];
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
if ($target_dev eq "") {
    print "No target device specified, quitting...\n";
    exit;
}
if ($db_server ne "") {
    if ($db_user eq "" || $db_pass eq "") {
        print "Username or password for db connection was not specified, quitting...\n";
        exit;
    }
}
if ($log_file ne "") {
    print "Opening log file for writing...";
    open(OUTFILE, ">$log_file") || die "Error while opening outfile \n";
}
if ($max_errors eq "") {
    $max_errors = 5;
}
if ($db_port eq "") {
    $db_port = "5432";
}
if ($db_server ne "") {
    db_make_tables();
}
cprint("bt_enum - 0.0.1\n");
cprint("\n");
cprint("Arguments provided:\n");
cprint("Log file : $log_file\n");
cprint("Errors   : $max_errors\n");
cprint("Source   : $source_dev\n");
cprint("Target   : $target_dev\n");
cprint("\n");
my $errors_found = 0;
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
sub db_connect {
    if ($dbh ne "") {
        return;
    }
    $dbh = DBI->connect("dbi:Pg:dbname=KRWireless;host=$db_server;port=$db_port",$db_user,$db_pass,{AutoCommit => 0}) || return "Failure";
}
sub db_disconnect {
    if ($dbh eq "") {
        return;
    }
    $dbh->commit;
    $dbh->disconnect;
}
sub db_make_tables {
    if ($dbh eq "") {
        db_connect();
    }
    cprint("Checking database for proper data table(s)...\n");
    my $sqlcmd = $dbh->prepare("SELECT COALESCE(pg_tables.tablename, \'EMPTY\') FROM pg_tables WHERE schemaname=\'public\';") || die ("Failed to prepare table query... Quitting...");
    $sqlcmd->execute() || die ("Failed to execute table query... Quitting...");
    my @sqlret = ();
    my $main_found = "False";
    while ( @sqlret = $sqlcmd->fetchrow_array ) {
        if ($sqlret[0] eq "bt_enum") {
            $main_found = "True";
            cprint("Table found...\n");
        }
    }
    if ($main_found ne "True") {
        cprint("Building main table...");
        $sqlcmd = $dbh->prepare("CREATE TABLE \"bt_enum\" (key serial PRIMARY KEY, device TEXT, handle TEXT, value TEXT, updated TIMESTAMP);") || die ("Failed to prepare bt_enum table creation query... Quitting...");
        $sqlcmd->execute() || die ("Failed to execute bt_enum table creation query... Quitting...");
        $dbh->commit() || die ("Failed to commit in db_make_tables\n");
        cprint("Done.\n");
    }
}