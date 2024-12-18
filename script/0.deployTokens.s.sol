// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {VirtualToken} from "../src/VirtualToken.sol";
import {LamboToken} from "../src/LamboToken.sol";
import {LaunchPadUtils} from "../src/Utils/LaunchPadUtils.sol";

import "forge-std/console2.sol";

contract DeployTokens is Script {
    // forge script script/0.deployTokens.s.sol:DeployTokens --rpc-url https://eth.llamarpc.com --broadcast -vvvv --legacy --verify --etherscan-api-key RTJCFXFDI87EIYGXH8BT1RJZRQ6IY85N3Q
    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(privateKey);
        LamboToken lamboTokenV2 = new LamboToken();
        VirtualToken vETH = new VirtualToken("VETH", "VETH", LaunchPadUtils.NATIVE_TOKEN);
        vm.stopBroadcast();

        console2.log("LamboToken address:", address(lamboTokenV2));
        console2.log("VirtualToken address:", address(vETH));
        
    }
}
