// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../interfaces/Curve/IStableNGPool.sol";

import {IMorpho} from "@morpho/interfaces/IMorpho.sol";
import {IMorphoFlashLoanCallback} from "@morpho/interfaces/IMorphoCallbacks.sol";

import {VirtualToken} from "../VirtualToken.sol";

import {IWETH} from "../interfaces/IWETH.sol";

import {IQuoter} from "../interfaces/Uniswap/IQuoter.sol";

import {IDexRouter} from "../interfaces/OKX/IDexRouter.sol";


contract LamboRebalanceOnUniwap is Initializable, UUPSUpgradeable, OwnableUpgradeable, IMorphoFlashLoanCallback {
    uint256 private constant _BUY_MASK = 1 << 255; // Mask for identifying if the swap is one-for-zero
    uint256 private constant _SELL_MASK = 0; // Mask for identifying if the swap is one-for-zero

    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    address public constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant veth = 0x280A8955A11FcD81D72bA1F99d265A48ce39aC2E;
    address public constant uniswapPool = 0x39AA9fA48FaC66AEB4A2fbfF0A91aa072C6bb4bD;
    address public constant morphoVault = 0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb;
    address public constant quoter = 0x5e55C9e631FAE526cd4B0526C4818D6e0a9eF0e3;

    address public constant OKXRouter = 0x7D0CcAa3Fac1e5A943c5168b6CEd828691b46B36;
    address public constant OKXTokenApprove = 0x40aA958dd87FC8305b97f2BA922CDdCa374bcD7f;
    uint24 public constant fee = 10000;

    function initialize(address _owner) public initializer {
        __Ownable_init(_owner);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function extractProfit(address to) external onlyOwner {
        uint256 balance = IERC20(weth).balanceOf(address(this));
        require(balance > 0, "No profit to extract");
        IERC20(weth).transfer(to, balance);
    }

    function rebalance(
        uint256 directionMask,
        uint256 amountIn,
        uint256 amountOut
    ) external {
        uint256 balanceBefore = IERC20(weth).balanceOf(address(this));
        
        bytes memory data = abi.encode(directionMask, amountIn, amountOut);
        IMorpho(morphoVault).flashLoan(weth, amountIn, data);
        
        uint256 balanceAfter = IERC20(weth).balanceOf(address(this));
        uint256 profit = balanceAfter - balanceBefore;
        require(profit > 0, "No profit made");
    }

    function onMorphoFlashLoan(uint256 assets, bytes calldata data) external {
        require(msg.sender == address(morphoVault), "Caller is not morphoVault");

        (uint256 directionMask, uint256 amountIn, uint256 amountOut) = abi.decode(data, (uint256, uint256, uint256));
        require(amountIn == assets, "Amount in does not match assets");

        uint256 _v3pool = uint256(uint160(uniswapPool)) | (directionMask);
        uint256[] memory pools = new uint256[](1);
        pools[0] = _v3pool;
        
        if (directionMask == _BUY_MASK) {
            _executeBuy(amountIn, pools);
        } else {
            _executeSell(amountIn, pools);
        }

        IERC20(weth).approve(address(morphoVault), assets);
    }

    function _executeBuy(uint256 amountIn, uint256[] memory pools) internal {
        IERC20(weth).approve(address(OKXTokenApprove), amountIn);
        uint256 uniswapV3AmountOut = IDexRouter(OKXRouter).uniswapV3SwapTo(uint256(uint160(address(this))), amountIn, 0, pools);
        VirtualToken(veth).cashOut(uniswapV3AmountOut);
        IWETH(weth).deposit{value: address(this).balance}();
    }

    function _executeSell(uint256 amountIn, uint256[] memory pools) internal {
        IWETH(weth).withdraw(amountIn);
        VirtualToken(veth).cashIn{value: amountIn}();
        IERC20(veth).approve(address(OKXTokenApprove), amountIn);
        IDexRouter(OKXRouter).uniswapV3SwapTo(uint256(uint160(address(this))), amountIn, 0, pools);
    }

    function previewRebalance() public view returns (
        bool result,
        uint256 directionMask,
        uint256 amountIn,
        uint256 amountOut
    ) {
        (uint256 wethBalance, uint256 vethBalance) = _getTokenBalances();
        uint256 targetBalance = (wethBalance + vethBalance) / 2;

        address tokenIn;
        address tokenOut;
        (tokenIn, tokenOut, amountIn) = _getTokenInOut(vethBalance, targetBalance, wethBalance);

        (amountOut, directionMask) = _getQuoteAndDirection(tokenIn, tokenOut, amountIn);

        result = amountOut > amountIn;
    }

    function _getTokenBalances() internal view returns (uint256 wethBalance, uint256 vethBalance) {
        wethBalance = IERC20(weth).balanceOf(uniswapPool);
        vethBalance = IERC20(veth).balanceOf(uniswapPool);
    }

    function _getTokenInOut(uint256 vethBalance, uint256 targetBalance, uint256 wethBalance) internal pure returns (address tokenIn, address tokenOut, uint256 amountIn) {
        if (vethBalance > targetBalance) {
            amountIn = vethBalance - targetBalance;

            tokenIn = weth;
            tokenOut = veth;
        } else {
            amountIn = wethBalance - targetBalance;

            tokenIn = veth;
            tokenOut = weth;
        }
    }

    function _getQuoteAndDirection(address tokenIn, address tokenOut, uint256 amountIn) internal view returns (uint256 amountOut, uint256 directionMask) {
        (amountOut, , , ) = IQuoter(quoter).quoteExactInputSingleWithPool(
            IQuoter.QuoteExactInputSingleWithPoolParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                amountIn: amountIn,
                fee: 10000,
                pool: uniswapPool,
                sqrtPriceLimitX96: 0
            })
        );

        directionMask = (tokenIn == weth) ? _BUY_MASK : _SELL_MASK;
    }

    receive() external payable {}
}
