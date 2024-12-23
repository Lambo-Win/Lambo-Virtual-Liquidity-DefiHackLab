// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IQuoter} from "../interfaces/Uniswap/IQuoter.sol";
import {IMorpho} from "@morpho/interfaces/IMorpho.sol";
import {IWETH} from "../interfaces/IWETH.sol";
import {VirtualToken} from "../VirtualToken.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import {IUniswapV3Pool} from "../interfaces/Uniswap/IUniswapV3Pool.sol";
import {IMorphoFlashLoanCallback} from "@morpho/interfaces/IMorphoCallbacks.sol";

contract LamboRebalanceOnUniswapV3 is IMorphoFlashLoanCallback, AccessControl {
    using SafeERC20 for IERC20;


    address public immutable VETH;
    address public immutable VETHWETHPool;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant quoter = 0x5e55C9e631FAE526cd4B0526C4818D6e0a9eF0e3;
    address public constant morphoVault = 0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb;

    // price = 1, targetPrice = 1 * 2^96 = 2^96
    uint160 public constant targetPrice = 79228162514264337593543950336;

    // Set Operator
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    constructor(address _multiSign, address _operator, address _vETH, address _uniswap) {
        require(_multiSign != address(0), "Invalid _multiSign address");
        require(_vETH != address(0), "Invalid _vETH address");
        require(_uniswap != address(0), "Invalid _uniswap address");

        // MutlSign is the supper admin
        _grantRole(DEFAULT_ADMIN_ROLE, _multiSign);
        _grantRole(OPERATOR_ROLE, _operator);

        VETH = _vETH;
        VETHWETHPool = _uniswap;
    }

    modifier onlyVETHWETHPool() {
        require(msg.sender == VETHWETHPool, "Caller is not the VETHWETHPool");
        _;
    }

    modifier onlyMorphoVault() {
        require(msg.sender == morphoVault, "Caller is not the morphoVault");
        _;
    }

    function extractProfit(address to, address token) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 balance = IERC20(token).balanceOf(address(this));
        if (balance > 0) {
            IERC20(token).safeTransfer(to, balance);
        }
    }

    // rebalance the sqrtPrice to targetPrice (1:1)
    function rebalance(uint256 minReturn) external onlyRole(OPERATOR_ROLE) returns (uint256 ) {
        (bool zeroForOne, , address tokenIn, address tokenOut) = _getDirection();

        // choose a large amount to rebalance, amountOut < sellAmount naturally.
        uint256 sellAmount = IERC20(tokenOut).balanceOf(VETHWETHPool);

        bytes memory data = abi.encode(zeroForOne, sellAmount, minReturn, tokenIn, tokenOut);

        IMorpho(morphoVault).flashLoan(WETH, sellAmount, data);

        (uint160 currentSqrtPriceX96, , , , , , ) = IUniswapV3Pool(VETHWETHPool).slot0();
        require(currentSqrtPriceX96 == targetPrice, "rebalance target error");
    }

    function onMorphoFlashLoan(uint256 assets, bytes calldata data) external onlyMorphoVault {
        (bool zeroForOne, uint256 sellAmount, uint256 minReturn, address tokenIn, address tokenOut) = abi.decode(data, (bool, uint256, uint256, address, address));

        // loan `assets` amount of WETH
        // prepare the tokenIn first, if the tokenIn is VETH, convert to WETH
        if (tokenIn == VETH) {
            IWETH(WETH).withdraw(assets);
            VirtualToken(VETH).cashIn{value: assets}(assets);
        }

        IUniswapV3Pool(VETHWETHPool).swap(
            address(this),
            zeroForOne,
            int256(sellAmount),
            targetPrice,
            abi.encode(tokenIn, tokenOut, minReturn)
        );

        // Convert all VETH to WETH
        uint256 vETHLeftAmount = IERC20(VETH).balanceOf(address(this));
        if (vETHLeftAmount > 0) {
            VirtualToken(VETH).cashOut(vETHLeftAmount);
            IWETH(WETH).deposit{value: vETHLeftAmount}();
        }

        require(IERC20(WETH).approve(address(morphoVault), assets), "Approve failed");
    }

    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata _data
    ) external onlyVETHWETHPool {
        require(amount0Delta > 0 || amount1Delta > 0); // swaps entirely within 0-liquidity regions are not supported
        (address tokenIn, address tokenOut, uint256 minReturn) = abi.decode(_data, (address, address, uint256));

        (bool isExactInput, uint256 amountToPay, uint256 amountOut) = amount0Delta > 0
            ? (tokenIn < tokenOut, uint256(amount0Delta), uint256(-amount1Delta))
            : (tokenOut < tokenIn, uint256(amount1Delta), uint256(-amount0Delta));  

        require(amountOut >= minReturn, "Return Amount Is Not Enough");

        if (isExactInput) {
            pay(tokenIn, amountToPay);
        } else {
            pay(tokenOut, amountToPay);
        }

    }

    function pay(address token, uint256 value) internal {
        IERC20(token).transfer(VETHWETHPool, value);        
    }

    function _getDirection() internal view returns (bool zeroForOne, uint160 currentSqrtPriceX96, address tokenIn, address tokenOut) {
        address token0 = IUniswapV3Pool(VETHWETHPool).token0();
        address token1 = IUniswapV3Pool(VETHWETHPool).token1();
        (currentSqrtPriceX96, , , , , , ) = IUniswapV3Pool(VETHWETHPool).slot0();

        zeroForOne = false;
        // price: token1/token0
        if (token0 == WETH) {
            // token0: WETH, token1: VETH. 

            if (currentSqrtPriceX96 > targetPrice) {
                // VETH/WETH > 1,
                // tokenIn: WETH, tokenOut = VETH
                tokenIn = WETH;
                tokenOut = VETH;
                zeroForOne = true;
            } else {
                // WETH/VETH > 1,
                // tokenIn: VETH, tokenOut = WETH
                tokenIn = VETH;
                tokenOut = WETH;
            }
        } else {
             if (currentSqrtPriceX96 > targetPrice) {
                tokenIn = VETH;
                tokenOut = WETH;
                zeroForOne = true;
             } else {
                tokenIn = WETH;
                tokenOut = VETH;
             }
        }
    }

    receive() external payable {}

}