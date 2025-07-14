import { program } from "commander";
import {
    Account,
    Aptos,
    AptosConfig,
    Network,
    NetworkToNetworkName,
} from "@aptos-labs/ts-sdk";
import { execSync } from "node:child_process";
import { readFileSync } from "node:fs";
import ora from "ora";

program
    .requiredOption("--network <network>", "The network on which to deploy")
    .requiredOption("--updater <updater>", "The updater of the contract")
    .requiredOption("--fee <fee>", "The initial fee (in ppm)")
    .requiredOption(
        "--minimum-campaign-duration <minimumCampaignDuration>",
        "The initial minimum campaign duration in seconds",
    )
    .requiredOption(
        "--maximum-campaign-duration <maximumCampaignDuration>",
        "The initial maximum campaign duration in seconds",
    )
    .option("--owner <owner>", "The owner of the contract")
    .parse(process.argv);

const {
    network,
    updater,
    fee,
    minimumCampaignDuration,
    maximumCampaignDuration,
    owner: rawOwner,
} = program.opts();

if (!(network in NetworkToNetworkName)) {
    console.error(
        `Invalid network "${network}" provided; valid values are: ${Object.values(Network).join(", ")}`,
    );
    process.exit(1);
}

// Check if the Aptos CLI is installed
try {
    execSync(`aptos --version`, { stdio: "ignore" });
} catch (error) {
    console.log(
        "The Aptos CLI is not installed. Please install it from the instructions on aptos.dev",
    );
}

const aptos = new Aptos(new AptosConfig({ network: network as Network }));

// Generate the deployment's account and set it as the owner if an owner wasn't specified
let spinner = ora("Generating deployment account").start();
const metrom = Account.generate();
let owner = rawOwner;
if (!rawOwner) owner = metrom.accountAddress;
spinner.succeed(`Deployment account with address ${metrom.accountAddress} generated (will be the module's address)`);

const PUBLISH_PAYLOAD_PATH = `${import.meta.dirname}/../build/publish-payload.json`;

// Fund the deployment account
spinner = ora("Funding deployment account").start();
try {
    await aptos.fundAccount({
        accountAddress: metrom.accountAddress,
        amount: 100_000_000,
    });
    spinner.succeed("Deployment account funded");
} catch (error) {
    spinner.fail(`Could not fund deployment account: ${error}`);
    process.exit(1);
}

// Compile the package
spinner = ora("Compiling package").start();
try {
    execSync(
        `aptos move build-publish-payload --json-output-file ${PUBLISH_PAYLOAD_PATH} --named-addresses metrom=${metrom.accountAddress} --assume-yes`,
        { stdio: "ignore" },
    );
    spinner.succeed("Package compiled");
} catch (error) {
    spinner.fail(`Error compiling the package: ${error}`);
    process.exit(1);
}

// Get the output compilation artifact
const jsonData = JSON.parse(readFileSync(PUBLISH_PAYLOAD_PATH, "utf8"));

// Publish the package
spinner = ora("Publishing the package on-chain").start();
try {
    const publishTransaction = await aptos.publishPackageTransaction({
        account: metrom.accountAddress,
        metadataBytes: jsonData.args[0].value,
        moduleBytecode: jsonData.args[1].value,
    });
    const publishResponse = await aptos.signAndSubmitTransaction({
        signer: metrom,
        transaction: publishTransaction,
    });
    spinner.text = `Publish transaction broadcast on-chain with hash ${publishResponse.hash}`;
    await aptos.waitForTransaction({ transactionHash: publishResponse.hash });
    spinner.succeed(
        `Publish transaction confirmed on-chain (hash: ${publishResponse.hash})`,
    );
} catch (error) {
    spinner.fail(`Transaction broadcast failed: ${error}`);
    process.exit(1);
}

// Run post-publish checks
spinner = ora("Checking the on-chain deployment").start();
const modules = await aptos.getAccountModules({
    accountAddress: metrom.accountAddress,
});
if (modules.length !== 1) {
    spinner.fail(
        `Check failed: expected 1 module to be published, but ${modules.length} were instead`,
    );
    process.exit(1);
}
if (modules[0].bytecode === jsonData.args[1].value.bytes) {
    spinner.fail(
        "Check failed: the published module's bytecode does not match the locally buit one",
    );
    process.exit(1);
}
spinner.succeed("On-chain checks passed");

// Initialize the package
spinner = ora("Initializing the package on-chain").start();
try {
    const initTransaction = await aptos.transaction.build.simple({
        sender: metrom.accountAddress,
        data: {
            function: `${metrom.accountAddress}::metrom::init_state`,
            typeArguments: [],
            functionArguments: [
                owner,
                updater,
                fee,
                minimumCampaignDuration,
                maximumCampaignDuration,
            ],
        },
    });
    const initResponse = await aptos.signAndSubmitTransaction({
        signer: metrom,
        transaction: initTransaction,
    });
    spinner.text = `Init state transaction broadcast on-chain with hash ${initResponse.hash}`;
    await aptos.waitForTransaction({ transactionHash: initResponse.hash });
    spinner.succeed(
        `Init state transaction confirmed on-chain (hash: ${initResponse.hash})`,
    );
} catch (error) {
    spinner.fail(`Init state transaction broadcast failed: ${error}`);
    process.exit(1);
}
