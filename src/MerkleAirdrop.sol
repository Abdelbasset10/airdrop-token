// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/// @title MerkleAirdrop
/// @notice Distributes ERC20 tokens to a whitelist of accounts committed to in a Merkle root.
///         Each account can claim its allocation once, and only with its own EIP-712 signature,
///         so a third party may pay the gas for a claim without being able to claim uninvited.
/// @dev Leaves are `keccak256(bytes.concat(keccak256(abi.encode(account, amount))))`, matching
///      OpenZeppelin's StandardMerkleTree. The contract must be funded with enough tokens
///      to cover every allocation before claims start.
contract MerkleAirdrop is EIP712 {
    using SafeERC20 for IERC20;

    /// @notice Thrown when the claiming account is the zero address
    error MerkleAirdrop__AddressMustBeNotZero();
    /// @notice Thrown when the claimed amount is zero
    error MerkleAirdrop__AmountMustBeGraterThanZero();
    /// @notice Thrown when the account has already claimed its allocation
    error MerkleAirdrop__UserAlreadyClaimed();
    /// @notice Thrown when the Merkle proof does not prove `(account, amount)` is in the tree
    error MerkleAirdrop__InvalidProof();
    /// @notice Thrown when the signature was not produced by the claiming account
    error MerkleAirdrop__InvalidSignature();

    /// @dev EIP-712 type hash of the message an account signs to authorize its claim
    bytes32 private constant MESSAGE_TYPEHASH = keccak256("AirdropClaim(address account,uint256 amount)");

    /// @notice Emitted when an allocation is claimed
    /// @param executer The address that submitted the claim transaction (paid the gas)
    /// @param beneficary The whitelisted account that received the tokens
    /// @param amount The amount of tokens transferred
    event MerkleAirdrop__UserClaimed(address indexed executer, address indexed beneficary, uint256 amount);

    /// @notice Merkle root of the `(account, amount)` whitelist
    bytes32 public immutable i_merkleProof;
    /// @notice The ERC20 token being airdropped
    address public immutable i_bagelToken;

    /// @notice Whether an account has already claimed its allocation
    mapping(address user => bool isClaimed) public s_userCalimed;

    /// @param _bagelTokenAddress The ERC20 token to distribute
    /// @param _merkProof The Merkle root of the whitelist
    constructor(address _bagelTokenAddress, bytes32 _merkProof) EIP712("MerkleAirdrop", "1") {
        i_merkleProof = _merkProof;
        i_bagelToken = _bagelTokenAddress;
    }

    /// @notice Claims `amount` tokens for `account`
    /// @dev Anyone may submit the transaction, but the tokens always go to `account` and the
    ///      signature must come from `account`. State is updated before the transfer (CEI).
    /// @param account The whitelisted account receiving the tokens
    /// @param amount The allocation for `account`, exactly as committed in the Merkle tree
    /// @param proofs The Merkle proof for the `(account, amount)` leaf
    /// @param v Recovery id of `account`'s signature over `getMessageHash(account, amount)`
    /// @param r First 32 bytes of the signature
    /// @param s Second 32 bytes of the signature
    function claim(address account, uint256 amount, bytes32[] memory proofs, uint8 v, bytes32 r, bytes32 s) public {
        if (account == address(0)) {
            revert MerkleAirdrop__AddressMustBeNotZero();
        }
        if (amount <= 0) {
            revert MerkleAirdrop__AmountMustBeGraterThanZero();
        }

        if (s_userCalimed[account]) {
            revert MerkleAirdrop__UserAlreadyClaimed();
        }

        if (!_isValidSignature(account, getMessageHash(account, amount), v, r, s)) {
            revert MerkleAirdrop__InvalidSignature();
        }

        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(account, amount))));

        if (!MerkleProof.verify(proofs, i_merkleProof, leaf)) {
            revert MerkleAirdrop__InvalidProof();
        }

        s_userCalimed[account] = true;

        emit MerkleAirdrop__UserClaimed(msg.sender, account, amount);

        IERC20(i_bagelToken).safeTransfer(account, amount);
    }

    /// @notice Returns the EIP-712 digest `account` must sign to authorize a claim of `amount`
    /// @dev The digest is bound to this contract and chain through the EIP-712 domain separator,
    ///      so it must be signed as-is (e.g. `cast wallet sign --no-hash`)
    /// @param account The whitelisted account
    /// @param amount The account's allocation
    /// @return The typed-data digest to sign
    function getMessageHash(address account, uint256 amount) public view returns (bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(MESSAGE_TYPEHASH, account, amount)));
    }

    /// @notice Checks that `digest` was signed by `account`
    /// @dev Uses `ECDSA.tryRecover`, which rejects malformed and malleable (high-s) signatures
    /// @param account The expected signer
    /// @param digest The signed EIP-712 digest
    /// @param v Recovery id of the signature
    /// @param r First 32 bytes of the signature
    /// @param s Second 32 bytes of the signature
    /// @return True if the signature is valid and recovers to `account`
    function _isValidSignature(address account, bytes32 digest, uint8 v, bytes32 r, bytes32 s)
        internal
        pure
        returns (bool)
    {
        (address signer, ECDSA.RecoverError err,) = ECDSA.tryRecover(digest, v, r, s);
        return err == ECDSA.RecoverError.NoError && signer == account;
    }
}
