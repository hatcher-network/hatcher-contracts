const {getContractAddr } = require("../utils/helpers")

module.exports = async function (taskArgs, hre) {
    // get local contract
    const localContractInstance = await ethers.getContract("HatcherServiceCertificate")

    const passportAddr = getContractAddr(hre.network.name, "HatcherServicePassport")

    // set
    try {
        let tx = await (await localContractInstance.init(passportAddr)).wait()
        console.log(`✅ [${hre.network.name}] init(${passportAddr})`)
        console.log(` tx: ${tx.transactionHash}`)
    } catch (e) {

        console.log(`❌ [${hre.network.name}] init failed: ${e.message}`)

    }

}
