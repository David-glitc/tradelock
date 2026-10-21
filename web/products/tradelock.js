import {$,config,fmt,link,button,field,form,details,address,amount,integer,read,tx,approveNFT,mine,chainTime,asset,start} from '../core.js';
function controls(){
 $('list-title').textContent='Swap offers';
 $('controls').innerHTML='<h2>Offer an NFT</h2>'+form('nft-offer',field('nft','Your NFT contract','','text','placeholder="0x…"')+field('token-id','Token ID','0','text','inputmode="numeric"')+field('price','Price (BOT)','0.01','text','inputmode="decimal"')+field('expiry','Expires in (days)','7','number','min="1" max="365"'),'Approve & list for BOT',async f=>{const nft=address(f.nft),id=integer(f['token-id']);await approveNFT(nft,id,config.contracts.TradelockEscrow);await tx('TradelockEscrow','createNftToTokenSwap',[nft,id,amount(f.price),BigInt(Number(f.expiry)*86400)]);})+details('Trade NFT for NFT',form('nft-swap',field('offered','Your NFT contract','','text','placeholder="0x…"')+field('offered-id','Your token ID','0')+field('wanted','Wanted NFT contract','','text','placeholder="0x…"')+field('wanted-id','Wanted token ID','0'),'Approve & offer swap',async f=>{const nft=address(f.offered),id=integer(f['offered-id']);await approveNFT(nft,id,config.contracts.TradelockEscrow);await tx('TradelockEscrow','createNftToNftSwap',[nft,id,address(f.wanted),integer(f['wanted-id']),604800n]);}));
 $('rules').innerHTML='<ul><li>Your offered ERC-721 NFT is held in escrow.</li><li>Only the specified BOT amount or exact requested NFT can fill the offer.</li><li>You can cancel an active offer; anyone can return an expired offer to its creator.</li><li>No protocol fee. Verify the NFT collection address before trading.</li></ul>';
}
async function render(){
 const count=Number(await read('TradelockEscrow','getSwapCount'));const nowMs=await chainTime()*1000;let html='';
 for(let id=count-1;id>=Math.max(0,count-30);id--){const s=await read('TradelockEscrow','getSwap',[BigInt(id)]);const active=s.status===0,expired=Number(s.expiresAt)*1000<=nowMs,own=mine(s.creator);
  html+=`<article class="item"><div class="section-head"><h3>NFT #${s.offerNftId}</h3><span class="badge">${['Active','Completed','Cancelled','Expired'][s.status]}</span></div><p>${link(s.offerNftContract,'View NFT collection')} · Seller ${link(s.creator)}</p><div class="amount">${s.swapType===1?`${fmt(s.wantedTokenAmount)} ${asset('BOT')}`:`NFT #${s.wantedNftId}`}</div>${s.swapType===0?`<p>Wanted collection: ${link(s.wantedNftContract)}</p>`:''}<p class="tiny">Expires ${new Date(Number(s.expiresAt)*1000).toLocaleString()}</p><div class="actions">`;
  if(active&&own)html+=button('Cancel & return NFT',()=>tx('TradelockEscrow','cancelSwap',[BigInt(id)]));
  if(active&&expired)html+=button('Return expired NFT',()=>tx('TradelockEscrow','expireSwap',[BigInt(id)]));
  if(active&&!expired&&!own)html+=button(s.swapType===1?'Buy NFT':'Approve & swap',async()=>{if(s.swapType===1)await tx('TradelockEscrow','acceptNftToTokenSwap',[BigInt(id)],s.wantedTokenAmount);else{await approveNFT(s.wantedNftContract,s.wantedNftId,config.contracts.TradelockEscrow);await tx('TradelockEscrow','acceptNftToNftSwap',[BigInt(id)]);}},true);
  html+='</div></article>';
 }return html||'<p class="empty">No offers yet. List an NFT to open the market.</p>';
}
start({controls,render});
