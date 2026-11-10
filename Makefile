-include .env

.PHONY: all build test clean anvil generate-input make-merkle merkle deploy claim

ANVIL_RPC_URL := http://127.0.0.1:8545
# default anvil account
ANVIL_PRIVATE_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

all: clean build test

build:
	forge build

test:
	forge test -vv

clean:
	forge clean

anvil:
	anvil

# Write the whitelist to script/target/input.json
generate-input:
	forge script script/GenerateInput.s.sol

# Build the tree from input.json and write root + proofs to script/target/output.json
make-merkle:
	forge script script/MakeMerkle.s.sol

merkle: generate-input make-merkle

# Deploy BagelToken + MerkleAirdrop to the local anvil node
deploy:
	forge script script/DeployMerkle.s.sol --rpc-url $(ANVIL_RPC_URL) --private-key $(ANVIL_PRIVATE_KEY) --broadcast

# Claim for the default anvil account on the most recently deployed MerkleAirdrop
claim:
	forge script script/Interact.s.sol --rpc-url $(ANVIL_RPC_URL) --broadcast
