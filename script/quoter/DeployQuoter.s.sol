pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "./LamboQuoterForAggregator.sol";
import "./LamboMemeQuoter.sol";
import "./LamboQuoterPathFor1inchV6.sol";


contract DeployQuoter is Script {
    // forge script script/quoter/DeployQuoter.s.sol:DeployQuoter --rpc-url https://eth-mainnet.public.blastapi.io --broadcast -vvvv --legacy --verify --etherscan-api-key RTJCFXFDI87EIYGXH8BT1RJZRQ6IY85N3Q

    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(privateKey);

        // LamboQuoterPathFor1inchV6 lamQuoterPathAggregator = new LamboQuoterPathFor1inchV6();
        //  console.log("LamboMemeQuoter address:", address(lamQuoterPathAggregator));

        // LamboMemeQuoter lamboMemeQuoter = new LamboMemeQuoter();
        // console.log("LamboMemeQuoter address:", address(lamboMemeQuoter));

        // LamboQuoterForAggregator lamboQuoter = new LamboQuoterForAggregator();
        // console.log("LamboQuoterForAggregator address:", address(lamboQuoter));
        vm.stopBroadcast();
    }
}
