// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script, console} from "forge-std/Script.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";

/// @notice Claims the airdrop for the default anvil account on the most recently deployed MerkleAirdrop
contract ClaimAirdrop is Script {
    // default anvil account
    address constant CLAIMING_ADDRESS = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    uint256 constant CLAIMING_PRIVATE_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    uint256 constant AMOUNT_TO_CLAIM = 25e18;
    bytes32 proof1 = 0xd1445c931158119b00449ffcac3c947d028c0c359c34a6646d95962b3b55c6ad;
    bytes32 proof2 = 0xf19a9e842b5a96e6e829203e375dfae8688610006eff2ecee5b1d5171631c970;
    bytes32[] proofs = [proof1, proof2];

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("MerkleAirdrop", block.chainid);
        MerkleAirdrop airdrop = MerkleAirdrop(mostRecentlyDeployed);

        bytes32 digest = airdrop.getMessageHash(CLAIMING_ADDRESS, AMOUNT_TO_CLAIM);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(CLAIMING_PRIVATE_KEY, digest);

        vm.startBroadcast(CLAIMING_PRIVATE_KEY);
        airdrop.claim(CLAIMING_ADDRESS, AMOUNT_TO_CLAIM, proofs, v, r, s);
        vm.stopBroadcast();

        console.log("Claimed %s tokens for %s", AMOUNT_TO_CLAIM, CLAIMING_ADDRESS);
    }
}
