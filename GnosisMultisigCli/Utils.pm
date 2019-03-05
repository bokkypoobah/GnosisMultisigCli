use strict;
package GnosisMultisigCli::Utils;

# ------------------------------------------------------------------------------
# Execute geth attach command with script
# ------------------------------------------------------------------------------
sub executeGethCommand {
  my %config = %{$_[0]};
  my $command = $_[1];

  # my ($gethBinary, $verbose, $command) = @_;
  printf scalar localtime . " Executing " . $command . "\n"
    if defined $config{verbose};
  my @result = `echo '$command' | $config{GETHBINARY} attach $config{GETHATTACH} 2>&1`;
  my $i = 0;
  for my $line (@result) {
    $i++;
    chomp $line;
    if (defined $config{verbose}) {
      printf scalar localtime . " line " . $i . ": " . $line . "\n";
    }
    if ($line =~ /Unable to attach to geth/) {
      die "Cannot attach to a 'geth [options] console' instance. Please start 'geth [options] console'.\nError returned " .
        $line . "\nStopped";
    } elsif ($line =~ /not found/) {
      die "The command '$config{GETHBINARY}' was not found on your path. Please adjust the \$GETHBINARY variable in $0.\nError returned " .
        $line . "\nStopped";
    }
  }
  return @result;
}

1;
