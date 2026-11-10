// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Test, console} from "forge-std/Test.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";
import {BagelToken} from "../src/BagelToken.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {DeployMerkle} from "../script/DeployMerkle.s.sol";

contract MerkleAirdropTest is Test {
    MerkleAirdrop merkleContract;
    BagelToken bagleToken;

    uint256 public constant AMOUNT_TO_CLAIM = 25e18;

    bytes32 proof1 = 0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986c00a;
    bytes32 proof2 = 0xf19a9e842b5a96e6e829203e375dfae8688610006eff2ecee5b1d5171631c970;
    bytes32[] proofs = [proof1, proof2];

    address user;
    uint256 privateKey;

    function setUp() public {
        DeployMerkle deployer = new DeployMerkle();
        (bagleToken,merkleContract) = deployer.run();
        (user, privateKey) = makeAddrAndKey("user");
    }

    function test_claim() public {
        uint256 userBalanceBefore = IERC20(bagleToken).balanceOf(user);

        bytes32 digest = merkleContract.getMessageHash(user, AMOUNT_TO_CLAIM);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);

        address gasPayer = makeAddr("gasPayer");
        vm.prank(gasPayer);
        merkleContract.claim(user, AMOUNT_TO_CLAIM, proofs, v, r, s);

        uint256 userBalanceAfter = IERC20(bagleToken).balanceOf(user);

        assertEq(userBalanceAfter, userBalanceBefore + AMOUNT_TO_CLAIM);
    }
}
