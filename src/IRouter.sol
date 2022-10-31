// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRouter {
    function zap(address tokenIn, uint256 amountIn, address tokenOut, address to, bytes calldata data) external;
}
