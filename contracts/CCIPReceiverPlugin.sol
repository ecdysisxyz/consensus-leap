// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {OwnerIsCreator} from "@chainlink/contracts-ccip/src/v0.8/shared/access/OwnerIsCreator.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {ISafe} from "@safe-global/safe-core-protocol/contracts/interfaces/Accounts.sol";
import {ISafeProtocolManager} from "@safe-global/safe-core-protocol/contracts/interfaces/Manager.sol";
import {SafeTransaction, SafeProtocolAction} from "@safe-global/safe-core-protocol/contracts/DataTypes.sol";
import {BasePlugin, BasePluginWithStoredMetadata, PluginMetadata} from "./BasePlugin.sol";

contract CCIPReceiverPlugin is CCIPReceiver, OwnerIsCreator, BasePluginWithStoredMetadata {
    error SourceChainSenderNotAllowlisted(
        uint64 sourceChainSelector,
        address sender
    );

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

    address payable immutable multisend;

    constructor(address _router, address _multisend) CCIPReceiver(_router) BasePluginWithStoredMetadata(
        PluginMetadata({name: "CCIPReceiver Plugin", version: "1.0.0", requiresRootAccess: false, requiresPermissions: 1, iconUrl: "", appUrl: ""})
    ){
        multisend = payable(_multisend);
    }

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

    function executeFromPlugin(
        ISafeProtocolManager manager,
        ISafe safe,
        bytes32 messageId
    ) external returns (bytes[] memory data) {

        if (isMessageExecuted[messageId]) {
            revert MessageAlreadyExecuted();
        }
        isMessageExecuted[messageId] = true;

        SafeProtocolAction[] memory actions = new SafeProtocolAction[](1);
        actions[0] = SafeProtocolAction(multisend,0,receivedMessages[messageId]);
        SafeTransaction memory safetx = SafeTransaction({
            actions: actions,
            nonce: 0,
            metadataHash: metadataHash
        });

        data = manager.executeTransaction(safe, safetx);

        emit MessageExecuted(messageId);
    }

    function supportsInterface(bytes4 interfaceId) public pure virtual override(BasePlugin, CCIPReceiver) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}