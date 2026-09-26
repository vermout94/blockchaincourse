// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../contracts/ProposalContract.sol";

// Each Voter instance acts as a separate address that can vote on the proposal contract.
contract Voter {
    ProposalContract private target;

    // Set after deployment: remix-tests deploys every contract in the test file without constructor arguments.
    function init(ProposalContract _target) external {
        require(address(target) == address(0), "Already initialized");
        target = _target;
    }

    function vote(uint8 choice) external {
        target.vote(choice);
    }

    function tryVote(uint8 choice) external returns (bool) {
        try target.vote(choice) {
            return true;
        } catch {
            return false;
        }
    }

    function tryCreate(string calldata title) external returns (bool) {
        try target.create(title, "description", 3) {
            return true;
        } catch {
            return false;
        }
    }

    function tryTerminate() external returns (bool) {
        try target.terminateProposal() {
            return true;
        } catch {
            return false;
        }
    }
}
