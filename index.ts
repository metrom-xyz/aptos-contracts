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
            "0xb5d000e8fd65b6fcb4ba4614b7c97df0eb01484fb4e6dc307a03bdeb7cdfe480",
        blockCreated: 30754169,
    },
};
