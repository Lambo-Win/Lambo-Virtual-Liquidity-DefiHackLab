// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {VirtualToken} from "../src/VirtualToken.sol";
import {LamboToken} from "../src/LamboToken.sol";
import {LaunchPadUtils} from "../src/Utils/LaunchPadUtils.sol";

import "forge-std/console2.sol";

contract DeployTokens is Script {
    // forge script script/0.deployTokens.s.sol --rpc-url https://base-rpc.publicnode.com --broadcast -vvvv --legacy
    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(privateKey);

        vm.startBroadcast(privateKey);
                
        LamboToken lamboTokenV2 = new LamboToken();
        console2.log("LamboToken address:", address(lamboTokenV2));
        
        VirtualToken vETH = new VirtualToken("vETH", "vETH", LaunchPadUtils.NATIVE_TOKEN);
        console2.log("VirtualToken address:", address(vETH));
        vm.stopBroadcast();

        console2.log("LamboToken address:", address(lamboTokenV2));
        console2.log("VirtualToken address:", address(vETH));
        
        vm.stopBroadcast();
    }
}
