
const CONFIG = require("../constants/config.json")
const { ethers } = require("hardhat")
const {updateConfig} = require("../utils/helpers")

module.exports = async function ({ deployments, getNamedAccounts }) {
    const { deploy } = deployments
    const { deployer } = await getNamedAccounts()

    console.log(`>>> your address: ${deployer}`)

    const revenueRate = CONFIG["revenueRate"]
    console.log(`revenue rate: ${revenueRate}`)

    // get the badge address
    const badgeAddr = CONFIG["networks"][hre.network.name]["HatcherDeveloperBadge"]
    console.log(`[${hre.network.name}]  HatcherDeveloperBadge address: ${badgeAddr}`)

    const res = await deploy("HatcherServiceCertificate", {
        from: deployer,
        args: [badgeAddr, revenueRate],
        log: true,
        waitConfirmations: 1,
    })
    updateConfig(hre.network.name, 'HatcherServiceCertificate', res.address);
}

module.exports.tags = ["HatcherServiceCertificate"]
