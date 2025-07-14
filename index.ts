export interface ChainContract {
    address: string;
    blockCreated: number;
}

export enum SupportedChain {
    Devnet = "devnet",
}

export const ADDRESS: Record<SupportedChain, ChainContract> = {
    [SupportedChain.Devnet]: {
        address: "0xfd10c4063248de3a9afe251ca87b6a72f06d72563c0c0209a1282a582e3eebe2",
        blockCreated: 15332433,
    }
};
