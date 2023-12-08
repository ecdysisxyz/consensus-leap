pragma solidity ^0.8.19;

import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {OwnerIsCreator} from "@chainlink/contracts-ccip/src/v0.8/shared/access/OwnerIsCreator.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";

contract CCIPReceiverPlugin is CCIPReceiver, OwnerIsCreator {
    error SourceChainSenderNotAllowlisted(
        uint64 sourceChainSelector,
        address sender
    );

    error TransactionsFailed();

    error MessageAlreadyExecuted();

    event MessageReceived(
        bytes32 messageId,
        uint64 sourceChainSelector,
        address sender
    );

    event MessageExecuted(bytes32 messageId);

    mapping(uint64 => mapping(address => bool))
        public allowlistedSourceChainSenders;

    mapping(bytes32 => bytes) public receivedMessages;
    mapping(bytes32 => bool) public isMessageExecuted;

    bytes32[] public receivedMessageIds;

    constructor(address _router) CCIPReceiver(_router) {}

    modifier onlyAllowlisted(uint64 _sourceChainSelector, address _sender) {
        if (!allowlistedSourceChainSenders[_sourceChainSelector][_sender]) {
            revert SourceChainSenderNotAllowlisted(
                _sourceChainSelector,
                _sender
            );
        }
        _;
    }

    function allowlistSourceChainSender(
        uint64 _sourceChainSelector,
        address _sender,
        bool allowed
    ) external onlyOwner {
        allowlistedSourceChainSenders[_sourceChainSelector][_sender] = allowed;
    }

    function _ccipReceive(
        Client.Any2EVMMessage memory message
    )
        internal
        override
        onlyAllowlisted(
            message.sourceChainSelector,
            abi.decode(message.sender, (address))
        )
    {
        bytes32 messageId = message.messageId;

        receivedMessages[messageId] = message.data;
        receivedMessageIds.push(messageId);

        emit MessageReceived(
            message.messageId,
            message.sourceChainSelector,
            abi.decode(message.sender, (address))
        );
    }
}