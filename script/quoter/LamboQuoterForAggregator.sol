pragma solidity ^0.8.20;

import {IQuoter} from "../../src/interfaces/Uniswap/IQuoter.sol";
import '../../src/libraries/UniswapV2Library.sol';

contract LamboQuoterForAggregator {
    address quoter = 0x5e55C9e631FAE526cd4B0526C4818D6e0a9eF0e3;
    address uniswapV3Pool = 0x39AA9fA48FaC66AEB4A2fbfF0A91aa072C6bb4bD;
    address uniswapV2Factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address public weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public veth = 0x280A8955A11FcD81D72bA1F99d265A48ce39aC2E;
    uint24 fee = 10000;

    function buyQuote(
        address meme,
        uint256 amountIn
    ) public view returns (uint256 amountOut) {
        // v3
        uint256 amountOut0 = _v3(true, amountIn);

        // v2
        amountOut = _v2(true, meme, amountOut0);
    }

    function sellQuote(
        address meme,
        uint256 amountIn
    ) public view returns (uint256 amountOut) {
        // v3
        uint256 amountOut0 = _v2(false, meme, amountIn);
        
        // v2
        amountOut = _v3(false, amountOut0);
    }

    function _v3(bool isBuy, uint256 amountIn) internal view returns(uint256 amountOut) {
        (amountOut, , , ) = IQuoter(quoter).quoteExactInputSingleWithPool(
            IQuoter.QuoteExactInputSingleWithPoolParams({
                tokenIn: isBuy? weth:veth,
                tokenOut: isBuy? veth:weth,
                amountIn: amountIn,
                fee: fee,
                pool: uniswapV3Pool,
                sqrtPriceLimitX96: 0
            })
        );
    }

    function _v2(
        bool isBuy,
        address meme,
        uint256 amountIn
    ) internal view returns(uint256 amountOut) {
        (uint256 reserveIn, uint256 reserveOut) = UniswapV2Library.getReserves(
            uniswapV2Factory, 
            isBuy? veth: meme, 
            isBuy? meme: veth
        );

        // Calculate the amount of quoteToken to be received
        amountOut = UniswapV2Library.getAmountOut(amountIn, reserveIn, reserveOut);
    }
}