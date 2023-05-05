
const CONFIG = require("../constants/config.json")
const { ethers, upgrades } = require("hardhat")
const {updateConfig} = require("../utils/helpers")

module.exports = async function ({ deployments, getNamedAccounts }) {
    const { deploy } = deployments
    const { deployer } = await getNamedAccounts()

    console.log(`>>> your address: ${deployer}`)

    const tax = CONFIG["tax"]
    console.log(`tax rate: ${tax}`)

    const HatcherServiceCertificate = await ethers.getContractFactory("HatcherServiceCertificate");
    const hsc = await upgrades.deployProxy(HatcherServiceCertificate, [tax]);

    updateConfig(hre.network.name, 'HatcherServiceCertificate', hsc.address);
}

module.exports.tags = ["HatcherServiceCertificate"]
