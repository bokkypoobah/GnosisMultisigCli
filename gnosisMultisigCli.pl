#!/usr/bin/perl -W

# ------------------------------------------------------------------------------
# Gnosis Multisig Command Line Interface
#
# STATUS: WIP
#
# Use with a local geth node
#
# https://github.com/bokkypoobah/GnosisMultisigCli
#
# Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2019. The MIT Licence.
# ------------------------------------------------------------------------------

use strict;
use Getopt::Long qw(:config no_auto_abbrev);
use Text::Wrap;
use JSON;
# use GnosisMultisigCli::Utils;
use GnosisMultisigCli::EthCommands;
use Data::Dumper;
# use Config::IniFiles;
#use bignum;

my $DEFAULTCONFIG = "config.pl";
my $GETHBINARY = "geth";
my $THEDAOADDRESS = "0xBB9bc244D798123fDe783fCc1C72d3Bb8C189413";
my ($ethDecimalPlaces, $ethNumberLength, $daoDecimalPlaces, $daoNumberLength) = (18, 27, 16, 25);

my $helptext = qq\
Gnosis Multisig CLI v0.90 Mar 04 2019. https://github.com/bokkypoobah/GnosisMultisigCli

Usage: $0 {command} [options]

Commands are:
  --listaccounts
  --listmultisigs
  --sendether
  --sendtoken
  --confirm
  --cancel
  --listproposals
  --sumsplits
  --vote
  --help

The --listaccounts command has additional optional parameters:
--account={account or id}        Use account number (e.g. 1) or address (e.g. 0xabc...)

The --listmultisigs command has additional optional parameters:
--multisig={address}             Use address (e.g. 0xabc...)

The --sendether command has additional optional parameters:
--to={address}             Use address (e.g. 0xabc...)
--amount={amount}          Amount in ETH
--decimals={decimals}

The --sendtoken command has additional optional parameters:
--to={address}             Use address (e.g. 0xabc...)
--tokens={tokens}          Amount in ETH
--weis={weis}
--decimals=

The --confirm command has additional optional parameters:
--sendether={address}             Use address (e.g. 0xabc...)

The --cancel command has additional optional parameters:
--sendether={address}             Use address (e.g. 0xabc...)

The --listaccounts command has no additional optional parameters other than the general
parameters listed below.

The --listproposals command has additional optional parameters:
  --proposalid={id}                Proposal id.
  --first={first proposal id}      First proposal id. Default '$GETHBINARY'.
  --last={last proposal id}        Last proposal id. Default last proposal id.
  --split={exclude|include|only}   Include splits. Default '$GETHBINARY'.
  --status={open|closed|both}      Proposal status. Default '$GETHBINARY'.
  --checkvotingstatus              Check your voting status for the proposals. Default off. This
                                   check uses eth.estimateGas() API call to determine if you have
                                   already voted.
  --checkpastvotes                 Retrieve your past voting history. Default off. Actual gas used
                                   will be reported in the (Est)Gas column

The --sumsplits command has no additional option.

The --vote command has the additional options:
  --account={account or id}        Use account number (e.g. 1) or address (e.g. 0xabc...)
  --proposalid={id}                Proposal id.
  --support={0|n|1|y}              Don't support (0 or n) or support (1 or y) proposal.
  --force                          Force a vote even when this tool reports that you have already voted.

There following options can be use generally:
  --config={config.pl}             Configuration file, defaults to $DEFAULTCONFIG in the current directory.
  --account={account or id}        Use account number (e.g. 1) or address (e.g. 0xabc...)
  --decimalplaces={decimal places) Number of decimal places. Default ETH '$GETHBINARY', DAO '$GETHBINARY'.
  --verbose                        Display what this script is doing.

HISTORY
  v0.90 Mar 04 2019 First version


REQUIREMENTS - This script runs on Linux and perhaps OSX. You can try it with Cygwin Perl, Strawberry Perl
or ActiveState Perl on Windows.

You will need to have geth (go Ethereum node software) on your path. geth is available from
https://github.com/ethereum/go-ethereum/releases .

geth is also packaged with the Ethereum Wallet (Mist) downloads. You will find the geth binary in the Ethereum
Wallet subdirectory under resources/node/geth/geth . Modify the GETHBINARY variable above to point to your geth path
if necessary.


NOTE - Only the --vote command will require you to enter your password to unlock your geth keystore. Check the code
below if you are concerned. The other --listaccounts and --listproposals commands do not require the unlocking of
your geth keystore.


WARNING - This script uses the same method as the Ethereum Wallet (Mist) to unlock your account in geth
when you are sending your vote to the Ethereum blockchain. Make sure that you start geth without the
--rpc option when using geth with this script. See the following URL about the security issues with this keystore
unlocking methodology:
http://ethereum.stackexchange.com/questions/3887/how-to-reduce-the-chances-of-your-ethereum-wallet-getting-hacked


