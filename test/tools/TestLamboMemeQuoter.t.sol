// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../script/quoter/LamboMemeQuoter.sol";

contract TestLamboMemeQuoter is Test {
    LamboMemeQuoter lamboMemeQuoter;

    function setUp() public {
        vm.createSelectFork("https://rpc.ankr.com/eth");
        lamboMemeQuoter = new LamboMemeQuoter();
    }

    function testGetUniswapPoolReserves() public {
        address[] memory pools = new address[](4);
        pools[0] = address(0xDa173E4212aE2477274621248bD15cC8455044cA); // 示例池地址
        pools[1] = address(0xDa173E4212aE2477274621248bD15cC8455044cA); // 示例池地址
        pools[2] = address(0xDa173E4212aE2477274621248bD15cC8455044cA); // 示例池地址
        pools[3] = address(0xDa173E4212aE2477274621248bD15cC8455044cA); // 示例池地址

        bytes memory result = lamboMemeQuoter.getUniswapPoolReserves(pools);
        uint256[] memory poolsReserve = abi.decode(result, (uint256[]));

        for (uint256 i = 0; i < pools.length; i++) {
            console.log(poolsReserve[i*2], poolsReserve[i*2+1]);
        }
    }
}
