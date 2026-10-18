// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {Test} from "forge-std/Test.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {TradelockEscrow} from "../src/TradelockEscrow.sol";

contract NFT is ERC721 {constructor() ERC721("Fixture","FIX"){} function mint(address a,uint256 id) external {_mint(a,id);}}
contract TradelockTest is Test {
    address alice=address(0xA11CE);address bob=address(0xB0B);address treasury=address(0x777);
    function setUp() public {vm.deal(alice,100 ether);vm.deal(bob,100 ether);vm.deal(address(this),100 ether);}
    function test_nftSwapPurchaseCancelExpiryAndMissingId() public {
        NFT n=new NFT();TradelockEscrow s=new TradelockEscrow(address(this),treasury,0);n.mint(alice,1);
        vm.startPrank(alice);n.approve(address(s),1);s.createNftToTokenSwap(address(n),1,1 ether,1 days);vm.stopPrank();
        vm.prank(bob);s.acceptNftToTokenSwap{value:1 ether}(0);assertEq(n.ownerOf(1),bob);assertEq(alice.balance,101 ether);
        vm.expectRevert();s.getSwap(1);vm.prank(bob);vm.expectRevert();s.acceptNftToTokenSwap{value:1 ether}(0);
        vm.startPrank(bob);n.approve(address(s),1);s.createNftToTokenSwap(address(n),1,2 ether,1 days);s.cancelSwap(1);assertEq(n.ownerOf(1),bob);
        n.approve(address(s),1);s.createNftToTokenSwap(address(n),1,2 ether,1 days);vm.stopPrank();vm.warp(block.timestamp+1 days);s.expireSwap(2);assertEq(n.ownerOf(1),bob);
    }
}
