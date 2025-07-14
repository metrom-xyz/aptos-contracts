export interface ChainContract {
    address: string;
    blockCreated: number;
}

export enum SupportedChain {
    Devnet = "devnet",
}

export const ADDRESS: Record<SupportedChain, ChainContract> = {
    [SupportedChain.Devnet]: {
        address:
            "0xaab676170774448375f2b01bdc6b1d013d2f3d73e869dddbb405b045773b5bc2",
        blockCreated: 15406126,
    },
};