The more frequently used commands follow:
  This help
    $0
  List accounts and display whether the account is blocked by votes in progress
    $0 --listaccounts
  List proposals (excluding splits, open proposals only)
    $0 --listproposals
  List proposals (excluding splits, open proposals only) and check voting status for your accounts
    $0 --listproposals --checkvotingstatus
  List proposals #2 and check voting status for your accounts
    $0 --listproposals --proposalid=2 --checkvotingstatus
  List open proposals and check voting status and past votes for your accounts
    $0 --listproposals --checkvotingstatus --checkpastvotes
  View split proposal statistics
    $0 --sumsplits
  Vote on proposal #2 from account #1 in your keystore, not supporting this vote
    $0 --vote --proposalid=2 --account=1 --support=0
  Vote on proposal #43 from account 0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa, supporting this vote
    $0 --vote --proposalid=43 --account=0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa --support=1


Donations happily accepted to Ethereum account 0x000001f568875F378Bf6d170B790967FE429C81A.

Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2019. The MIT Licence.

Stopped\;

my ($listAccounts, $listMultisigs, $listProposals, $sumSplits, $vote);
my ($proposalId, $first, $last, $split, $proposalStatus, $checkVotingStatus, $checkPastVotes, $account, $support, $force);
my ($configFile, $help, $verbose, $decimalPlaces);
my $status = 0;

GetOptions(
  "listaccounts"        => \$listAccounts,
  "listmultisigs"       => \$listMultisigs,
  "listproposals"       => \$listProposals,
  "sumsplits"           => \$sumSplits,
  "vote"                => \$vote,
  "config:s"            => \$configFile,
  "help"                => \$help,
  "verbose"             => \$verbose,
  "decimalPlaces:n"     => \$decimalPlaces,
  "proposalid:n"        => \$proposalId,
  "first:n"             => \$first,
  "last:n"              => \$last,
  "status:s"            => \$proposalStatus,
  "split:s"             => \$split,
  "checkVotingStatus"   => \$checkVotingStatus,
  "checkpastvotes"      => \$checkPastVotes,
  "account:s"           => \$account,
  "support:s"           => \$support,
  "force"               => \$force)
or die $helptext;

$configFile = $DEFAULTCONFIG
  unless defined $configFile;

printf scalar localtime . " config: '" . $configFile . "'\n"
  if defined $verbose;

my %config = do $configFile;
my $config_json = encode_json \%config;
print Dumper(\%config);
print $config_json;

exit;

if (defined $verbose) {
  $config{verbose} = $verbose;
}

if (defined $help) {
  die $helptext;
} elsif (defined $listAccounts) {
  $status = listAccounts($account);
} elsif (defined $listMultisigs) {
  $status = listMultisigs($account);
}

exit;


# ------------------------------------------------------------------------------
# List accounts
# ------------------------------------------------------------------------------
sub listAccounts {
  my ($account) = @_;

  my %accounts = GnosisMultisigCli::EthCommands::getAccounts(\%config, $account);
  print "  # Account                                 " . " " x $ethNumberLength . "ETH" .
    " " x ($daoNumberLength - 2) . "DAO The DAO transfer blocked by OPEN proposal?\n";
  my $separator = "--- ------------------------------------------ " . "-" x $ethNumberLength .
    " " . "-" x $daoNumberLength . " ------------------------------------------------------------\n";
  print $separator;
  for (my $i = 0; $i < scalar keys %accounts; $i++) {
    my $account = $accounts{$i};
    if ($account->{account} =~ /Total/) {
      print $separator;
      printf "%3d %-42s %*s %*s\n", $i, $account->{account}, $ethNumberLength, $account->{eth}, $daoNumberLength, $account->{dao};
    } else {
      my $blockString;
      if ($account->{blocked} != 0 && $account->{open} eq "true") {
        $blockString = "#" . $account->{blocked} . " OPEN until " . getTimeAndDuration($account->{votingDeadline});
      } else {
        $blockString = "";
      }
      printf "%3d %-42s %*s %*s %s\n", $i, $account->{account}, $ethNumberLength, $account->{eth}, $daoNumberLength, $account->{dao}, $blockString;
    }
  }
  return 0;
}


# ------------------------------------------------------------------------------
# List multsigs
# ------------------------------------------------------------------------------
sub listMultisigs {
  my ($account) = @_;

  my %accounts = GnosisMultisigCli::EthCommands::getMultisigs(\%config, $account);
  print "  # Account                                 " . " " x $ethNumberLength . "ETH" .
    " " x ($daoNumberLength - 2) . "DAO The DAO transfer blocked by OPEN proposal?\n";
  my $separator = "--- ------------------------------------------ " . "-" x $ethNumberLength .
    " " . "-" x $daoNumberLength . " ------------------------------------------------------------\n";
  print $separator;
  for (my $i = 0; $i < scalar keys %accounts; $i++) {
    my $account = $accounts{$i};
    if ($account->{account} =~ /Total/) {
      print $separator;
      printf "%3d %-42s %*s %*s\n", $i, $account->{account}, $ethNumberLength, $account->{eth}, $daoNumberLength, $account->{dao};
    } else {
      my $blockString;
      if ($account->{blocked} != 0 && $account->{open} eq "true") {
        $blockString = "#" . $account->{blocked} . " OPEN until " . getTimeAndDuration($account->{votingDeadline});
      } else {
        $blockString = "";
      }
      printf "%3d %-42s %*s %*s %s\n", $i, $account->{account}, $ethNumberLength, $account->{eth}, $daoNumberLength, $account->{dao}, $blockString;
    }
  }
  return 0;
}
