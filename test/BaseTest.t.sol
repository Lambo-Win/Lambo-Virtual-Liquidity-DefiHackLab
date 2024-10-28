// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {VirtualToken} from "../src/VirtualToken.sol";
import {LamboFactory} from "../src/LamboFactory.sol";
import {LamboToken} from "../src/LamboToken.sol";
import {AggregationRouterV6, IWETH} from "../src/libraries/1inchV6.sol";
import {LamboVEthRouter} from "../src/LamboVEthRouter.sol";
import {LaunchPadUtils} from "../src/Utils/LaunchPadUtils.sol";

contract BaseTest is Test {
    VirtualToken public vETH;
    LamboFactory public factory;
    AggregationRouterV6 public aggregatorRouter;
    LamboVEthRouter public lamboRouter;
    LamboToken public lamboTokenV2;

    address public multiSigAdmin = makeAddr("multiSigAdmin");

    function setUp() public virtual {
        // ankr eth mainnet
        vm.createSelectFork("https://rpc.ankr.com/eth");

        // ankr base mainnet
        // vm.createSelectFork("https://rpc.ankr.com/base");

        lamboTokenV2 = new LamboToken();

        vm.startPrank(multiSigAdmin);
        vETH = new VirtualToken("vETH", "vETH", LaunchPadUtils.NATIVE_TOKEN);

        factory = new LamboFactory(
            address(lamboTokenV2)
        );
        vm.stopPrank();
        


        aggregatorRouter = new AggregationRouterV6(IWETH(LaunchPadUtils.WETH));

        lamboRouter = new LamboVEthRouter(
            address(vETH),
            address(LaunchPadUtils.UNISWAP_POOL_FACTORY_)   
        );

        vm.startPrank(multiSigAdmin);
        vETH.updateFactory(address(factory), true);
        vETH.addToWhiteList(address(lamboRouter));
        
        factory.setLamboRouter(address(lamboRouter));
        factory.addVTokenWhiteList(address(vETH));
        vm.stopPrank();
    }
}
