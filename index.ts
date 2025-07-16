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
            "0xb6f5688319d72283325323d3545554a9505a1876cbc7c5eb5a88647abe18cabc",
        blockCreated: 15406126,
    },
};
