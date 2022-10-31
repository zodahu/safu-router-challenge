// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "../IRouter.sol";
import "../libraries/ApproveHelper.sol";

contract RouterForbidERC20 is IRouter {
    using SafeERC20 for IERC20;

    bytes4 constant BALANCE_OF_SIG = bytes4(keccak256(bytes("balanceOf(address)")));

    address public immutable forwarder;

    constructor(address forwarder_) {
        forwarder = forwarder_;
    }

    /// @notice Forbid interacting ERC20 contract to protect user's approval.
    /// @dev Is there any token which hasn't balanceOf function but has other functions which can use user's allowances?
    function zap(address tokenIn, uint256 amountIn, address tokenOut, address to, bytes calldata data) external {
        // Safu?
        try IERC20(to).balanceOf(address(0)) {
            revert("Unsafu");
        } catch {
            // Do nothing
        }

        // Forwarder is used for interacting with ERC20-compliant contract using ethical data.
        if (to == forwarder) {
            // Pull tokenIn to forwarder
            IERC20(tokenIn).safeTransferFrom(msg.sender, forwarder, amountIn);

            // Execute forwarder
            (bool success, bytes memory result) = to.call(data);
            require(success && (result.length == 0 || abi.decode(result, (bool))), "FAIL_FORWARDER");
        } else {
            // Pull tokenIn
            IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);

            // Approve tokenIn
            ApproveHelper._tokenApprove(tokenIn, to, type(uint256).max);

            // Execute
            (bool success, bytes memory result) = to.call(data);
            require(success && (result.length == 0 || abi.decode(result, (bool))), "FAIL");

            // Approve zero
            ApproveHelper._tokenApproveZero(tokenIn, to);
        }

        // Push tokenIn and tokenOut
        if (IERC20(tokenIn).balanceOf(address(this)) > 0) {
            IERC20(tokenIn).safeTransfer(msg.sender, IERC20(tokenIn).balanceOf(address(this)));
        }
        if (IERC20(tokenOut).balanceOf(address(this)) > 0) {
            IERC20(tokenOut).safeTransfer(msg.sender, IERC20(tokenOut).balanceOf(address(this)));
        }
    }
}
