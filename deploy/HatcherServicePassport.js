const CONFIG = require("../constants/config.json")
const { ethers, upgrades } = require("hardhat")
const {updateConfig} = require("../utils/helpers")

module.exports = async function ({ deployments, getNamedAccounts }) {
    const { deploy } = deployments
    const { deployer } = await getNamedAccounts()

    console.log(`>>> your address: ${deployer}`)

    // get the service certificate address
    const certAddr = CONFIG["networks"][hre.network.name]["HatcherServiceCertificate"]
    console.log(`[${hre.network.name}]  HatcherServiceCertificate address: ${certAddr}`)

    const HatcherServicePassport = await ethers.getContractFactory("HatcherServicePassport");
    const hsc = await upgrades.deployProxy(HatcherServicePassport, [certAddr]);

    updateConfig(hre.network.name, 'HatcherServicePassport', hsc.address);
}

module.exports.tags = ["HatcherServicePassport"]
