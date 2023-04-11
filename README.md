# hatcher-contracts


 ### Install

```shell
yarn install
```

* The code in the `/contracts` folder demonstrates behaviours.
* Always audit your own code and test extensively on `testnet` before going to mainnet 🙏

> The examples below use testnet chains, however you could substitute any  supported chain! 


# Deploy

The behavious of three contracts below:

    1. `HatcherDeveloperBadge.sol` - The Badge NFT for service providers who coould create a service with it.
    2. `HatcherServiceCertificate.sol` - Service provider create their service which will be provided for users.    
    3. `HatcherServicePassport` - User interacts with this contract to subscribe to the service to use.

In the example deployment below we use chain is ```mumbai```.
Using the Polygon network ```(testnet: mumbai)``` as a is a cost cut decision.


## example

1. Deploy three contracts to ```mumbai```.

    ```angular2html
    npx hardhat --network mumbai deploy --tags HatcherDeveloperBadge
    npx hardhat --network mumbai deploy --tags HatcherServiceCertificate
    npx hardhat --network mumbai deploy --tags HatcherServicePassport
    ```
2. Init cerfication contract
    ```angular2html
    npx hardhat --network mumbai serviceInit
    ```