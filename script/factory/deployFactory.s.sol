// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import "forge-std/console2.sol";

import {VirtualTokenFactory} from "./VirtualTokenFactory.sol";

contract DeployFactory is Script {
    // forge script script/factory/deployFactory.s.sol:DeployFactory --rpc-url https://eth.llamarpc.com --broadcast -vvvv --legacy

    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(privateKey);
        VirtualTokenFactory factory = new VirtualTokenFactory();
        vm.stopBroadcast();

        console2.log("VirtualTokenFactory address:", address(factory));
    }
}
