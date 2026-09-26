# blockchaincourse

Proposal voting smart contract (Solidity ^0.8.18). The owner creates proposals with a title, a description and a vote limit; every other address can vote once per proposal with approve, reject or pass.

## Structure

| Path | Content |
|---|---|
| `contracts/ProposalContract.sol` | Proposal voting contract |
| `tests/ProposalContract_test.sol` | Remix unit tests (15 cases) |
| `tests/Voter.sol` | Test helper: each instance acts as a separate voter address |

## Contract overview

| Function | Access | Purpose |
|---|---|---|
| `create(title, description, total_vote_to_end)` | owner | Starts a new proposal and resets the voter list |
| `vote(choice)` | any address except owner, once per proposal | `0` = pass, `1` = approve, `2` = reject |
| `terminateProposal()` | owner | Ends the current proposal early |
| `setOwner(new_owner)` | owner | Transfers ownership |
| `isVoted(address)` | view | Has the address voted on the current proposal |
| `getCurrentProposal()` | view | Current proposal |
| `getProposal(number)` | view | Proposal by id (history) |

### State calculation

A proposal passes when both conditions hold:

1. **Participation:** approve + reject votes make up at least half of all votes cast. Pass votes count as abstentions.
2. **Supermajority:** approve votes reach at least two thirds of approve + reject.

Integer-only arithmetic (`approve * 3 >= decisive * 2`), no rounding.

| approve | reject | pass | Result |
|---|---|---|---|
| 2 | 1 | 0 | passes |
| 3 | 2 | 0 | fails (60 % < 2/3) |
| 1 | 0 | 1 | passes |
| 1 | 0 | 2 | fails (too many abstentions) |

### Changes compared to the course version

- `title` field in `Proposal` and in `create`
- Own state calculation (see above)
- `require` on empty title, vote limit `0`, invalid `choice` and zero address in `setOwner`
- Voter list is reset on `create` and `terminateProposal`; otherwise voters of a terminated proposal are blocked from the next one
- New owner is excluded from voting after `setOwner`
- Error messages on all `require` statements

## Testing in Remix

1. Open [remix.ethereum.org](https://remix.ethereum.org) and create the three files from this repository with the same paths (or use *Clone* with the repository URL).
2. Compiler tab: version `0.8.18` or newer, compile `ProposalContract.sol`.
3. Plugin manager: activate **Solidity Unit Testing**.
4. Select `tests/ProposalContract_test.sol` and click **Run**. Expected result: 15 passed, 0 failed.

Manual check in *Deploy & Run* (Remix VM): deploy with account 1, call `create`, switch to accounts 2 to 4 and call `vote`, read the result with `getCurrentProposal`.

## Deployment

| Network | Chain ID | Address |
|---|---|---|
| Ethereum Sepolia | 11155111 | _pending_ |

Goerli and Rinkeby are shut down; Sepolia is the current Ethereum testnet.
