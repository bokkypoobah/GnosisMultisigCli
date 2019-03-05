use strict;
package GnosisMultisigCli::EthCommands;
use GnosisMultisigCli::Utils;
use JSON;
use Data::Dumper;

my $THEDAOADDRESS = "0xBB9bc244D798123fDe783fCc1C72d3Bb8C189413";
my ($ethDecimalPlaces, $ethNumberLength, $daoDecimalPlaces, $daoNumberLength) = (18, 27, 16, 25);


# ------------------------------------------------------------------------------
# Get the list of accounts from geth
# ------------------------------------------------------------------------------
sub getAccounts {
  my %config = %{$_[0]};
  my $account = $_[1];
  # my ($account) = @_;

  my $verbose = $config{verbose};
  my $config_json = encode_json \%config;

  $account = ""
    unless defined $account;
  printf scalar localtime . " getAccounts('$account')\n"
    if defined $verbose;
  my %result = ();
  my $command = qq/

loadScript("abis.js");

var config = $config_json;
console.log("gnosisMultisigAbi: " + JSON.stringify(gnosisMultisigAbi));
console.log("erc20Abi: " + JSON.stringify(erc20Abi));
console.log("config.GETHBINARY: " + config.GETHBINARY);
console.log("config: " + JSON.stringify(config));
\/\/ console.log("config_json: " + JSON.stringify(JSON.parse(\"$config_json\")));

var theDAOABIFragment = [{"type":"function","outputs":[{"type":"uint256","name":"balance"}],"name":"balanceOf","inputs":[{"type":"address","name":"_owner"}],"constant":true},{"constant":true,"inputs":[{"name":"","type":"address"}],"name":"blocked","outputs":[{"name":"","type":"uint256"}],"type":"function"},{"constant":true,"inputs":[{"name":"","type":"uint256"}],"name":"proposals","outputs":[{"name":"recipient","type":"address"},{"name":"amount","type":"uint256"},{"name":"description","type":"string"},{"name":"votingDeadline","type":"uint256"},{"name":"open","type":"bool"},{"name":"proposalPassed","type":"bool"},{"name":"proposalHash","type":"bytes32"},{"name":"proposalDeposit","type":"uint256"},{"name":"newCurator","type":"bool"},{"name":"yea","type":"uint256"},{"name":"nay","type":"uint256"},{"name":"creator","type":"address"}],"type":"function"}];
var theDAO = eth.contract(theDAOABIFragment).at("$THEDAOADDRESS");
var i = 0;
var totalEthers = 0;
var totalDaos = 0;
var votingDeadline;
var open;
var account = "$account";
if (account == "") {
  eth.accounts.forEach( function(e) {
    var ethers = web3.fromWei(eth.getBalance(e), "ether");
    var daos = theDAO.balanceOf(e)\/1e16;
    var blocked = theDAO.blocked(e);
    if (blocked > 0) {
      var proposal = theDAO.proposals(blocked);
      votingDeadline = proposal[3];
      open = proposal[4];
    } else {
      votingDeadline = 0;
      open = false;
    }
    totalEthers += parseFloat(ethers);
    totalDaos += parseFloat(daos);
    console.log(i++ + "\\t" + e + "\\t" + ethers.toFixed($ethDecimalPlaces) + "\\t" + daos.toFixed($daoDecimalPlaces) + "\\t" + blocked + "\\t" + votingDeadline + "\\t" + open);
  });
} else if (account.length < 10) {
  var acc = eth.accounts[account];
  var ethers = web3.fromWei(eth.getBalance(acc), "ether");
  var daos = theDAO.balanceOf(acc)\/1e16;
  var blocked = theDAO.blocked(acc);
  if (blocked > 0) {
    var proposal = theDAO.proposals(blocked);
    votingDeadline = proposal[3];
    open = proposal[4];
  } else {
    votingDeadline = 0;
    open = false;
  }
  totalEthers += parseFloat(ethers);
  totalDaos += parseFloat(daos);
  console.log(i++ + "\\t" + acc + "\\t" + ethers.toFixed($ethDecimalPlaces) + "\\t" + daos.toFixed($daoDecimalPlaces) + "\\t" + blocked + "\\t" + votingDeadline + "\\t" + open);
} else if (account.length > 40) {
  var ethers = web3.fromWei(eth.getBalance(account), "ether");
  var daos = theDAO.balanceOf(account)\/1e16;
  var blocked = theDAO.blocked(account);
  if (blocked > 0) {
    var proposal = theDAO.proposals(blocked);
    votingDeadline = proposal[3];
    open = proposal[4];
  } else {
    votingDeadline = 0;
    open = false;
  }
  totalEthers += parseFloat(ethers);
  totalDaos += parseFloat(daos);
  console.log(i++ + "\\t" + account + "\\t" + ethers.toFixed($ethDecimalPlaces) + "\\t" + daos.toFixed($daoDecimalPlaces) + "\\t" + blocked + "\\t" + votingDeadline + "\\t" + open);
}
console.log(i + "\\tTotal\\t" + totalEthers.toFixed($ethDecimalPlaces) + "\\t" + totalDaos.toFixed($daoDecimalPlaces) + "\\t" + 0 + "\\t" + 0 + "\\t" + false);
exit;
/;
  my @output = GnosisMultisigCli::Utils::executeGethCommand(\%config, $command);
  for my $line (@output) {
    if ($line =~ /\d+\t\S+\t\d+.*\t\d+/) {
      my ($i, $account, $ethers, $daos, $blocked, $votingDeadline, $open) = $line =~ /(\d+)\t(\S+)\t(\d+.*)\t(\d+.*)\t(\S+)\t(\S+)\t(\S+)/;
      printf scalar localtime . " " . $i . " " . $account . " " . $ethers . " " . $daos . " " . $blocked . " " . $votingDeadline . " " . $open . "\n"
        if defined $verbose;
      $result{$i}{account} = $account;
      $result{$i}{eth} = $ethers;
      $result{$i}{dao} = $daos;
      $result{$i}{blocked} = $blocked;
      $result{$i}{votingDeadline} = $votingDeadline;
      $result{$i}{open} = $open;
    }
  }
  return %result;
}


# ------------------------------------------------------------------------------
# Get the list of accounts from geth
# ------------------------------------------------------------------------------
sub getMultisigs {
  my %config = %{$_[0]};
  my $account = $_[1];
  # my ($account) = @_;

  my $verbose = $config{verbose};
  my $config_json = encode_json \%config;
  my $multisigs_json = to_json $config{MULTISIGS};
  print $multisigs_json;

  $account = ""
    unless defined $account;
  printf scalar localtime . " getAccounts('$account')\n"
    if defined $verbose;
  my %result = ();
  my $command = qq/

loadScript("abis.js");

var config = $config_json;
var multisigs = $multisigs_json;
\/\/ console.log("gnosisMultisigAbi: " + JSON.stringify(gnosisMultisigAbi));
\/\/ console.log("erc20Abi: " + JSON.stringify(erc20Abi));
\/\/ console.log("config.GETHBINARY: " + config.GETHBINARY);
console.log("config.MULTISIGS: " + JSON.stringify(config.MULTISIGS));
console.log("config.multisigs: " + JSON.stringify(multisigs));
\/\/ console.log("config: " + JSON.stringify(config));
\/\/ console.log("config_json: " + JSON.stringify(JSON.parse(\"$config_json\")));

var i = 0;
multisigs.forEach(function(e) {
  var multisig = eth.contract(gnosisMultisigAbi).at(e.address);
  var required = multisig.required();
  var transactionCount = multisig.transactionCount();
  var j;
  var noOwners = 0;
  var owners = [];
  for (j = 0; j < 50; j++) {
    var owner = multisig.owners(j);
    if (owner == "0x") {
      break;
    }
    var name = owner;
    var address = owner;
    Object.keys(e.owners).forEach(function(e1) {
      var address = e.owners[e1];
      if (address.toLowerCase() === owner.toLowerCase()) {
        name = e1;
      }
    });
    \/\/ console.log("multisigowner\\t" + e.address + "\\t" + name + "\\t" + address);
    owners.push({name: name, address: address});
    noOwners = parseInt(j) + 1;
  }
  console.log("multisig\\t" + i++ + "\\t" + e.code + "\\t" + e.name + "\\t" + e.address + "\\t" + noOwners + "\\t" +
    required + "\\t" + transactionCount + "\\t" + eth.getBalance(e.address));
  owners.forEach(function(e) {
    console.log("multisigowner\\t" + e.address + "\\t" + e.name);
  });
  for (j = Math.max(1, transactionCount-5); j < transactionCount; j++) {
    var tx = multisig.transactions(j);
    var dest = tx[0];
    var value = tx[1];
    var data = tx[2];
    var executed = tx[3];
    console.log("multisigtx\\t" + j + "\\t" + dest + "\\t" + value + "\\t" + data + "\\t" + executed);
    var k;
    for (k = 0; k < noOwners; k++) {
      var owner = multisig.owners(k);
      var confirmation = multisig.confirmations(j, owner);
      console.log("multisigtxconf\\t" + j + "\\t" + k + "\\t" + e.address + "\\t" + owner + "\\t" + confirmation);
    }
    \/\/ console.log(JSON.stringify(tx));
  }
});
exit;
/;
  my @output = GnosisMultisigCli::Utils::executeGethCommand(\%config, $command);
  for my $line (@output) {
    my @columns = split (/\t/, $line);
    if (scalar @columns > 0) {
      print $columns[0] . "\n";
      if ($columns[0] =~ /^multisig$/) {
        print Dumper(\@columns);
      }
    }
    #if ($line =~ /\d+\t\S+\t\d+.*\t\d+$/) {
    #  my ($i, $account, $ethers, $daos, $blocked, $votingDeadline, $open) = $line =~ /(\d+)\t(\S+)\t(\d+.*)\t(\d+.*)\t(\S+)\t(\S+)\t(\S+)/;
    #  printf scalar localtime . " " . $i . " " . $account . " " . $ethers . " " . $daos . " " . $blocked . " " . $votingDeadline . " " . $open . "\n"
    #    if defined $verbose;
    #  $result{$i}{account} = $account;
    #  $result{$i}{eth} = $ethers;
    #  $result{$i}{dao} = $daos;
    #  $result{$i}{blocked} = $blocked;
    #  $result{$i}{votingDeadline} = $votingDeadline;
    #  $result{$i}{open} = $open;
    #}
  }
  return %result;
}

1;
