export interface ChainContract {
    address: `0x${string}`;
    versionCreated: number;
}

export enum SupportedChain {
    Testnet = "testnet",
    Mainnet = "mainnet",
}

export const ADDRESS: Record<SupportedChain, ChainContract> = {
    [SupportedChain.Testnet]: {
        address:
            "0xb0359fb67f74ce2dd11c9b219be4b2f00569e6b55912e2145a8e69df1497ce67",
        versionCreated: 6854139736,
    },
    [SupportedChain.Mainnet]: {
        address:
            "0x0244c176d3d3db102bc46581cd22050e371afdce03c58307507ce6eef450d166",
        versionCreated: 3362403011,
    },
};
