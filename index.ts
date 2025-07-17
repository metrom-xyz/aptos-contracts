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
            "0x280de537562f50a78bba408ac0ea6c9ea8e661222e22734cc8315d8b3341a705",
        blockCreated: 15406126,
    },
};
