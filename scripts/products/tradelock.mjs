export default {
 slug:'tradelock',vercel:'tradelockbot',assets:['BOT'],name:'Tradelock',repo:'tradelock',contract:'TradelockEscrow',color:'#99e2c2',eyebrow:'NFT ESCROW',symbol:'⇄',
 line:'Your NFT. Your terms.',
 app:{title:'Offer book',line:'Every NFT here is locked in escrow until a trade fills or it returns.',layout:'desk'},
 description:'Escrow an NFT for BOT or another NFT. Accept, cancel, or recover an expired offer onchain.',
 abis:['TradelockEscrow'],
 contracts:['src/TradelockEscrow.sol'],tests:['test/Tradelock.t.sol'],
 landing:{
  steps:[['List an NFT','Approve one ERC-721 and set a BOT price, or name the exact NFT you want in return.'],['Counterparty fills','The buyer pays the exact BOT amount or hands over the exact requested NFT.'],['Atomic settlement','Both sides move in one transaction. Cancel any time before it fills.']],
  features:[['Exact terms','Offers fill only with the precise amount or token you asked for.'],['Escrowed NFTs','Your NFT is held by the contract, not by another person.'],['Expiry recovery','Anyone can return an expired NFT to its owner.'],['No protocol fee','Tradelock launches with a 0% fee.']],
  faq:[['Which NFTs work?','Any standard ERC-721 on BOT Chain. Always check the collection address before buying.'],['Can I trade NFT for NFT?','Yes. Name the wanted collection and token ID; only its owner can fill the offer.'],['What happens when an offer expires?','It stops accepting fills, and anyone can send the escrowed NFT back to its creator.'],['Is there a fee?','Only BOT Chain gas.']],
 },
 async deploy({deploy,account}){await deploy('TradelockEscrow',[account.address,account.address,0n]);},
};
