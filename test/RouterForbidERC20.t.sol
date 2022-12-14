// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "../src/forbid-erc20/RouterForbidERC20.sol";
import "../src/forbid-erc20/Forwarder.sol";

interface IYVault {
    function deposit(uint256) external;
    function balanceOf(address) external returns (uint256);
}

interface IUniswapV2Router02 {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

contract RouterForbidERC20Test is Test {
    using SafeERC20 for IERC20;

    IERC20 public constant TOKEN = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7); // USDT
    IERC20 public constant WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2); // WETH
    IUniswapV2Router02 public constant uniswapRouter02 = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IYVault public constant yVault = IYVault(0x2f08119C6f07c006695E079AAFc638b8789FAf18); // yUSDT

    RouterForbidERC20 public router;
    Forwarder public forwarder;
    address public user;
    address public hacker;
    address public hackerWallet;

    function setUp() external {
        user = makeAddr("user");
        hacker = makeAddr("hacker");
        hackerWallet = makeAddr("hackerWallet");

        forwarder = new Forwarder();
        router = new RouterForbidERC20(address(forwarder));

        // User approved router
        vm.startPrank(user);
        TOKEN.safeApprove(address(router), type(uint256).max);
        vm.stopPrank();
    }

    // Ensure the safu checker allows interacting with `to` which is not ERC20-compliant.
    function testZapUniswapV2(uint256 amount) external {
        IERC20 tokenIn = TOKEN;
        IERC20 tokenOut = WETH;
        amount = bound(amount, 1, tokenIn.totalSupply());
        deal(address(tokenIn), user, amount);

        // Prepare calldata for uniswap
        address[] memory path = new address[](2);
        path[0] = address(tokenIn);
        path[1] = address(tokenOut);
        bytes memory dataUniswap = abi.encodeWithSelector(
            uniswapRouter02.swapExactTokensForTokens.selector,
            amount, // amountIn
            1, // amountOutMin
            path, // path
            address(router), // to
            block.timestamp // deadline
        );

        // Set uniswapRouter02 to `to`
        vm.prank(user);
        router.zap(
            address(tokenIn), // tokenIn
            amount, // amountIn
            address(tokenOut), // tokenOut
            address(uniswapRouter02), // to
            dataUniswap
        );
        assertGt(tokenOut.balanceOf(address(user)), 0);
    }

    // Ensure the safu checker allows interacting with `to` which is ERC20-compliant token.
    function testZapYearn(uint128 amount) external {
        vm.assume(amount > 1);
        IERC20 tokenIn = TOKEN;
        deal(address(tokenIn), user, amount);

        // Prepare calldata for forwarder
        bytes memory dataForwarder = abi.encodeWithSelector(
            forwarder.forward.selector,
            address(tokenIn), // tokenIn
            address(yVault), // tokenOut
            address(yVault), // to
            abi.encodeWithSelector(yVault.deposit.selector, amount)
        );

        // Set forwarder to `to`
        vm.prank(user);
        router.zap(
            address(tokenIn), // tokenIn
            amount, // amountIn
            address(yVault), // tokenOut
            address(forwarder), // to
            dataForwarder
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
