

pragma solidity ^0.8.20;

import {IPool} from "../../src/interfaces/Uniswap/IPool.sol";

contract LamboMemeQuoter {
    function getUniswapPoolReserves(address[] memory pools) public view returns (bytes memory) {
        uint256[] memory reserves = new uint256[](pools.length * 2);
        
        for (uint256 i = 0; i < pools.length; i++) {
            (uint256 reserveA, uint256 reserveB, ) = IPool(pools[i]).getReserves();
            reserves[i*2] = reserveA;
            reserves[i*2 + 1] = reserveB;
        }
        return abi.encode(reserves);
    }
}

