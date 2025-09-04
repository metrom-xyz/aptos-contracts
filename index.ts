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
            "0x8ca73e071810f46d1d6dcf7762e3f5c0da657fe7bce2cab93a77e2316afb4537",
        blockCreated: 500110776,
    },
    [SupportedChain.Mainnet]: {
        address:
            "0xcc51d5050370aa937794e5e91c57e132fdfd182a5885ceadf6adce0106e32cd9",
        blockCreated: 3308740396,
    },
};
