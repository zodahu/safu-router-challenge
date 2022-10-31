// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "../src/forbid-transfer-from/RouterForbidTransferFrom.sol";

interface IYVault {
    function deposit(uint256) external;
    function balanceOf(address) external returns (uint256);
}

contract RouterForbidTransferFromTest is Test {
    using SafeERC20 for IERC20;

    IERC20 public constant TOKEN = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7); // USDT
    IYVault public constant yVault = IYVault(0x2f08119C6f07c006695E079AAFc638b8789FAf18); // yUSDT

    RouterForbidTransferFrom public router;
    address public user;
    address public hacker;
    address public hackerWallet;

    function setUp() external {
        user = makeAddr("user");
        hacker = makeAddr("hacker");
        hackerWallet = makeAddr("hackerWallet");

        router = new RouterForbidTransferFrom();

        // User approved router
        vm.startPrank(user);
        TOKEN.safeApprove(address(router), type(uint256).max);
        vm.stopPrank();
    }

    // Ensure the safu checker allows interacting with `to` which is ERC20-compliant token.
    function testZapYearn(uint128 amount) external {
        vm.assume(amount > 1);
        IERC20 tokenIn = TOKEN;
        deal(address(tokenIn), user, amount);

        vm.prank(user);
        router.zap(
            address(tokenIn), // tokenIn
            amount, // amountIn
            address(yVault), // tokenOut
            address(yVault), // to
            abi.encodeWithSelector(yVault.deposit.selector, amount)
        );
        assertGt(yVault.balanceOf(address(user)), 0);
    }

    // Ensure hacker cannot execute malicious calldata
    function testCannotExploit(uint128 amount) external {
        vm.assume(amount > 0);
        IERC20 tokenIn = TOKEN;
        deal(address(tokenIn), user, amount);

        vm.startPrank(hacker);
        vm.expectRevert(bytes("Unsafu"));
        router.zap(
            address(tokenIn), // tokenIn is dummy
            0, // amountIn is dummy
            address(tokenIn), // tokenOut is dummy
            address(tokenIn), // to is the token to be stolen from user
            abi.encodeWithSelector(tokenIn.transferFrom.selector, user, hackerWallet, amount) // malicious calldata
        );
        vm.stopPrank();
    }
}
