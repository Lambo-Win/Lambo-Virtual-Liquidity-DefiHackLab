
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {LamboRebalanceOnUniswapV3} from "../src/rebalance/LamboRebalanceOnUniswapV3.sol";
import "forge-std/console.sol";

contract DeployLamboRebalanceOnUniswap is Script {
    // forge script script/3.deployRebalacne.s.sol:DeployLamboRebalanceOnUniswap --rpc-url https://eth.llamarpc.com --broadcast -vvvv --legacy
    function run() external {
        address multiSign;
        address operator;

        uint24 fee = 3000;
        address VETH = address(0);
        address uniswapPool = address(0);
        uint256 privateKey = vm.envUint("PRIVATE_KEY");

        address deployerAddress = vm.addr(privateKey);

        vm.startBroadcast(privateKey);

        LamboRebalanceOnUniswapV3 lamboRebalance = new LamboRebalanceOnUniswapV3(multiSign, operator, VETH, uniswapPool);

        console.log("LamboRebalanceOnUniwap address:", address(lamboRebalance));

        vm.stopBroadcast();
    }
}
