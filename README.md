## Token Migration

This repository contains a smart contract suite that allows for the migration of ERC-20 tokens from one contract to another.

It also contains an implementation of a UUPS upgradeable proxy pattern ERC-20 token, which is intended to be the target token for the migration.

The migration contract is designed to be used in a two-way migration, but can be configured to be unidirectional by the deployer of the contract.

### Building This Code

You can build the contract suite with the following command:

```bash
forge build
```

### Running Unit Tests

You can run the unit tests with the following command:
```bash
forge test
```
