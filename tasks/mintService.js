const {getContractAddr } = require("../utils/helpers")

module.exports = async function (taskArgs, hre) {
    // get local contract
    const cert = await ethers.getContractAt("HatcherServiceCertificate", 
        getContractAddr(hre.network.name, "HatcherServiceCertificate"))

    /*
    uint256 maxUserLimit,
    uint256 price,
    string memory logo,
    string memory name_,
    string memory description,
    string memory endpoint,
    string memory service_type
    */
    try {
        let tx = await (await cert.mint(
            10000, 1000, "https://pbs.twimg.com/profile_images/977496875887558661/L86xyLF4_400x400.jpg",
            "Vitalik's soul", "Talk to Vitalik now!", "https://api.hatcher.network/",
            "chat",
            {
                value: ethers.utils.parseEther("0.01"),
                // gasLimit: 1000000,
            }
            )).wait()
        console.log(`✅ [${hre.network.name}] mintService`)
        console.log(` tx: ${tx.transactionHash}`)
    } catch (e) {

        console.log(`❌ [${hre.network.name}] mint failed: ${e.message}`)

    }

}
