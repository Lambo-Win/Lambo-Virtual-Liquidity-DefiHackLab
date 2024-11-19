import {BaseTest} from "./BaseTest.t.sol";
import {LaunchPadUtils} from "../src/Utils/LaunchPadUtils.sol";
import {IStableNGFactory} from "../src/interfaces/Curve/IStableNGFactory.sol";
import {IUniswapV2Router01} from "../src/interfaces/Uniswap/IUniswapV2Router01.sol";
import {IStableNGPool} from "../src/interfaces/Curve/IStableNGPool.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregationRouterV6, IWETH} from "../src/libraries/1inchV6.sol";
import "forge-std/console2.sol";

contract GeneralTest is BaseTest {

    function setUp() public override {
        super.setUp();
    }

    function test_changeOwnerToMultisigner() public {
        address NewMultiSigAdmin = 0x9E1823aCf0D1F2706F35Ea9bc1566719B4DE54B8;
        vm.startPrank(multiSigAdmin);
        vETH.transferOwnership(NewMultiSigAdmin);
        vm.stopPrank();
    }

    function test_lamboFactoryChangeOwner() public {
        address NewMultiSigAdmin = 0x9E1823aCf0D1F2706F35Ea9bc1566719B4DE54B8;
        
        vm.startPrank(multiSigAdmin);
        factory.transferOwnership(NewMultiSigAdmin);
        vm.stopPrank();

        // check owner
        vm.startPrank(NewMultiSigAdmin);
        factory.removeVTokenWhiteList(address(vETH));
        factory.addVTokenWhiteList(address(vETH));
        factory.setLamboRouter(address(lamboRouter));
        (address quoteToken, address pool) = factory.createLaunchPad("LamboToken", "LAMBO", 10 ether, address(vETH));
        vm.stopPrank();
    }

    function test_createLaunchPad_exceeding_100ETH() public {

        vm.expectRevert("Loan limit per block exceeded");
        factory.createLaunchPad("LamboToken", "LAMBO", 300 ether + 1, address(vETH));

        vm.roll(block.number + 1);

        factory.createLaunchPad("LamboToken", "LAMBO", 300 ether, address(vETH));
        
    }
    
    // vETH <-> Meme into Uniswap
    function test_createLaunchPad_with_virtual_token_and_buy_sell() public {
        (address quoteToken, address pool) = factory.createLaunchPad("LamboToken", "LAMBO", 10 ether, address(vETH));
        
        uint256 amountQuoteOut = lamboRouter.getBuyQuote(quoteToken, 10 ether);
        uint256 gasStart = gasleft();
        uint256 amountOut = lamboRouter.buyQuote{value: 10 ether}(quoteToken, 10 ether, 0);
        uint256 gasUsed = gasStart - gasleft();

        require(amountOut == amountQuoteOut, "getBuyQuote error");

        // 123544
        console2.log("BuyQuote Gas Used: ", gasUsed);
        vm.assertEq(IERC20(quoteToken).balanceOf(address(this)), amountOut);

        IERC20(quoteToken).approve(address(lamboRouter), amountOut);
        
        amountQuoteOut = lamboRouter.getSellQuote(quoteToken, amountOut);
        gasStart = gasleft();
        uint256 amountXOut = lamboRouter.sellQuote(quoteToken, amountOut, 0);
        gasUsed = gasStart - gasleft();

        console2.log("amountQuoteOut: ", amountQuoteOut);
        console2.log("amountXOut: ", amountXOut);
        require(amountQuoteOut == amountXOut);
        // 111287
        console2.log("SellQuote Gas Used: ", gasUsed);

        // nearly 0.003
        console2.log("amountXOut: ", amountXOut);
        
    }

        // vETH <-> Meme into Uniswap
    function test_createLaunchPadWithInitalBuy() public {
        (address quoteToken, address pool, uint256 amountYOut) = lamboRouter.createLaunchPadAndInitialBuy{value: 10 ether}(address(factory), "LamboToken", "LAMBO", 10 ether, 10 ether);
  
        console2.log("amountYOut: ", amountYOut);
        vm.assertEq(IERC20(quoteToken).balanceOf(address(this)), amountYOut);
        IERC20(quoteToken).approve(address(lamboRouter), amountYOut);
        
        uint256 gasStart = gasleft();
        uint256 amountXOut = lamboRouter.sellQuote(quoteToken, amountYOut, 0);
        uint256 gasUsed = gasStart - gasleft();
        // 111287
        console2.log("SellQuote Gas Used: ", gasUsed);

        // nearly 0.003
        console2.log("amountXOut: ", amountXOut);
    }

    function test_cashIn_and_buyQuote() public {
        (address quoteToken, address pool) = factory.createLaunchPad("LamboToken", "LAMBO", 10 ether, address(vETH));
        uint256 amountQuoteOut = lamboRouter.getBuyQuote(quoteToken, 10 ether);
        uint256 amountOut = lamboRouter.buyQuote{value: 10 ether}(quoteToken, 10 ether, 0);
        
        // require(amountOut == amountQuoteOut, "getBuyQuote error");
    }

    function test_cashIn_and_sellQuote() public {
        (address quoteToken, address pool) = factory.createLaunchPad("LamboToken", "LAMBO", 10 ether, address(vETH));
        uint256 amountQuoteOut = lamboRouter.getBuyQuote(quoteToken, 10 ether);
        uint256 amountOut = lamboRouter.buyQuote{value: 10 ether}(quoteToken, 10 ether, 0);
        require(amountOut == amountQuoteOut, "getBuyQuote error");

        IERC20(quoteToken).approve(address(lamboRouter), amountOut);
        lamboRouter.sellQuote(quoteToken, amountOut, 0);
    }

   
    receive() external payable {}
}
