// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {VirtualToken} from "../src/VirtualToken.sol";
import {LamboToken} from "../src/LamboToken.sol";
import {LaunchPadUtils} from "../src/Utils/LaunchPadUtils.sol";
import {LamboFactory} from "../src/LamboFactory.sol";
import "forge-std/console2.sol";

contract OwnerTransfer is Script {
    // forge script script/2.ownerTransfer.s.sol:OwnerTransfer --rpc-url https://eth.llamarpc.com --broadcast -vvvv --legacy
    
    address FactoryAddress = 0x62f250CF7021e1CF76C765deC8EC623FE173a1b5;
    address vETH = 0x280A8955A11FcD81D72bA1F99d265A48ce39aC2E;

    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");

        address multiSignWallet = 0x9E1823aCf0D1F2706F35Ea9bc1566719B4DE54B8;

        vm.startBroadcast(privateKey);
        LamboFactory(FactoryAddress).transferOwnership(multiSignWallet);
        VirtualToken(vETH).transferOwnership(multiSignWallet);

        vm.stopBroadcast();


        
    }
}
