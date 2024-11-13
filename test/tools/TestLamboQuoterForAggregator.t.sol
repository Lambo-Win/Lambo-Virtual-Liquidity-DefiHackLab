pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../../script/quoter/LamboQuoterForAggregator.sol";
import "../../script/quoter/LamboQuoterPathFor1inchV6.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract TestLamboQuoterForAggregator is Test {
    LamboQuoterForAggregator lamboQuoter;
    LamboQuoterPathFor1inchV6 lamboPathQuoter;

    function setUp() public {
        vm.createSelectFork("https://rpc.ankr.com/eth");

        lamboQuoter = new LamboQuoterForAggregator();
        lamboPathQuoter = new LamboQuoterPathFor1inchV6();
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

    function test1inchV6() public {
        address _1inchV6 = 0x111111125421cA6dc452d289314280a0f8842A65;
        address memePool = 0xdd8Cf12CDEEAc819bFBE73c6F2E4428A4EB44005;
        uint256 amountIn = 30 ether;
        uint256 minReturn = 0;

        bytes memory data = lamboPathQuoter.getBuyQuotePathThrough1inchV6(memePool, amountIn, minReturn);

        // bytes memory data2 = hex"89af926a00000000000000000000000000000000000000000000000000000016ad11459620000000000000000000000088e6a0c2ddd26feeb64f039a2c41296fcb3f56402080000000000000000000003416cf6c708da44db2624d63ea0aaef7113527c6ddc5239b";
        (bool success, bytes memory result) = payable(_1inchV6).call{value: amountIn}(data);
        require(success, "Call failed");
        uint256 amountOut = abi.decode(result, (uint256));
        console.log("Decoded Result:", amountOut);
        assert(amountOut > 0);

        address meme = 0xb16BE9D991FAF17E4f4A9628FcBdb9B06956BF43;
        uint256 memeBalance = IERC20(meme).balanceOf(address(this));
        console.log("Meme Balance:", memeBalance);
        assert(memeBalance == amountOut);


        // Meme -> ETH
        data = lamboPathQuoter.getSellQuotePathThrough1inchV6(memePool, memeBalance, minReturn);
        
        uint256 initialBalance = address(this).balance;
        console.log("Initial Balance:", initialBalance);

        deal(meme, address(this), memeBalance);
        IERC20(meme).approve(_1inchV6, memeBalance);
        (bool success1, bytes memory result1) = payable(_1inchV6).call(data);
        require(success1, "Call failed2");
        amountOut = abi.decode(result1, (uint256));
        console.log("Decoded Result2:", amountOut);
        assert(amountOut > 0);

        uint256 finalBalance = address(this).balance;
        console.log("Final Balance:", finalBalance);

        assert(finalBalance == initialBalance + amountOut);
    }

    receive() external payable {
        // This function allows the contract to receive Ether
    }
}
