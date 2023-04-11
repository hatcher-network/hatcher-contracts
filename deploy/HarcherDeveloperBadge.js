const CONFIG = require("../constants/config.json")
const { ethers } = require("hardhat")
const {updateConfig} = require("../utils/helpers")

module.exports = async function ({ deployments, getNamedAccounts }) {
    const { deploy } = deployments
    const { deployer } = await getNamedAccounts()
    console.log(`>>> your address: ${deployer}`)

    let res = await deploy("HatcherDeveloperBadge", {
        from: process.env.TEST_PRIV_KEY,
        args: [],
        log: true,
        waitConfirmations: 1,
    })
    updateConfig(hre.network.name, 'HatcherDeveloperBadge', res.address);
    
}

module.exports.tags = ["HatcherDeveloperBadge"]

