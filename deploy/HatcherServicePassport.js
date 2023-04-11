
const CONFIG = require("../constants/config.json")
const { ethers } = require("hardhat")
const {updateConfig} = require("../utils/helpers")

module.exports = async function ({ deployments, getNamedAccounts }) {
    const { deploy } = deployments
    const { deployer } = await getNamedAccounts()

    console.log(`>>> your address: ${deployer}`)

    // get the service certification address
    const certificationAddr = CONFIG["networks"][hre.network.name]["HatcherServiceCertificate"]
    console.log(`[${hre.network.name}]  HatcherServiceCertificate address: ${certificationAddr}`)

    const res = await deploy("HatcherServicePassport", {
        from: deployer,
        args: [certificationAddr],
        log: true,
        waitConfirmations: 1,
    })
    updateConfig(hre.network.name, 'HatcherServicePassport', res.address);
}

module.exports.tags = ["HatcherServicePassport"]
