// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {IERC20} from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.0/contracts/token/ERC20/IERC20.sol";

contract CCIPSender {
    enum PayFeesIn {
        Native,
        LINK
    }

    address immutable i_router;

    event MessageSent(bytes32 messageId);

    constructor(address router) {
        i_router = router;
    }

    function triggerCCIPSend(
        uint64 destinationChainSelector,
        address receiver,
        bytes calldata message
    ) public returns (bytes32 messageId) {
        Client.EVM2AnyMessage memory encodedMessage = Client.EVM2AnyMessage({
            receiver: abi.encode(receiver),
            data: message,
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: "",
            feeToken: address(0)
        });

        uint256 fee = IRouterClient(i_router).getFee(
            destinationChainSelector,
            encodedMessage
        );

        messageId = IRouterClient(i_router).ccipSend{value: fee}(
            destinationChainSelector,
            encodedMessage
        );

        emit MessageSent(messageId);
    }

}
