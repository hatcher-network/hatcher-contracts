const {getContractAddr } = require("../utils/helpers")

module.exports = async function (taskArgs, hre) {
    // get local contract
    const cert = await ethers.getContractAt("HatcherServiceCertificate", 
        getContractAddr(hre.network.name, "HatcherServiceCertificate"))

    const passportAddr = getContractAddr(hre.network.name, "HatcherServicePassport")

    // set
    try {
        let tx = await (await cert.setPassportContract(passportAddr)).wait()
        console.log(`✅ [${hre.network.name}] setPassportContract(${passportAddr})`)
        console.log(` tx: ${tx.transactionHash}`)
    } catch (e) {

        console.log(`❌ [${hre.network.name}] init failed: ${e.message}`)

    }

}
