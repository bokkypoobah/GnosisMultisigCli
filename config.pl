GETHBINARY     => 'geth',

# Blank for local IPC, otherwise specify endpoint like 'rpc:http://localhost:8545'
GETHATTACH     => '',

TOKENS         => [
  {
    symbol       => 'DAI',
    name         => 'Dai Stablecoin v1.0',
    address      => '0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359',
    decimals     => '18'
  },
],

MULTISIGS      => [
  {
    code        => 'STATUS',
    name        => 'Status Multisig',
    address     => '0xA646E29877d52B9e2De457ECa09C724fF16D0a2B',
    owners      => {
    'Owner1'    => '0xdBD6ffD3CB205576367915Dd2f8De0aF7edcCeeF',
    'Owner2'    => '0x3Ac6Cb2CcFd8c8aAe3BA31D7ED44C20d241B16A4',
    'Owner3'    => 'MISMATCH - 0xBBF0cC1C63F509d48a4674e270D26d80cCAF6022',
    },
  },
],
