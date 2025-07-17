import { program } from "commander";
import { execSync } from "node:child_process";

program
    .option(
        "--profile [profile]",
        "The profile to use in the Aptos CLI",
        "default",
    )
    .requiredOption("--metrom <metrom>", "The Metrom module address")
    .requiredOption("--token <token>", "The token of which to set the ratio")
    .requiredOption("--ratio <ratio>", "The ratio")
    .parse(process.argv);

const { profile, metrom, token, ratio } = program.opts();

execSync(
    `aptos move run --profile ${profile} --function-id ${metrom}::metrom::set_minimum_reward_token_rate --args address:${token} u64:${ratio}`,
    { stdio: "inherit" },
);
