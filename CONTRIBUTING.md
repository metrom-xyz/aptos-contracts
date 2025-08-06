# Contributing

## Testing

Tests are in the `tests` folder.

### Deploying

To deploy the modules, these following Aptos CLI commands are needed:

```sh
aptos move deploy-object --profile=$PROFILE --address-name metrom
# at this point note down the object account address printed by the previous command (it will be the deployed module's address and we refer to it as $COPIED_ADDRESS from now on)
aptos move run --profile=$PROFILE --function-id $COPIED_ADDRESS::metrom::init_state --args address:$OWNER address:$UPDATER u32:$FEE u64:$MINIMUM_CAMPAIGN_DURATION u64:$MAXIMUM_CAMPAIGN_DURATION
```

### Addresses

Official addresses and creation blocks are tracked in the `index.ts` file and
are consumable from Javascript through a dedicated NPM package
(`@metrom-xyz/aptos-contracts`).
