
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {LamboRebalanceOnUniwap} from "../src/rebalance/LamboRebalanceOnUniwap.sol";
import "forge-std/console.sol";

contract DeployLamboRebalanceOnUniswap is Script {
    // forge script script/3.deployRebalacne.s.sol:DeployLamboRebalanceOnUniswap --rpc-url https://eth.llamarpc.com --broadcast -vvvv --legacy
    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");

        address deployerAddress = vm.addr(privateKey);

        vm.startBroadcast(privateKey);

        LamboRebalanceOnUniwap lamboRebalance = new LamboRebalanceOnUniwap();
        lamboRebalance.initialize(deployerAddress);

        console.log("LamboRebalanceOnUniwap address:", address(lamboRebalance));

        vm.stopBroadcast();
    }
}
