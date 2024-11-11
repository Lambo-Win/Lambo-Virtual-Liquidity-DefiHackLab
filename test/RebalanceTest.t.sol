
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {LamboRebalanceOnUniwap} from "../src/rebalance/LamboRebalanceOnUniwap.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {VirtualToken} from "../src/VirtualToken.sol";
import {IDexRouter} from "../src/interfaces/OKX/IDexRouter.sol";
import {console} from "forge-std/console.sol";


contract RebalanceTest is Test {
    LamboRebalanceOnUniwap public lamboRebalance;
    address public multiSign = 0x9E1823aCf0D1F2706F35Ea9bc1566719B4DE54B8;
    address public WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public VETH = 0x280A8955A11FcD81D72bA1F99d265A48ce39aC2E;
    address public uniswapPool = 0x39AA9fA48FaC66AEB4A2fbfF0A91aa072C6bb4bD;
    uint256 private constant _ONE_FOR_ZERO_MASK = 1 << 255; // Mask for identifying if the swap is one-for-zero
    address public OKXTokenApprove = 0x40aA958dd87FC8305b97f2BA922CDdCa374bcD7f;

    address public OKXRouter = 0x7D0CcAa3Fac1e5A943c5168b6CEd828691b46B36;

    function setUp() public {
        vm.createSelectFork("https://rpc.ankr.com/eth");

        lamboRebalance = new LamboRebalanceOnUniwap();
        lamboRebalance.initialize(address(this));

        vm.startPrank(multiSign);
        VirtualToken(VETH).addToWhiteList(address(lamboRebalance));
        vm.stopPrank();
    }

    function test_rebalance_from_weth_to_veth() public {   
        uint256 amount = 384 ether;
        uint256 _v3pool = uint256(uint160(uniswapPool)) | (_ONE_FOR_ZERO_MASK);
        uint256[] memory pools = new uint256[](1);
        pools[0] = _v3pool;
        uint256 amountOut0 = IDexRouter(OKXRouter).uniswapV3SwapTo{value: amount}(uint256(uint160(multiSign)), amount, 0, pools);

        (bool result, uint256 directionMask, uint256 amountIn, uint256 amountOut) = lamboRebalance.previewRebalance();
        require(result, "Rebalance not profitable");

        lamboRebalance.rebalance(directionMask, amountIn, amountOut);

        uint256 initialBalance = IERC20(WETH).balanceOf(address(this));
        lamboRebalance.extractProfit(address(this));
        uint256 finalBalance = IERC20(WETH).balanceOf(address(this));
        require(finalBalance > initialBalance, "Profit must be greater than 0");

        console.log("profit :", finalBalance - initialBalance);
    }

    function test_rebalance_from_veth_to_weth() public {   
        uint256 amount = 384 ether;
        uint256 _v3pool = uint256(uint160(uniswapPool));
        uint256[] memory pools = new uint256[](1);
        pools[0] = _v3pool;

        deal(VETH, address(this), amount);
        IERC20(VETH).approve(address(OKXTokenApprove), amount);
        uint256 amountOut0 = IDexRouter(OKXRouter).uniswapV3SwapTo(uint256(uint160(multiSign)), amount, 0, pools);

        (bool result, uint256 directionMask, uint256 amountIn, uint256 amountOut) = lamboRebalance.previewRebalance();
        require(result, "Rebalance not profitable");

        lamboRebalance.rebalance(directionMask, amountIn, amountOut);

        uint256 initialBalance = IERC20(WETH).balanceOf(address(this));
        lamboRebalance.extractProfit(address(this));
        uint256 finalBalance = IERC20(WETH).balanceOf(address(this));
        require(finalBalance > initialBalance, "Profit must be greater than 0");

        console.log("profit :", finalBalance - initialBalance);
    }
    

}
