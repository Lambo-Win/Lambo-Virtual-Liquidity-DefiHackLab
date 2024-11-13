pragma solidity ^0.8.20;

import {IPool} from "../../src/interfaces/Uniswap/IPool.sol";
import {IQuoter} from "../../src/interfaces/Uniswap/IQuoter.sol";
import '../../src/libraries/UniswapV2Library.sol';
import '../../src/libraries/ProtocolLib.sol';
import '../../src/libraries/UniswapV2Library.sol';


contract LamboQuoterPathFor1inchV6 {
    using ProtocolLib for Address;

    address uniswapV3Pool = 0x39AA9fA48FaC66AEB4A2fbfF0A91aa072C6bb4bD;
    address public weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public veth = 0x280A8955A11FcD81D72bA1F99d265A48ce39aC2E;

    function getBuyQuotePathThrough1inchV6(
        address uniswapV2Pool,
        uint256 amountIn,
        uint256 minReturn
    ) public view returns (bytes memory data) {
    }

    function getSellQuotePathThrough1inchV6(
        address uniswapV2Pool,
        uint256 amountIn,
        uint256 minReturn
    ) public view returns (bytes memory data) {
    }


    
}