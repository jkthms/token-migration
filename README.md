## Token Migration

This is a simple token migration contract that allows users to migrate their tokens from an old token to a new token.

The contract is designed to be used in a two-way migration, but can be configured to be unidirectional by the deployer of the contract.

**Note:** These contracts embed a fixed mint of 20% of the total supply of the old token to the deployer of the contract, therefore the new token will have a total supply of 120% of the old token. This can be configured by modifying the `ValiDAO` contract inside `src/Migration.sol`.

### Running This Code

You can build the contract suite with the following command:

```bash
forge build
```

You can run the unit tests with the following command:
```bash
forge test
```
