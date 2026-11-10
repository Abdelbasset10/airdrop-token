// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;
import {Script} from "forge-std/Script.sol";

import {BagelToken} from "../src/BagelToken.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";

contract DeployMerkle is Script {
    uint256 public constant AMOUNT_TO_CLAIM = 25e18;

    bytes32 merkeProof = 0xd77e47a6f583216692e5537e91cc25c88ae6eec77bac4d4532ba953b45c24bc6;

    function run() public returns (BagelToken, MerkleAirdrop) {
        vm.startBroadcast();
        BagelToken bagleToken = new BagelToken();
        MerkleAirdrop merkleContract = new MerkleAirdrop(address(bagleToken), merkeProof);
        bagleToken.mint(address(merkleContract), AMOUNT_TO_CLAIM * 10);
        bagleToken.transferOwnership(address(merkleContract));
        vm.stopBroadcast();
        return (bagleToken, merkleContract);
    }
}
