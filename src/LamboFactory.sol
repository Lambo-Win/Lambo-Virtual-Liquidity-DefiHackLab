// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {LamboToken} from "./LamboToken.sol";
import {VirtualToken} from "./VirtualToken.sol";
import {LaunchPadUtils} from "./Utils/LaunchPadUtils.sol";
import {IPool} from "./interfaces/Uniswap/IPool.sol";
import {IPoolFactory} from "./interfaces/Uniswap/IPoolFactory.sol";
import {UniswapV2Library} from "./libraries/UniswapV2Library.sol";
import {LamboVEthRouter} from "./LamboVEthRouter.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract LamboFactory is Ownable {
    address public immutable lamboTokenImplementation;
    address public lamboRouter;
    mapping(address => bool) public whiteList;

    event TokenDeployed(address quoteToken);
    event PoolCreated(address virtualLiquidityToken, address quoteToken, address pool, uint256 virtualLiquidityAmount);
    event LiquidityAdded(address virtualLiquidityToken, address quoteToken, uint256 amountVirtualDesired, uint256 amountQuoteOptimal);

    constructor(address _lamboTokenImplementation) Ownable(msg.sender) {
        lamboTokenImplementation = _lamboTokenImplementation;
    }

    modifier onlyWhiteListed(address virtualLiquidityToken) {
        require(whiteList[virtualLiquidityToken], "virtualLiquidityToken is not in the whitelist");
        _;
    }

    function setLamboRouter(address _lamboRouter) public onlyOwner {
        lamboRouter = _lamboRouter;
    }

    function addVTokenWhiteList(address virtualLiquidityToken) public onlyOwner {
        whiteList[virtualLiquidityToken] = true;
    }

    function removeVTokenWhiteList(address virtualLiquidityToken) public onlyOwner {
        whiteList[virtualLiquidityToken] = false;
    }

    function _deployLamboToken(string memory name, string memory tickname) internal returns (address quoteToken) {
        // Create a deterministic clone of the LamboToken implementation
        quoteToken = Clones.clone(lamboTokenImplementation);

        // Initialize the cloned LamboToken
        LamboToken(quoteToken).initialize(name, tickname);

        emit TokenDeployed(quoteToken);
    }

    function createLaunchPad(
        string memory name,
        string memory tickname,
        uint256 virtualLiquidityAmount,
        address virtualLiquidityToken
    ) public onlyWhiteListed(virtualLiquidityToken) returns (address quoteToken, address pool) {
        quoteToken = _deployLamboToken(name, tickname);
        pool = IPoolFactory(LaunchPadUtils.UNISWAP_POOL_FACTORY_).createPair(virtualLiquidityToken, quoteToken);

        VirtualToken(virtualLiquidityToken).takeLoan(pool, virtualLiquidityAmount);
        IERC20(quoteToken).transfer(pool, LaunchPadUtils.TOTAL_AMOUNT_OF_QUOTE_TOKEN);

        // Directly minting to address(0) will cause Dexscreener to not display LP being burned
        // So, we have to mint to address(this), then send it to address(0).
        IPool(pool).mint(address(this));
        IERC20(pool).transfer(address(0), IERC20(pool).balanceOf(address(this)));

        emit PoolCreated(virtualLiquidityToken, quoteToken, pool, virtualLiquidityAmount);
    }

}
