// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-contracts/contracts/utils/Address.sol";

/// @notice Users approve tokens to Spender
contract Spender {
    using SafeERC20 for IERC20;

    address public immutable router;

    constructor(address router_) {
        router = router_;
    }

    /// @notice Transfer tokens from user to Router
    function transferFromERC20(address from, address token, uint256 amount) external {
        require(msg.sender == router, "Unsafu");

        IERC20(token).safeTransferFrom(from, router, amount);
    }
}
