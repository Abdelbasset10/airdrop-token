// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script, console} from "forge-std/Script.sol";

/// @notice Writes the airdrop whitelist (address + amount) to script/target/input.json
contract GenerateInput is Script {
    string private constant INPUT_PATH = "./script/target/input.json";
    uint256 private constant AMOUNT = 25e18;

    function run() public {
        address[] memory whitelist = new address[](4);
        whitelist[0] = makeAddr("user"); // matches makeAddr("user") in tests
        whitelist[1] = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266; // default anvil account
        whitelist[2] = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;
        whitelist[3] = 0x90F79bf6EB2c4f870365E785982E1f101E93b906;

        string memory values = "values";
        string memory valuesJson;
        for (uint256 i = 0; i < whitelist.length; i++) {
            string memory entry = string.concat("entry", vm.toString(i));
            vm.serializeAddress(entry, "0", whitelist[i]);
            string memory entryJson = vm.serializeString(entry, "1", vm.toString(AMOUNT));
            valuesJson = vm.serializeString(values, vm.toString(i), entryJson);
        }

        string[] memory types = new string[](2);
        types[0] = "address";
        types[1] = "uint";

        string memory root = "root";
        vm.serializeString(root, "types", types);
        vm.serializeUint(root, "count", whitelist.length);
        string memory json = vm.serializeString(root, "values", valuesJson);

        vm.writeJson(json, INPUT_PATH);
        console.log("Wrote %s entries to %s", whitelist.length, INPUT_PATH);
    }
}
