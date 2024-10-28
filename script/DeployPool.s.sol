// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {LamboFactory} from "../src/LamboFactory.sol";
import {VirtualToken} from "../src/VirtualToken.sol";
import {LamboToken} from "../src/LamboToken.sol";
import {LaunchPadUtils} from "../src/Utils/LaunchPadUtils.sol";
import "forge-std/console2.sol";

contract DeployPool is Script {

    address FactoryAddress = 0x62f250CF7021e1CF76C765deC8EC623FE173a1b5;
    address vETH = 0x280A8955A11FcD81D72bA1F99d265A48ce39aC2E;

    // forge script script/DeployPool.s.sol:DeployPool --rpc-url https://eth.llamarpc.com --broadcast -vvvv --legacy
    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address multiSigAdmin = vm.addr(privateKey);

        vm.startBroadcast(privateKey);
        
        (address quoteToken, address pool) = LamboFactory(FactoryAddress).createLaunchPad(
            "LamboV2",
            "LamboV2",
            3.5 ether,
            address(vETH)
        );
        console2.log("QuoteToken address:", address(quoteToken));
        console2.log("Pool address:", address(pool));

        vm.stopBroadcast();
    }
}
