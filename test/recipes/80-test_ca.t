#! /usr/bin/perl

use strict;
use warnings;

use POSIX;
use File::Path 2.00 qw/rmtree/;
use OpenSSL::Test qw/:DEFAULT cmdstr srctop_file/;

setup("test_ca");

$ENV{OPENSSL} = cmdstr(app(["openssl"]));
my $std_openssl_cnf =
    srctop_file("apps", $^O eq "VMS" ? "openssl-vms.cnf" : "openssl.cnf");

rmtree("demoCA", { safe => 0 });

plan tests => 4;
 SKIP: {
     $ENV{OPENSSL_CONFIG} = "-config ".srctop_file("test", "CAss.cnf");
     skip "failed creating CA structure", 3
	 if !ok(run(perlapp(["CA.pl","-newca"], stdin => undef, stderr => undef)),
		'creating CA structure');

     $ENV{OPENSSL_CONFIG} = "-config ".srctop_file("test", "Uss.cnf");
     skip "failed creating new certificate request", 2
	 if !ok(run(perlapp(["CA.pl","-newreq"], stderr => undef)),
		'creating CA structure');

     $ENV{OPENSSL_CONFIG} = "-config ".$std_openssl_cnf;
     skip "failed to sign certificate request", 1
	 if !is(yes(cmdstr(perlapp(["CA.pl", "-sign"], stderr => undef))), 0,
		'signing certificate request');

     ok(run(perlapp(["CA.pl", "-verify", "newcert.pem"], stderr => undef)),
	'verifying new certificate');
}


rmtree("demoCA", { safe => 0 });
unlink "newcert.pem", "newreq.pem";


sub yes {
    my $cntr = 10;
    open(PIPE, "|-", join(" ",@_));
    local $SIG{PIPE} = "IGNORE";
    1 while $cntr-- > 0 && print PIPE "y\n";
    close PIPE;
    return 0;
}

