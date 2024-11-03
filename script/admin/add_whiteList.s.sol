
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {VirtualToken} from "../../src/VirtualToken.sol";
import "forge-std/console2.sol";

contract ApproveAdminMintVETH is Script {
    // forge script script/admin/add_whiteList.s.sol
    function run() external {
        // address admin = 0x9E1823aCf0D1F2706F35Ea9bc1566719B4DE54B8;
        // // 0x47ee03940000000000000000000000009e1823acf0d1f2706f35ea9bc1566719b4de54b8
        // bytes memory data = abi.encodeWithSignature("addToWhiteList(address)", admin);
        // console2.logBytes(data);

        // 0x1e580615
        // bytes memory data = abi.encodeWithSignature("cashIn()");
        // console2.logBytes(data);

        bytes memory data = abi.encodeWithSignature("updateCashOutFee(uint256)", 0);
        console2.logBytes(data);
        
    }


}