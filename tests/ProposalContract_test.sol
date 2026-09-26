// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "remix_tests.sol";
import "../contracts/ProposalContract.sol";
import "./Voter.sol";

contract ProposalContractTest {
    ProposalContract private proposals;
    Voter private v1;
    Voter private v2;
    Voter private v3;
    Voter private v4;

    function beforeEach() public {
        proposals = new ProposalContract();
        v1 = _newVoter();
        v2 = _newVoter();
        v3 = _newVoter();
        v4 = _newVoter();
    }

    function _newVoter() internal returns (Voter voter) {
        voter = new Voter();
        voter.init(proposals);
    }

    function _tryCreate(string memory title, uint256 limit) internal returns (bool) {
        try proposals.create(title, "description", limit) {
            return true;
        } catch {
            return false;
        }
    }

    function _trySetOwner(address newOwner) internal returns (bool) {
        try proposals.setOwner(newOwner) {
            return true;
        } catch {
            return false;
        }
    }

    // ---------- create ----------

    function createStoresTitleAndDescription() public {
        proposals.create("Budget 2027", "Approve the 2027 budget", 3);
        ProposalContract.Proposal memory p = proposals.getCurrentProposal();
        Assert.equal(p.title, "Budget 2027", "title should be stored");
        Assert.equal(p.description, "Approve the 2027 budget", "description should be stored");
        Assert.equal(p.total_vote_to_end, uint256(3), "vote limit should be stored");
        Assert.ok(p.is_active, "new proposal should be active");
        Assert.ok(!p.current_state, "new proposal should not be passing");
    }

    function onlyOwnerCanCreate() public {
        Assert.ok(!v1.tryCreate("Hijack"), "non-owner must not create proposals");
    }

    function createRejectsInvalidInput() public {
        Assert.ok(!_tryCreate("", 3), "empty title must be rejected");
        Assert.ok(!_tryCreate("Title", 0), "vote limit 0 must be rejected");
    }

    // ---------- vote ----------

    function supermajorityPassesAndEndsProposal() public {
        proposals.create("T", "D", 3);
        v1.vote(1);
        v2.vote(1);
        v3.vote(2);
        ProposalContract.Proposal memory p = proposals.getCurrentProposal();
        Assert.equal(p.approve, uint256(2), "two approve votes");
        Assert.equal(p.reject, uint256(1), "one reject vote");
        Assert.ok(p.current_state, "2 of 3 decisive votes is a two-thirds supermajority");
        Assert.ok(!p.is_active, "proposal should end when the vote limit is reached");
    }

    function simpleMajorityIsNotEnough() public {
        proposals.create("T", "D", 5);
        v1.vote(1);
        v2.vote(1);
        v3.vote(1);
        v4.vote(2);
        v4 = _newVoter();
        v4.vote(2);
        ProposalContract.Proposal memory p = proposals.getCurrentProposal();
        Assert.ok(!p.current_state, "3 of 5 is below two thirds");
        Assert.ok(!p.is_active, "proposal should have ended");
    }

    function abstentionCapBlocksProposal() public {
        proposals.create("T", "D", 10);
        v1.vote(1);
        v2.vote(0);
        Assert.ok(proposals.getCurrentProposal().current_state, "1 approve vs 1 pass: participation exactly half, passes");
        v3.vote(0);
        Assert.ok(!proposals.getCurrentProposal().current_state, "1 approve vs 2 pass: too many abstentions");
    }

    function noDecisiveVotesMeansNotPassing() public {
        proposals.create("T", "D", 10);
        v1.vote(0);
        Assert.ok(!proposals.getCurrentProposal().current_state, "only pass votes must not pass");
    }

    function cannotVoteTwice() public {
        proposals.create("T", "D", 5);
        Assert.ok(v1.tryVote(1), "first vote should succeed");
        Assert.ok(!v1.tryVote(1), "second vote must be rejected");
        Assert.ok(proposals.isVoted(address(v1)), "voter should be recorded");
        Assert.ok(!proposals.isVoted(address(v2)), "other address should not be recorded");
    }

    function ownerCannotVote() public {
        proposals.create("T", "D", 5);
        Assert.ok(proposals.isVoted(address(this)), "owner is pre-registered as voted");
    }

    function invalidChoiceIsRejected() public {
        proposals.create("T", "D", 5);
        Assert.ok(!v1.tryVote(3), "choice 3 must be rejected");
        Assert.ok(!proposals.isVoted(address(v1)), "rejected vote must not register the voter");
    }

    function cannotVoteOnInactiveProposal() public {
        Assert.ok(!v1.tryVote(1), "voting without any proposal must fail");
        proposals.create("T", "D", 1);
        v1.vote(1);
        Assert.ok(!v2.tryVote(1), "voting on an ended proposal must fail");
    }

    // ---------- terminateProposal ----------

    function ownerCanTerminate() public {
        proposals.create("T", "D", 5);
        Assert.ok(!v1.tryTerminate(), "non-owner must not terminate");
        proposals.terminateProposal();
        Assert.ok(!proposals.getCurrentProposal().is_active, "proposal should be inactive after termination");
        Assert.ok(!v1.tryVote(1), "voting after termination must fail");
    }

    function votersCanVoteAgainAfterTermination() public {
        proposals.create("First", "D", 5);
        v1.vote(1);
        proposals.terminateProposal();
        proposals.create("Second", "D", 5);
        Assert.ok(v1.tryVote(1), "voter list must be reset for the next proposal");
    }

    // ---------- history and ownership ----------

    function historyIsKept() public {
        proposals.create("First", "D", 1);
        v1.vote(1);
        proposals.create("Second", "D", 1);
        Assert.equal(proposals.getProposal(1).title, "First", "first proposal kept in history");
        Assert.equal(proposals.getProposal(2).title, "Second", "second proposal is current");
        Assert.ok(proposals.getProposal(1).current_state, "first proposal result kept");
    }

    function setOwnerTransfersControl() public {
        Assert.ok(!_trySetOwner(address(0)), "zero address must be rejected");
        proposals.setOwner(address(v1));
        Assert.ok(!_tryCreate("T", 3), "old owner must lose create rights");
        Assert.ok(v1.tryCreate("New owner"), "new owner can create");
        Assert.ok(!v1.tryVote(1), "new owner must not vote");
    }
}
