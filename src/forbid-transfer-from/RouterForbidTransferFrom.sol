// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-contracts/contracts/utils/Address.sol";
import "../IRouter.sol";
import "../libraries/ApproveHelper.sol";

contract RouterForbidTransferFrom {
    using SafeERC20 for IERC20;

    bytes4 constant TRANSFER_FROM_SIG = bytes4(keccak256(bytes("transferFrom(address,address,uint256)")));

    /// @notice Forbid injecting transferFrom to data to protect user's approval.
    /// @dev Is there any token which has other functions consume user's allowances except transferFrom?
    /// @dev Is there any token which has other functions invoking transferFrom?
    function zap(address tokenIn, uint256 amountIn, address tokenOut, address to, bytes calldata data) external {
        // Safu?
        bytes4 sig = bytes4(data[:4]);
        require(sig != TRANSFER_FROM_SIG, "Unsafu");

        require(Address.isContract(to), "NOT_CONTRACT");

        // Pull tokenIn
        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);

        // Approve tokenIn
        ApproveHelper._tokenApprove(tokenIn, to, type(uint256).max);

        // Execute
        (bool success,) = to.call(data);
        require(success, "FAIL");

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
