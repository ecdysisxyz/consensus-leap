// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/governance/Governor.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorStorage.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction.sol";
import "./CCIPSender.sol";

contract MockGovernor is Governor, GovernorCountingSimple, GovernorStorage, GovernorVotes, GovernorVotesQuorumFraction, CCIPSender {
    constructor(IVotes _token, address _router)
        Governor("MockGovernor")
        GovernorVotes(_token)
        GovernorVotesQuorumFraction(4)
        CCIPSender(_router)
    {}

    struct CCIPInfo {
        uint64 destinationChainSelector;
        address receiver;
    }

    mapping(uint256 proposalId => CCIPInfo) _CCIPInfos;

    function votingDelay() public pure override returns (uint256) {
        return 7200; // 1 day
    }

    function votingPeriod() public pure override returns (uint256) {
        return 50400; // 1 week
    }

    function quorum(uint256 blockNumber)
        public
        view
        override(Governor, GovernorVotesQuorumFraction)
        returns (uint256)
    {
        return super.quorum(blockNumber);
    }

    function propose(
        uint64 destinationChainSelector,
        address receiver,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public virtual returns (uint256) {
        uint256 proposalId = super.propose(targets, values, calldatas, description);
        
        _CCIPInfos[proposalId] = CCIPInfo({
            destinationChainSelector: destinationChainSelector,
            receiver: receiver
        });
        
        return proposalId;
    }

    function _propose(address[] memory targets, uint256[] memory values, bytes[] memory calldatas, string memory description, address proposer)
        internal
        override(Governor, GovernorStorage)
        returns (uint256)
    {
        return super._propose(targets, values, calldatas, description, proposer);
    }

    function state(uint256 /* proposalId*/) public view virtual override returns (ProposalState) {
        return ProposalState.Succeeded;
    }

    function _executeOperations(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 /*descriptionHash*/
    ) internal virtual override {     
        CCIPInfo memory ccipInfo = _CCIPInfos[proposalId];
        
        triggerCCIPSend(ccipInfo.destinationChainSelector, ccipInfo.receiver, targets,values,calldatas);
    }
}
