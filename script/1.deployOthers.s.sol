// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {VirtualToken} from "../src/VirtualToken.sol";
import {LamboFactory} from "../src/LamboFactory.sol";
import {LamboToken} from "../src/LamboToken.sol";
import {AggregationRouterV6, IWETH} from "../src/libraries/1inchV6.sol";
import {LamboVEthRouter} from "../src/LamboVEthRouter.sol";
import {LaunchPadUtils} from "../src/Utils/LaunchPadUtils.sol";

import "forge-std/console2.sol";

contract DeployAll is Script {
    // forge script script/1.deployOthers.s.sol:DeployAll --rpc-url https://eth.llamarpc.com --broadcast -vvvv --legacy
    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");

        LamboToken lamboTokenV2 = LamboToken(0x6B7e633FBDAf237bcFB8176BE04B0DD72dDa3B3A);
        VirtualToken vETH = VirtualToken(0x280A8955A11FcD81D72bA1F99d265A48ce39aC2E);

        vm.startBroadcast(privateKey);
        LamboFactory factory = new LamboFactory(address(lamboTokenV2));

        LamboVEthRouter lamboRouter = new LamboVEthRouter(
            address(vETH),
            address(LaunchPadUtils.UNISWAP_POOL_FACTORY_)
        );

        vm.stopBroadcast();

        vm.startBroadcast(privateKey);
        vETH.updateFactory(address(factory), true);
        vETH.addToWhiteList(address(lamboRouter));
        
        factory.setLamboRouter(address(lamboRouter));
        factory.addVTokenWhiteList(address(vETH));
        vm.stopBroadcast();

        console2.log("LamboFactory address:", address(factory));
        console2.log("LamboVEthRouter address:", address(lamboRouter));

    }

}
