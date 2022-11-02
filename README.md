# Safu Router Challenge

> This is highly experimental contracts not recommended for production.

This repository contains a few mechnisms to create a safu router which don't relay on whitelist to protect user's approvals.

Router without whitelist is useful when projects integrate more protocols and generate tx data off-chain sent to Router, it means the router can have no admin who controls what contract can be called from Router when users had approved tokens to Router.

## Usage

### Build

`forge build`

### Test

`forge test --fork-url https://rpc.ankr.com/eth -vvv`
