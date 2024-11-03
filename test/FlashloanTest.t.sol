
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {IMorpho} from "@morpho/interfaces/IMorpho.sol";
import {IMorphoFlashLoanCallback} from "@morpho/interfaces/IMorphoCallbacks.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {console} from "forge-std/console.sol";

contract FlashloanTest is Test, IMorphoFlashLoanCallback {
    IMorpho private immutable MORPHO;
    address public MorphoVault = 0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb;
    address public WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    function setUp() public {
        vm.createSelectFork("https://rpc.ankr.com/eth");

    }

    function test_flashLoan() public {
        IMorpho(MorphoVault).flashLoan(WETH, 400 ether, "");
    }

    function onMorphoFlashLoan(uint256 assets, bytes calldata data) external {
        require(msg.sender == address(MorphoVault), "Caller is not MorphoVault");
        IERC20(WETH).approve(address(MorphoVault), assets);
    }

}