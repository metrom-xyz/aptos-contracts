export interface ChainContract {
    address: `0x${string}`;
    blockCreated: number;
}

export enum SupportedChain {
    Testnet = "testnet",
    Mainnet = "mainnet",
}

export const ADDRESS: Record<SupportedChain, ChainContract> = {
    [SupportedChain.Testnet]: {
        address:
            "0xb0359fb67f74ce2dd11c9b219be4b2f00569e6b55912e2145a8e69df1497ce67",
        blockCreated: 6854139736,
    },
    [SupportedChain.Mainnet]: {
        address:
            "0xd438cb1c136b04beb5b832d2ab1e63c73d1d1a95fe3e8eb1a79d1e86b746a42b",
        blockCreated: 3353134305,
    },
};
