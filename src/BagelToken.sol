// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title BagelToken
/// @notice ERC20 token distributed through the MerkleAirdrop contract
/// @dev Supply starts at zero; only the owner can mint. The deployer is the initial owner.
contract BagelToken is ERC20, Ownable {
    /// @notice Thrown when minting to the zero address
    error BagelToken__AddressCannotBeZero();
    /// @notice Thrown when minting an amount of zero
    error BagelToken__AmountShouldBeGraterThanZero();

    /// @notice The token name
    string public constant TOKEN_NAME = "Date Token";
    /// @notice The token symbol
    string public constant TOKEN_SYMBOL = "DATE";

    /// @notice Deploys the token and sets the deployer as owner
    constructor() ERC20(TOKEN_NAME, TOKEN_SYMBOL) Ownable(msg.sender) {}

    /// @notice Mints `amount` new tokens to `to`
    /// @dev Restricted to the owner
    /// @param to The address receiving the tokens
    /// @param amount The amount to mint, in the token's smallest unit (18 decimals)
    function mint(address to, uint256 amount) public onlyOwner {
        if (to == address(0)) {
            revert BagelToken__AddressCannotBeZero();
        }

        if (amount <= 0) {
            revert BagelToken__AmountShouldBeGraterThanZero();
        }
        _mint(to, amount);
    }
}
