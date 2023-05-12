# hatcher-contracts


 ### Install

```shell
yarn install
```

* The code in the `/contracts` folder demonstrates behaviours.
* Always audit your own code and test extensively on `testnet` before going to mainnet 🙏


# Deploy

The behavious of three contracts below:

    0. `DataMarket.sol` - Data Marketplace on BSC, to trade data objects on the Greenfield network
    1. `HatcherServiceCertificate.sol` - Service provider publish their services.    
    2. `HatcherServicePassport` - User interacts with this contract to subscribe to services.

## example

1. Deploy three contracts to ```bsc_gnfd```.

    ```angular2html
    npx hardhat --network bsc_gnfd deploy --tags DataMarket
    npx hardhat --network bsc_gnfd deploy --tags HatcherServiceCertificate
    npx hardhat --network bsc_gnfd deploy --tags HatcherServicePassport
    ```
2. Init cerfication contract
    ```angular2html
    npx hardhat --network bsc_gnfd serviceInit
    ```
