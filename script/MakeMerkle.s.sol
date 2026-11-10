// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script, console} from "forge-std/Script.sol";
import {Merkle} from "murky/src/Merkle.sol";

/// @notice Reads script/target/input.json, builds the Merkle tree and writes
///         the root plus a proof for every entry to script/target/output.json
contract MakeMerkle is Script {
    string private constant INPUT_PATH = "./script/target/input.json";
    string private constant OUTPUT_PATH = "./script/target/output.json";

    function run() public {
        string memory input = vm.readFile(INPUT_PATH);
        uint256 count = vm.parseJsonUint(input, ".count");

        address[] memory accounts = new address[](count);
        uint256[] memory amounts = new uint256[](count);
        bytes32[] memory leaves = new bytes32[](count);

        for (uint256 i = 0; i < count; i++) {
            string memory key = string.concat(".values.", vm.toString(i));
            accounts[i] = vm.parseJsonAddress(input, string.concat(key, ".0"));
            amounts[i] = vm.parseUint(vm.parseJsonString(input, string.concat(key, ".1")));
            // must match the leaf built in MerkleAirdrop.claim
            leaves[i] = keccak256(bytes.concat(keccak256(abi.encode(accounts[i], amounts[i]))));
        }

        Merkle merkle = new Merkle();
        bytes32 root = merkle.getRoot(leaves);

        string memory claims;
        for (uint256 i = 0; i < count; i++) {
            string memory entry = string.concat("claim", vm.toString(i));
            vm.serializeAddress(entry, "account", accounts[i]);
            vm.serializeString(entry, "amount", vm.toString(amounts[i]));
            vm.serializeBytes32(entry, "leaf", leaves[i]);
            string memory entryJson = vm.serializeBytes32(entry, "proof", merkle.getProof(leaves, i));
            claims = i == 0 ? entryJson : string.concat(claims, ",", entryJson);
        }

        string memory json = string.concat('{"root":"', vm.toString(root), '","claims":[', claims, "]}");
        vm.writeJson(json, OUTPUT_PATH);

        console.log("Merkle root:");
        console.logBytes32(root);
        console.log("Wrote proofs to %s", OUTPUT_PATH);
    }
}
