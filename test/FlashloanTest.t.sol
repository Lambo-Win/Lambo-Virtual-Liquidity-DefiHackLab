// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {IMorpho} from "@morpho/interfaces/IMorpho.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {console} from "forge-std/console.sol";
import {LamboRebalanceOnUniwap} from "../src/rebalance/LamboRebalanceOnUniwap.sol";

import {IStableNGPool} from "../src/interfaces/Curve/IStableNGPool.sol";
import {VirtualToken} from "../src/VirtualToken.sol";

import {IStableNGFactory} from "../src/interfaces/Curve/IStableNGFactory.sol";

import {ILiquidityManager} from "../src/interfaces/Uniswap/ILiquidityManager.sol";

import {IDexRouter} from "../src/interfaces/OKX/IDexRouter.sol";

import {IQuoter} from "../src/interfaces/Uniswap/IQuoter.sol";

contract FlashloanTest is Test {
    IMorpho private immutable MORPHO;
    address public MorphoVault = 0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb;
    address public WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public VETH = 0x280A8955A11FcD81D72bA1F99d265A48ce39aC2E;
    address public CurvePool = 0x4a0cAF67c0399416b647Eb13E71B8205aBc15d35;
    address public multiSign = 0x9E1823aCf0D1F2706F35Ea9bc1566719B4DE54B8;
    address public OKXRouter = 0x7D0CcAa3Fac1e5A943c5168b6CEd828691b46B36;
    address public OKXTokenApprove = 0x40aA958dd87FC8305b97f2BA922CDdCa374bcD7f;
    address public uniswapPool = 0x39AA9fA48FaC66AEB4A2fbfF0A91aa072C6bb4bD;
    address public quoterAcdress = 0x5e55C9e631FAE526cd4B0526C4818D6e0a9eF0e3;
    address public newCurvePool;

    address public liquidityManager = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;

    uint256 private constant _ONE_FOR_ZERO_MASK = 1 << 255; // Mask for identifying if the swap is one-for-zero
    uint256 private constant _WETH_UNWRAP_MASK = 1 << 253; // Mask for identifying if WETH should be unwrapped to ETH

    LamboRebalanceOnUniwap public lamboRebalance;

    function setUp() public {
        vm.createSelectFork("https://rpc.ankr.com/eth", 21139730);
        // vm.createSelectFork("https://rpc.ankr.com/eth");
        lamboRebalance = new LamboRebalanceOnUniwap();
        lamboRebalance.initialize(multiSign);

        vm.startPrank(multiSign);
        VirtualToken(VETH).addToWhiteList(address(lamboRebalance));
        vm.stopPrank();
    }

    function test_uniswapChange_weth_to_veth() public {
        uint256 tokenId = 851481;

        // re-organize the liquidity
        vm.startPrank(multiSign);
        ILiquidityManager.DecreaseLiquidityParams memory params = ILiquidityManager.DecreaseLiquidityParams({
            tokenId: tokenId,
            liquidity: 10000 ether,
            amount0Min: 99 ether,
            amount1Min: 99 ether,
            deadline: block.timestamp + 24 hours
        });
        bytes memory data = abi.encodeWithSelector(ILiquidityManager.decreaseLiquidity.selector, params);
        (bool success, bytes memory returnData) = address(liquidityManager).call(data);
        require(success, "decreaseLiquidity call failed");
        (uint256 amount0, uint256 amount1) = abi.decode(returnData, (uint256, uint256));

        // console.log("amount0:", amount0);
        // console.log("amount1:", amount1);
        // console.logBytes(data);

        // 收集流动性减少后的代币
        ILiquidityManager.CollectParams memory collectParams = ILiquidityManager.CollectParams({
            tokenId: tokenId,
            recipient: multiSign,
            amount0Max: type(uint128).max,
            amount1Max: type(uint128).max
        });
        bytes memory collectData = abi.encodeWithSelector(ILiquidityManager.collect.selector, collectParams);
        (bool collectSuccess, bytes memory collectReturnData) = address(liquidityManager).call(collectData);
        require(collectSuccess, "collect call failed");
        (uint256 collectedAmount0, uint256 collectedAmount1) = abi.decode(collectReturnData, (uint256, uint256));

        console.logBytes(collectData);

        ILiquidityManager.MintParams memory mintParams0 = ILiquidityManager.MintParams({
            token0: VETH,
            token1: WETH,
            fee: 10000,
            tickLower: 200,
            tickUpper: 600,
            amount0Desired: collectedAmount0,
            amount1Desired: 0,
            amount0Min: 99 ether,
            amount1Min: 0,
            recipient: multiSign,
            deadline: block.timestamp + 24 hours
        });

        IERC20(VETH).approve(address(liquidityManager), mintParams0.amount0Desired);
        bytes memory mintData0 = abi.encodeWithSelector(ILiquidityManager.mint.selector, mintParams0);
        (bool mintSuccess0, bytes memory mintReturnData0) = address(liquidityManager).call(mintData0);
        (uint256 newTokenId0, uint128 newLiquidity0, uint256 newAmount0, uint256 newAmount1) = abi.decode(mintReturnData0, (uint256, uint128, uint256, uint256));
        require(mintSuccess0, "mint call failed");

        // console.log("newAmount0:", newAmount0);
        // console.log("newAmount1:", newAmount1);
        // console.logBytes(mintData0);

        ILiquidityManager.MintParams memory mintParams1 = ILiquidityManager.MintParams({
            token0: VETH,
            token1: WETH,
            fee: 10000,
            tickLower: -600,
            tickUpper: -200,
            amount0Desired: 0,
            amount1Desired: collectedAmount1 ,
            amount0Min: 0,
            amount1Min: 99 ether,
            recipient: multiSign,
            deadline: block.timestamp + 24 hours
        });

        IERC20(VETH).approve(address(liquidityManager), mintParams1.amount1Desired);
        bytes memory mintData1 = abi.encodeWithSelector(ILiquidityManager.mint.selector, mintParams1);
        (bool mintSuccess1, bytes memory mintReturnData1) = address(liquidityManager).call(mintData1);
        (uint256 newTokenId1, uint128 newLiquidity1, uint256 newAmount2, uint256 newAmount3) = abi.decode(mintReturnData1, (uint256, uint128, uint256, uint256));
        require(mintSuccess1, "mint call failed");

        // console.log("newAmount2:", newAmount2);
        // console.log("newAmount3:", newAmount3);

        // console.logBytes(mintData1);
      
        vm.stopPrank();

        // deal(WETH, address(this), 100 ether);
        // deal(VETH, address(this), 100 ether);

        // ILiquidityManager.MintParams memory mintParams2 = ILiquidityManager.MintParams({
        //     token0: VETH,
        //     token1: WETH,
        //     fee: 10000,
        //     tickLower: -200,
        //     tickUpper: 200,
        //     amount0Desired: 100 ether,
        //     amount1Desired: 100 ether,
        //     amount0Min: 0,
        //     amount1Min: 0,
        //     recipient: address(this),
        //     deadline: block.timestamp + 24 hours
        // });

        // IERC20(VETH).approve(address(liquidityManager), mintParams2.amount0Desired);
        // IERC20(WETH).approve(address(liquidityManager), mintParams2.amount1Desired);
        // (, , uint256 a0, uint256 a1) = ILiquidityManager(liquidityManager).mint(mintParams2);

        uint256 amount = 473 ether  - collectedAmount0 + 13 ether;
        uint256 _v3pool = uint256(uint160(uniswapPool)) | (_ONE_FOR_ZERO_MASK);
        uint256[] memory pools = new uint256[](1);
        pools[0] = _v3pool;
        uint256 amountOut0 = IDexRouter(OKXRouter).uniswapV3SwapTo{value: amount}(uint256(uint160(multiSign)), amount, 0, pools);

        // quote
        (bool rebalanceResult, uint256 directionMask, uint256 amountIn, uint256 amountOut) = lamboRebalance.previewRebalance();
        

        // Rebalance
        if(rebalanceResult) {
            lamboRebalance.rebalance(directionMask, amountIn, amountOut);

            uint256 wethBalanceAfterRebalance = IERC20(WETH).balanceOf(uniswapPool);
            uint256 vethBalanceAfterRebalance = IERC20(VETH).balanceOf(uniswapPool);
            console.log("WETH Balance after rebalance: ", wethBalanceAfterRebalance);
            console.log("vETH Balance after rebalance: ", vethBalanceAfterRebalance);
        }



        // vm.startPrank(multiSign);
        // uint256 initialBalance = IERC20(WETH).balanceOf(address(this));
        // lamboRebalance.extractProfit(address(this));
        // uint256 finalBalance = IERC20(WETH).balanceOf(address(this));
        // require(finalBalance > initialBalance, "Profit must be greater than 0");
        // vm.stopPrank();

    }

    function test_uniswapChange_vETH_to_wETH() public {
        uint256 tokenId = 851481;

        // re-organize the liquidity
        vm.startPrank(multiSign);
        ILiquidityManager.DecreaseLiquidityParams memory params = ILiquidityManager.DecreaseLiquidityParams({
            tokenId: tokenId,
            liquidity: 10000 ether,
            amount0Min: 99496712587905182896,
            amount1Min: 99496712587905182896,
            deadline: block.timestamp + 24 hours
        });
        bytes memory data = abi.encodeWithSelector(ILiquidityManager.decreaseLiquidity.selector, params);
        (bool success, bytes memory returnData) = address(liquidityManager).call(data);
        require(success, "decreaseLiquidity call failed");
        (uint256 amount0, uint256 amount1) = abi.decode(returnData, (uint256, uint256));

        // console.logBytes(data);

        // 收集流动性减少后的代币
        ILiquidityManager.CollectParams memory collectParams = ILiquidityManager.CollectParams({
            tokenId: tokenId,
            recipient: multiSign,
            amount0Max: type(uint128).max,
            amount1Max: type(uint128).max
        });
        bytes memory collectData = abi.encodeWithSelector(ILiquidityManager.collect.selector, collectParams);
        (bool collectSuccess, bytes memory collectReturnData) = address(liquidityManager).call(collectData);
        require(collectSuccess, "collect call failed");
        (uint256 collectedAmount0, uint256 collectedAmount1) = abi.decode(collectReturnData, (uint256, uint256));

        // console.logBytes(collectData);

        ILiquidityManager.MintParams memory mintParams0 = ILiquidityManager.MintParams({
            token0: VETH,
            token1: WETH,
            fee: 10000,
            tickLower: 200,
            tickUpper: 600,
            amount0Desired: collectedAmount0,
            amount1Desired: 0,
            amount0Min: 99496712587905182896,
            amount1Min: 0,
            recipient: multiSign,
            deadline: block.timestamp + 24 hours
        });

        IERC20(VETH).approve(address(liquidityManager), mintParams0.amount0Desired);
        bytes memory mintData0 = abi.encodeWithSelector(ILiquidityManager.mint.selector, mintParams0);
        (bool mintSuccess0, bytes memory mintReturnData0) = address(liquidityManager).call(mintData0);
        (uint256 newTokenId0, uint128 newLiquidity0, uint256 newAmount0, uint256 newAmount1) = abi.decode(mintReturnData0, (uint256, uint128, uint256, uint256));
        require(mintSuccess0, "mint call failed");

        // console.log("newAmount0:", newAmount0);
        // console.log("newAmount1:", newAmount1);
        // console.logBytes(mintData0);

        ILiquidityManager.MintParams memory mintParams1 = ILiquidityManager.MintParams({
            token0: VETH,
            token1: WETH,
            fee: 10000,
            tickLower: -600,
            tickUpper: -200,
            amount0Desired: 0,
            amount1Desired: collectedAmount1 ,
            amount0Min: 0,
            amount1Min: 99496712587905182896,
            recipient: multiSign,
            deadline: block.timestamp + 24 hours
        });

        IERC20(VETH).approve(address(liquidityManager), mintParams1.amount1Desired);
        bytes memory mintData1 = abi.encodeWithSelector(ILiquidityManager.mint.selector, mintParams1);
        (bool mintSuccess1, bytes memory mintReturnData1) = address(liquidityManager).call(mintData1);
        (uint256 newTokenId1, uint128 newLiquidity1, uint256 newAmount2, uint256 newAmount3) = abi.decode(mintReturnData1, (uint256, uint128, uint256, uint256));
        require(mintSuccess1, "mint call failed");

        // console.log("newAmount2:", newAmount2);
        // console.log("newAmount3:", newAmount3);

        // console.logBytes(mintData1);
      
        vm.stopPrank();

        deal(WETH, address(this), 100 ether);
        deal(VETH, address(this), 100 ether);

        ILiquidityManager.MintParams memory mintParams2 = ILiquidityManager.MintParams({
            token0: VETH,
            token1: WETH,
            fee: 10000,
            tickLower: -200,
            tickUpper: 200,
            amount0Desired: 100 ether,
            amount1Desired: 100 ether,
            amount0Min: 0,
            amount1Min: 0,
            recipient: address(this),
            deadline: block.timestamp + 24 hours
        });

        IERC20(VETH).approve(address(liquidityManager), mintParams2.amount0Desired);
        IERC20(WETH).approve(address(liquidityManager), mintParams2.amount1Desired);
        (, , uint256 a0, uint256 a1) = ILiquidityManager(liquidityManager).mint(mintParams2);

        uint256 amount = 473 ether  - collectedAmount0 + 13 ether;
        uint256 _v3pool = uint256(uint160(uniswapPool));
        uint256[] memory pools = new uint256[](1);
        pools[0] = _v3pool;

        deal(VETH, address(this), amount);
        IERC20(VETH).approve(address(OKXTokenApprove), amount);
        uint256 amountOut0 = IDexRouter(OKXRouter).uniswapV3SwapTo(uint256(uint160(multiSign)), amount, 0, pools);

        // console.log("amount :", amount);
        // console.log("amountOut0 :", amountOut0);

        // quote
        (bool rebalanceResult, uint256 directionMask, uint256 amountIn, uint256 amountOut) = lamboRebalance.previewRebalance();
        

        // Rebalance
        if(rebalanceResult) {
            lamboRebalance.rebalance(directionMask, amountIn, amountOut);

            uint256 wethBalanceAfterRebalance = IERC20(WETH).balanceOf(uniswapPool);
            uint256 vethBalanceAfterRebalance = IERC20(VETH).balanceOf(uniswapPool);
            console.log("WETH Balance after rebalance: ", wethBalanceAfterRebalance);
            console.log("vETH Balance after rebalance: ", vethBalanceAfterRebalance);
        }

        // vm.startPrank(multiSign);
        // uint256 initialBalance = IERC20(WETH).balanceOf(address(this));
        // lamboRebalance.extractProfit(address(this));
        // uint256 finalBalance = IERC20(WETH).balanceOf(address(this));
        // require(finalBalance > initialBalance, "Profit must be greater than 0");
        // vm.stopPrank();

    }

}