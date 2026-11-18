#!/usr/bin/perl
# Usage: run-with-timeout.pl <minutes> <command> [arguments...]
#
# Runs a command in its own process group and stops the whole group if it runs longer than
# <minutes>: SIGINT first, so xcodebuild can stop its test runner and save the result bundle,
# then SIGKILL after a grace period. Exits 124 on timeout, otherwise with the command's status.
# The group no longer gets terminal signals, so INT, TERM and HUP are forwarded to it.
use strict;
use warnings;
use POSIX qw(setpgid _exit);

my $grace_seconds = 30;
my $minutes = shift @ARGV;
die "usage: $0 <minutes> <command> [arguments...]\n"
  unless defined $minutes && $minutes =~ /^[1-9][0-9]*$/ && @ARGV;

my $pid = fork() // die "fork failed: $!\n";
if ($pid == 0) {
    setpgid(0, 0);
    exec { $ARGV[0] } @ARGV or _exit(127);
}
# Set it from both sides so the group exists before either process signals it.
setpgid($pid, $pid);

sub signal_group { kill $_[0], -$pid }

my $stopped = 0;
for my $signal (qw(INT TERM HUP)) {
    $SIG{$signal} = sub { $stopped = 1; signal_group($signal) };
}

my $timed_out = 0;
$SIG{ALRM} = sub {
    if ($timed_out) {
        signal_group('KILL');
        return;
    }
    $timed_out = 1;
    my $command = join ' ', grep { defined } @ARGV[0, 1];
    print STDERR "error: '$command' timed out after $minutes min; stopping its process group\n";
    signal_group('INT');
    alarm $grace_seconds;
};
alarm $minutes * 60;

my $status;
while (1) {
    if (waitpid($pid, 0) == $pid) {
        $status = $?;
        last;
    }
    die "waitpid failed: $!\n" unless $!{EINTR};
}
alarm 0;

# Leave nothing of a stopped run behind, such as children that outlived xcodebuild.
signal_group('KILL') if $timed_out || $stopped;
exit 124 if $timed_out;
exit($status & 127 ? 128 + ($status & 127) : $status >> 8);
