// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "../libraries/ApproveHelper.sol";

contract Forwarder {
    using SafeERC20 for IERC20;

    function forward(address tokenIn, address tokenOut, address to, bytes calldata data) external {
        // Approve tokenIn
        ApproveHelper._tokenApprove(tokenIn, to, type(uint256).max);

        // Execute
        (bool success, bytes memory result) = to.call(data);
        require(success && (result.length == 0 || abi.decode(result, (bool))), "FAIL_FORWARD");

        // Approve zero
        ApproveHelper._tokenApproveZero(tokenIn, to);

        // Push tokenIn and tokenOut
        if (IERC20(tokenIn).balanceOf(address(this)) > 0) {
            IERC20(tokenIn).safeTransfer(msg.sender, IERC20(tokenIn).balanceOf(address(this)));
        }
        if (IERC20(tokenOut).balanceOf(address(this)) > 0) {
            IERC20(tokenOut).safeTransfer(msg.sender, IERC20(tokenOut).balanceOf(address(this)));
        }
    }
}
