<br />

<p align="center">
    <img src=".github/static/logo.svg" alt="Metrom logo" width="60%" />
</p>

<br />

<p align="center">
  Design your incentives to AMMplify liquidity.
</p>

<br />

<p align="center">
    <img src="https://img.shields.io/badge/License-GPLv3-blue.svg" alt="License: GPL v3">
    <img src="https://github.com/metrom-xyz/contracts/actions/workflows/ci.yml/badge.svg" alt="CI">
</p>

# Metrom Aptos contracts

The smart contract powering Metrom's efficient AMM incentivization on Aptos,
written in Move.

## What is Metrom

Metrom is a tool that DeFi protocols (and more) can use to incentivize liquidity
providers to provide the maximum amount of liquidity possible in the way that is
the most efficient through the creation of dedicated incentivization campaigns.

Once a campaign is created and activated, Metrom's backend monitors the required
metrics, processing all the meaningful on-chain event that happen on it and
computing a rewards distribution list off-chain depending on the specific
contributions to the goal. A Merkle tree is constructed from the list and its
root is then pushed on-chain. Eligible users can then claim their rewards (if
any) by simply providing a tree inclusion proof to the Metrom smart contract.
