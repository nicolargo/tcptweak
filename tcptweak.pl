#!/usr/bin/perl
#--------------
# TCP Tweaking 
#--------------
# Author : Nicolas Hennion
# Licence: GPL v2
#
# Release notes:
# 0.1b : First beta release
#
$program_name = "TCP Tweak";
$program_version = "0.1b";

use Getopt::Std;
use LWP::Simple;
use Net::Ping;

# Program variables configuration
#################################
# Temp folder (should be readable and writable)
$tmp_folder = "/tmp"; 
# Speed test (URL)
$url_speedtest = "http://speedtest.macbidouille.com/speedtest6.php";
# Host name of the server for the ping test (HTTP ping)
$host_pingtest = "speedtest.macbidouille.com";

# System variables configuration
################################
$default_tcp_receive_window_file = "/proc/sys/net/core/rmem_default";
$default_tcp_receive_window_info = "Default TCP Receive Window";
$default_tcp_receive_window = -1;
$max_tcp_receive_window_file = "/proc/sys/net/core/rmem_max";
$max_tcp_receive_window_info = "Maximum TCP Receive Window";
$max_tcp_receive_window = -1;
$default_tcp_send_window_file = "/proc/sys/net/core/wmem_default";
$default_tcp_send_window_info = "Default TCP Send Window";
$default_tcp_send_window = -1;
$max_tcp_send_window_file = "/proc/sys/net/core/wmem_max";
$max_tcp_send_window_info = "Maximum TCP Send Window";
$max_tcp_send_window = -1;
$tcp_timestamps_file = "/proc/sys/net/ipv4/tcp_timestamps";
$tcp_timestamps_info = "Timestamps (add 12 bytes to the TCP header)";
$tcp_timestamps = -1;
$tcp_selective_ack_file = "/proc/sys/net/ipv4/tcp_sack";
$tcp_selective_ack_info = "TCP selective acknowledgements";
$tcp_selective_ack = -1;
$tcp_large_windows_file = "/proc/sys/net/ipv4/tcp_window_scaling";
$tcp_large_windows_info = "Support for large TCP Windows";
$tcp_large_windows = -1;

# Programs argument management
#############################
%opts = ();
getopts("hvrt", \%opts);

$r_tag=($opts{r})?1:0;
$t_tag=($opts{t})?1:0;
$c_tag=($opts{t})?1:0;
if ($c_tag) {
	$r_tag=$t_tag=1;
}

if ($opts{v}) {
    # Version
    print "$program_name $program_version\n";
    exit(-1);
}

if ($opts{h} | !($r_tag | $t_tag | $c_tag)) {
    # Help
    print "$program_name $program_version\n";
    print "usage: tcptweak.pl [options]\n";
    print " -h: Print the command line help\n";
    print " -v: Print the program version\n";
    print " -r: Read and display the current system configuration\n";
    print " -t: Test the network\n";
    print " -c: Display the recommanded system configuration\n";    
    exit (-1);
}

# Main program
##############

# Read and display the current configuration
if ($r_tag) {
	print "Current system configuration\n";
	print "----------------------------\n";
	if (open(FILE, $default_tcp_receive_window_file)) {
		$default_tcp_receive_window = <FILE>;
	  	chop($default_tcp_receive_window);
	  	print "$default_tcp_receive_window_info (bytes) = $default_tcp_receive_window\n";
	  	close(FILE);
	}
	if (open(FILE, $max_tcp_receive_window_file)) {
		$max_tcp_receive_window = <FILE>;
	  	chop($max_tcp_receive_window);
	  	print "$max_tcp_receive_window_info (bytes) = $max_tcp_receive_window\n";
	  	close(FILE);
	}
	if (open(FILE, $default_tcp_send_window_file)) {
		$default_tcp_send_window = <FILE>;
	  	chop($default_tcp_send_window);
	  	print "$default_tcp_send_window_info (bytes) = $default_tcp_send_window\n";
	  	close(FILE);
	}
	if (open(FILE, $max_tcp_send_window_file)) {
		$max_tcp_send_window = <FILE>;
	  	chop($max_tcp_send_window);
	  	print "$max_tcp_send_window_info (bytes) = $max_tcp_send_window\n";
	  	close(FILE);
	}
	if (open(FILE, $tcp_timestamps_file)) {
		$tcp_timestamps = <FILE>;
	  	chop($tcp_timestamps);
	  	$tcp_timestamps = $tcp_timestamps?"YES":"NO";
	  	print "$tcp_timestamps_info = $tcp_timestamps\n";
	  	close(FILE);
	}
	if (open(FILE, $tcp_selective_ack_file)) {
		$tcp_selective_ack = <FILE>;
	  	chop($tcp_selective_ack);
	  	$tcp_selective_ack = $tcp_selective_ack?"YES":"NO";
	  	print "$tcp_selective_ack_info = $tcp_selective_ack\n";
	  	close(FILE);
	}
	if (open(FILE, $tcp_large_windows_file)) {
		$tcp_large_windows = <FILE>;
	  	chop($tcp_large_windows);
	  	$tcp_large_windows = $tcp_large_windows?"YES":"NO";
	  	print "$tcp_large_windows_info = $tcp_large_windows\n";
	  	close(FILE);
	}
	print "\n";
}

# Test the bandwidth
if ($t_tag) {
	# Test network
	print "Test your network\n";
	print "-----------------\n";
	local $| = 1;
	print "Please wait while testing the bandwidth...";
	getstore($url_speedtest, $tmp_folder."/tcptweak.dat");
	print "\r                                          \r";
	if (open(FILE, $tmp_folder."/tcptweak.dat")) {
		while (defined($line = <FILE>)) {
			if ($line =~ /Bande Passante (\d*)\./) {
				$bandwidth = $1;
				print "Bandwidth (Kbps) = $bandwidth\n";;
			}
		}
		close(FILE);
	}
	local $| = 1;
	print "Please wait while testing the delay...";
	$p = Net::Ping->new("tcp");
	$p->{port_num} = getservbyname("http", "tcp");
	$p->hires(1);
	@pingreturn = $p->ping($host_pingtest, 2);
	print "\r                                      \r";
	if ($pingreturn[0]) {
		$delay = int($pingreturn[1]*1000);
		print "Delay (ms) = $delay\n";
	}
	$p->close();
	local $| = 0;
	
	# Display BDP
	$bdp = int(($bandwidth/8)*$delay);
	print "Bandwidth Delay Product (bytes) = $bdp\n";
	print "\n";
}

# Display the recommanded system configuration
if ($c_tag) {
	print "Display the recommanded system configuration\n";
	print "--------------------------------------------\n";
	print "On Linux OS copy/paste in /etc/sysctl.conf file:\n";
	print "Configuration optimized for LAN access:\n";	
	print " net.core.rmem_default = 256960\n";
	print " net.core.rmem_max = 256960\n";
	print " net.core.wmem_default = 256960\n";
	print " net.core.wmem_max = 256960\n";
	print " net.ipv4.tcp_timestamps = 0\n";
	print " net.ipv4.tcp_sack = 1\n";
	print " net.ipv4.tcp_window_scaling = 1\n";
	print "Configuration optimized for the tested network:\n";	
	print " net.core.rmem_default = $bdp\n";
	print " net.core.rmem_max = $bdp\n";
	print " net.core.wmem_default = $bdp\n";
	print " net.core.wmem_max = $bdp\n";
	print " net.ipv4.tcp_timestamps = 0\n";
	print " net.ipv4.tcp_sack = 1\n";
	print " net.ipv4.tcp_window_scaling = 1\n";
}

# End of the program
####################
exit(0);
