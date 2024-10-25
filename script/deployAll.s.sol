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
    // forge script script/deployAll.s.sol --rpc-url https://base-rpc.publicnode.com --broadcast -vvvv --legacy
    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address multiSigAdmin = vm.addr(privateKey);

        vm.startBroadcast(privateKey);
                
        LamboToken lamboTokenV2 = new LamboToken();
        console2.log("LamboToken address:", address(lamboTokenV2));
        
        VirtualToken vETH = new VirtualToken("vETH", "vETH", LaunchPadUtils.NATIVE_TOKEN, multiSigAdmin);
        console2.log("VirtualToken address:", address(vETH));
        vm.stopBroadcast();

        vm.startBroadcast(privateKey);
        LamboFactory factory = new LamboFactory(
            multiSigAdmin,
            address(lamboTokenV2)
        );
        console2.log("LamboFactory address:", address(factory));

        LamboVEthRouter lamboRouter = new LamboVEthRouter(
            address(vETH),
            address(LaunchPadUtils.UNISWAP_POOL_FACTORY_)
        );
        console2.log("LamboVEthRouter address:", address(lamboRouter));

        vm.stopBroadcast();


        vm.startBroadcast(privateKey);
        vETH.updateFactory(address(factory), true);
        vETH.addToWhiteList(address(lamboRouter));
        vETH.addToWhiteList(multiSigAdmin);
        
        factory.setLamboRouter(address(lamboRouter));
        factory.addVTokenWhiteList(address(vETH));
        vm.stopBroadcast();
        
    }

}
