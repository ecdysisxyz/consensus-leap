// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IAny2EVMMessageReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IAny2EVMMessageReceiver.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {IERC20} from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.0/contracts/token/ERC20/IERC20.sol";

contract MockCCIPRouter is IRouterClient {
    mapping(bytes32 messageId => Client.Any2EVMMessage message) messages;
    mapping(bytes32 messageId => address receiver) receivers;

    uint nonce;

    function ccipSend(
        uint64 destinationChainSelector,
        Client.EVM2AnyMessage calldata message
    ) external payable returns (bytes32) {
        nonce++;

        bytes32 messageId = keccak256(abi.encode(nonce));

        Client.Any2EVMMessage storage encodedMessage = messages[messageId];
        encodedMessage.messageId = messageId;
        encodedMessage.sender = abi.encode(msg.sender);
        encodedMessage.data = message.data;

        for (uint i; i < message.tokenAmounts.length; i++) {
            encodedMessage.destTokenAmounts.push(message.tokenAmounts[i]);
        }

        receivers[messageId] = abi.decode(message.receiver, (address));

        return messageId;
    }

    function ccipTransfer(bytes32 messageId) external {
        IAny2EVMMessageReceiver(receivers[messageId]).ccipReceive(
            messages[messageId]
        );
    }

    function isChainSupported(
        uint64 chainSelector
    ) external view returns (bool supported) {
        supported = true;
    }

    function getSupportedTokens(
        uint64 chainSelector
    ) external view returns (address[] memory tokens) {}

    function getFee(
        uint64 destinationChainSelector,
        Client.EVM2AnyMessage memory message
    ) external view returns (uint256 fee) {
        fee = 1;
    }
}
