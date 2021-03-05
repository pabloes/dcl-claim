var Collection = artifacts.require("ERC721Collection");
var Claimer = artifacts.require("Claimer");

module.exports = async function(deployer, network, accounts) {
  const [owner, operator, player] = accounts;
  let collection, claimer;

  try{
    collection = await Collection.deployed();
  }catch(err){
    collection =  await deployer.deploy(Collection,...[
      "dcl://mf_sammichgamer",
      "DCLMFSMMCHGMR", 
      operator,
      "https://wearable-api.decentraland.org/v2/standards/erc721-metadata/collections/mf_sammichgamer/wearables/"
  ], {from:owner});
    //TODO createWearables, assign operator, etc.        
  }
  
  
  try{
    claimer = await Claimer.deployed();
  }catch(err){
    claimer =  await deployer.deploy(Claimer,...[
      collection.address
    ]);
    //TODO createWearables, assign operator, etc.        
  }
  console.log("collection address", collection.address);
  console.log("claimer address", claimer.address);
};
