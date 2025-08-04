export interface ChainContract {
    address: `0x${string}`;
    blockCreated: number;
}

export enum SupportedChain {
    Devnet = "devnet",
}

export const ADDRESS: Record<SupportedChain, ChainContract> = {
    [SupportedChain.Devnet]: {
        address:
            "0x98ec7cca4b5e32ec8288bbb593bd4cbb570f7203cc9e9e9efad8d25af3ceb6e2",
        blockCreated: 18437390,
    },
};
