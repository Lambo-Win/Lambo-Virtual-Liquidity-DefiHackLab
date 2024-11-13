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

    enum Protocol {
        UniswapV2,
        UniswapV3,
        Curve
    }

    uint256 private constant _PROTOCOL_OFFSET = 253;
    uint256 private constant _WETH_UNWRAP_FLAG = 1 << 252;
    uint256 private constant _WETH_NOT_WRAP_FLAG = 1 << 251;
    uint256 private constant _USE_PERMIT2_FLAG = 1 << 250;

    uint256 private constant _UNISWAP_V2_ZERO_FOR_ONE_OFFSET = 247;
    uint256 private constant _UNISWAP_V2_ZERO_FOR_ONE_MASK = 0x01;
    uint256 private constant _UNISWAP_V3_ZERO_FOR_ONE_OFFSET = 247;

    function getBuyQuotePathThrough1inchV6(
        address uniswapV2Pool,
        uint256 amountIn,
        uint256 minReturn
    ) public view returns (bytes memory data) {
        data = _buyThrough1inchV6(uniswapV2Pool, minReturn);
    }

    function getSellQuotePathThrough1inchV6(
        address uniswapV2Pool,
        uint256 amountIn,
        uint256 minReturn
    ) public view returns (bytes memory data) {
        data = _sellThrough1inchV6(uniswapV2Pool, amountIn, minReturn);
    }

    function _sellThrough1inchV6(address uniswapV2Pool, uint256 amountIn, uint256 minReturn) internal view returns(bytes memory data) {
        // Meme -> vETH
        address token0 = IPool(uniswapV2Pool).token0();
        address token1 = IPool(uniswapV2Pool).token1();
        uint256 _directionMask = (token1 == veth)? uint256(1) << _UNISWAP_V2_ZERO_FOR_ONE_OFFSET : uint256(0);
        Address tokenIn = token1 == veth ? Address.wrap(uint256(uint160(token0))): Address.wrap(uint256(uint160(token1)));

        Address v2 = Address.wrap(
            uint256(uint160(uniswapV2Pool)) | 
            uint256(Protocol.UniswapV2) << _PROTOCOL_OFFSET |
            _directionMask
        );

        // vETH -> ETH
    
        Address v3 = Address.wrap(
            uint256(uint160(uniswapV3Pool)) |
            uint256(Protocol.UniswapV3) << _PROTOCOL_OFFSET |
            uint256(1) << _UNISWAP_V3_ZERO_FOR_ONE_OFFSET |
            _WETH_UNWRAP_FLAG
        );

        // Function: unoswap2(uint256 token,uint256 amount,uint256 minReturn,uint256 dex,uint256 dex2)
        data = abi.encodeWithSelector(
            bytes4(0x8770ba91), 
            tokenIn,
            amountIn,
            minReturn,
            v2,
            v3
        );
    }

    function _buyThrough1inchV6(address uniswapV2Pool, uint256 minReturn) internal view returns(bytes memory data) {
        // ETH -> vETH(UniswapV3) 
        Address v3 = Address.wrap(
            uint256(uint160(uniswapV3Pool)) |
            uint256(Protocol.UniswapV3) << _PROTOCOL_OFFSET
        );

        // vETH -> Meme
        address token0 = IPool(uniswapV2Pool).token0();
        address token1 = IPool(uniswapV2Pool).token1();
        uint256 _directionMask = (token0 == veth)? uint256(1) << _UNISWAP_V2_ZERO_FOR_ONE_OFFSET : uint256(0);
        Address v2 = Address.wrap(
            uint256(uint160(uniswapV2Pool)) | 
            uint256(Protocol.UniswapV2) << _PROTOCOL_OFFSET |
            _directionMask
        );    

        //  function ethUnoswap2(uint256 minReturn, Address dex, Address dex2) external payable returns(uint256 returnAmount) {
        data = abi.encodeWithSelector(
            bytes4(0x89af926a),
            minReturn,  // minReturn
            v3,         // v3
            v2          // 2
        );
    }
    
}