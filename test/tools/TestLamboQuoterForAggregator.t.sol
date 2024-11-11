pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../../script/quoter/LamboQuoterForAggregator.sol";

contract TestLamboQuoterForAggregator is Test {
    LamboQuoterForAggregator lamboQuoter;

    function setUp() public {
        vm.createSelectFork("https://rpc.ankr.com/eth");

        lamboQuoter = new LamboQuoterForAggregator();
    }

    function testBuyQuote() public {
        address meme = 0xb16BE9D991FAF17E4f4A9628FcBdb9B06956BF43;
        uint256 amountIn = 1 ether;
        uint256 amountOut = lamboQuoter.buyQuote(meme, amountIn);
        console.log("Buy Quote amountOut:", amountOut);
        assert(amountOut > 0);
    }

    function testSellQuote() public {
        address meme = 0xb16BE9D991FAF17E4f4A9628FcBdb9B06956BF43;
        uint256 amountIn = 1000000000 ether;
        uint256 amountOut = lamboQuoter.sellQuote(meme, amountIn);
        console.log("Sell Quote amountOut:", amountOut);
        assert(amountOut > 0);
    }
}
