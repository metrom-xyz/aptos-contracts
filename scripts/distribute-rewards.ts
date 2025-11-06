import { program } from "commander";
import { execSync } from "node:child_process";

program
    .option(
        "--profile [profile]",
        "The profile to use in the Aptos CLI",
        "default",
    )
    .requiredOption("--metrom <metrom>", "The Metrom module address")
    .requiredOption(
        "--campaign-id <campaignId>",
        "The id of the campaign to distribute rewards for",
    )
    .requiredOption("--root <root>", "The Merkle root")
    .requiredOption("--data-hash <dataHash>", "The data hash")
    .parse(process.argv);

const { profile, metrom, campaignId, root, dataHash } = program.opts();

execSync(
    `aptos move run --profile ${profile} --function-id ${metrom}::metrom::distribute_rewards --args 'hex:["${campaignId}"]' 'hex:["${root}"]' 'hex:["${dataHash}"]'`,
    { stdio: "inherit" },
);
