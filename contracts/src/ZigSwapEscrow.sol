// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";


/**
 * @title ZigSwapEscrow
 * @dev A secure escrow contract for NFT OTC swaps on Base network
 * Supports both NFT-to-NFT and NFT-to-Token swaps
 */
contract ZigSwapEscrow is ERC721Holder, Ownable, ReentrancyGuard {

    
    // Enum for swap types
    enum SwapType { NFT_TO_NFT, NFT_TO_TOKEN }
    
    // Enum for swap status
    enum SwapStatus { ACTIVE, COMPLETED, CANCELLED, EXPIRED }
    
    // Struct to store swap details
    struct SwapOffer {
        uint256 id;
        address creator;
        SwapType swapType;
        address offerNftContract;
        uint256 offerNftId;
        address wantedNftContract;
        uint256 wantedNftId;
        uint256 wantedTokenAmount;
        uint256 expiresAt;
        SwapStatus status;
        address taker;
    }
    
    // Counter for swap offer IDs
    uint256 private _swapIdCounter;
    
    // Mapping from swap ID to swap details
    mapping(uint256 => SwapOffer) public swapOffers;
    
    // Platform fee percentage (in basis points, e.g., 100 = 1%)
    uint256 public platformFeePercentage;
    
    // Protocol treasury address
    address public treasury;
    
    // Events
    event SwapOfferCreated(
        uint256 indexed swapId,
        address indexed creator,
        SwapType swapType,
        address offerNftContract,
        uint256 offerNftId,
        uint256 expiresAt
    );
    
    event SwapCompleted(
        uint256 indexed swapId,
        address indexed creator,
        address indexed taker
    );
    
    event SwapCancelled(uint256 indexed swapId, address indexed creator);
    
    event SwapExpired(uint256 indexed swapId);
    
    // Constructor
    constructor(address initialOwner, address _treasury, uint256 _platformFeePercentage) Ownable(initialOwner) {
        require(_treasury != address(0), "Invalid treasury");
        treasury = _treasury;
        require(_platformFeePercentage <= 1000, "Fee percentage cannot exceed 10%");
        platformFeePercentage = _platformFeePercentage;
    }
    
    /**
     * @dev Create a new NFT-to-NFT swap offer
     * @param _offerNftContract Address of the NFT contract being offered
     * @param _offerNftId Token ID of the NFT being offered
     * @param _wantedNftContract Address of the NFT contract wanted
     * @param _wantedNftId Token ID of the NFT wanted
     * @param _expirationPeriod Time in seconds until the swap expires
     * @return swapId The ID of the created swap offer
     */
    function createNftToNftSwap(
        address _offerNftContract,
        uint256 _offerNftId,
        address _wantedNftContract,
        uint256 _wantedNftId,
        uint256 _expirationPeriod
    ) external nonReentrant returns (uint256) {
        require(_offerNftContract != address(0), "Invalid NFT contract address");
        require(_wantedNftContract != address(0), "Invalid wanted NFT contract address");
        require(_expirationPeriod > 0, "Expiration period must be greater than 0");
        
        // Transfer NFT from creator to this contract
        IERC721(_offerNftContract).safeTransferFrom(msg.sender, address(this), _offerNftId);
        
        // Create new swap offer
        uint256 swapId = _swapIdCounter;
        _swapIdCounter++;
        
        swapOffers[swapId] = SwapOffer({
            id: swapId,
            creator: msg.sender,
            swapType: SwapType.NFT_TO_NFT,
            offerNftContract: _offerNftContract,
            offerNftId: _offerNftId,
            wantedNftContract: _wantedNftContract,
            wantedNftId: _wantedNftId,
            wantedTokenAmount: 0,
            expiresAt: block.timestamp + _expirationPeriod,
            status: SwapStatus.ACTIVE,
            taker: address(0)
        });
        
        emit SwapOfferCreated(
            swapId,
            msg.sender,
            SwapType.NFT_TO_NFT,
            _offerNftContract,
            _offerNftId,
            block.timestamp + _expirationPeriod
        );
        
        return swapId;
    }
    
    /**
     * @dev Create a new NFT-to-Token swap offer
     * @param _offerNftContract Address of the NFT contract being offered
     * @param _offerNftId Token ID of the NFT being offered
     * @param _wantedTokenAmount Amount of ETH wanted (in wei)
     * @param _expirationPeriod Time in seconds until the swap expires
     * @return swapId The ID of the created swap offer
     */
    function createNftToTokenSwap(
        address _offerNftContract,
        uint256 _offerNftId,
        uint256 _wantedTokenAmount,
        uint256 _expirationPeriod
    ) external nonReentrant returns (uint256) {
        require(_offerNftContract != address(0), "Invalid NFT contract address");
        require(_wantedTokenAmount > 0, "Token amount must be greater than 0");
        require(_expirationPeriod > 0, "Expiration period must be greater than 0");
        
        // Transfer NFT from creator to this contract
        IERC721(_offerNftContract).safeTransferFrom(msg.sender, address(this), _offerNftId);
        
        // Create new swap offer
        uint256 swapId = _swapIdCounter;
        _swapIdCounter++;
        
        swapOffers[swapId] = SwapOffer({
            id: swapId,
            creator: msg.sender,
            swapType: SwapType.NFT_TO_TOKEN,
            offerNftContract: _offerNftContract,
            offerNftId: _offerNftId,
            wantedNftContract: address(0),
            wantedNftId: 0,
            wantedTokenAmount: _wantedTokenAmount,
            expiresAt: block.timestamp + _expirationPeriod,
            status: SwapStatus.ACTIVE,
            taker: address(0)
        });
        
        emit SwapOfferCreated(
            swapId,
            msg.sender,
            SwapType.NFT_TO_TOKEN,
            _offerNftContract,
            _offerNftId,
            block.timestamp + _expirationPeriod
        );
        
        return swapId;
    }
    
    /**
     * @dev Accept an NFT-to-NFT swap
     * @param _swapId ID of the swap offer to accept
     */
    function acceptNftToNftSwap(uint256 _swapId) external nonReentrant {
        SwapOffer storage swap = swapOffers[_swapId];
        
        require(_swapId < _swapIdCounter, "Swap does not exist");
        require(swap.swapType == SwapType.NFT_TO_NFT, "Not an NFT-to-NFT swap");
        require(swap.status == SwapStatus.ACTIVE, "Swap is not active");
        require(swap.creator != msg.sender, "Creator cannot accept their own swap");
        require(block.timestamp < swap.expiresAt, "Swap has expired");
        
        // Transfer NFT from taker to creator
        IERC721(swap.wantedNftContract).safeTransferFrom(
            msg.sender, 
            swap.creator, 
            swap.wantedNftId
        );
        
        // Transfer NFT from contract to taker
        IERC721(swap.offerNftContract).safeTransferFrom(
            address(this), 
            msg.sender, 
            swap.offerNftId
        );
        
        // Update swap status
        swap.status = SwapStatus.COMPLETED;
        swap.taker = msg.sender;
        
        emit SwapCompleted(_swapId, swap.creator, msg.sender);
    }
    
    /**
     * @dev Accept an NFT-to-Token swap
     * @param _swapId ID of the swap offer to accept
     */
    function acceptNftToTokenSwap(uint256 _swapId) external payable nonReentrant {
        SwapOffer storage swap = swapOffers[_swapId];
        
        require(_swapId < _swapIdCounter, "Swap does not exist");
        require(swap.swapType == SwapType.NFT_TO_TOKEN, "Not an NFT-to-Token swap");
        require(swap.status == SwapStatus.ACTIVE, "Swap is not active");
        require(swap.creator != msg.sender, "Creator cannot accept their own swap");
        require(block.timestamp < swap.expiresAt, "Swap has expired");
        require(msg.value == swap.wantedTokenAmount, "Incorrect token amount");
        
        // Calculate platform fee
        uint256 fee = (swap.wantedTokenAmount * platformFeePercentage) / 10000;
        uint256 creatorAmount = swap.wantedTokenAmount - fee;
        
        // Transfer ETH to creator
        (bool success, ) = swap.creator.call{value: creatorAmount}("");
        require(success, "ETH transfer to creator failed");
        
        // Transfer fee to treasury
        if (fee > 0) {
            (bool feeSuccess, ) = treasury.call{value: fee}("");
            require(feeSuccess, "ETH transfer to treasury failed");
        }
        
        // Transfer NFT from contract to taker
        IERC721(swap.offerNftContract).safeTransferFrom(
            address(this), 
            msg.sender, 
            swap.offerNftId
        );
        
        // Update swap status
        swap.status = SwapStatus.COMPLETED;
        swap.taker = msg.sender;
        
        emit SwapCompleted(_swapId, swap.creator, msg.sender);
    }
    
    /**
     * @dev Cancel a swap offer (only callable by the creator)
     * @param _swapId ID of the swap offer to cancel
     */
    function cancelSwap(uint256 _swapId) external nonReentrant {
        SwapOffer storage swap = swapOffers[_swapId];
        
        require(_swapId < _swapIdCounter, "Swap does not exist");
        require(swap.status == SwapStatus.ACTIVE, "Swap is not active");
        require(swap.creator == msg.sender, "Only creator can cancel");
        
        // Transfer NFT back to creator
        IERC721(swap.offerNftContract).safeTransferFrom(
            address(this), 
            swap.creator, 
            swap.offerNftId
        );
        
        // Update swap status
        swap.status = SwapStatus.CANCELLED;
        
        emit SwapCancelled(_swapId, msg.sender);
    }
    
    /**
     * @dev Mark a swap as expired (can be called by anyone)
     * @param _swapId ID of the swap offer to expire
     */
    function expireSwap(uint256 _swapId) external nonReentrant {
        SwapOffer storage swap = swapOffers[_swapId];
        
        require(_swapId < _swapIdCounter, "Swap does not exist");
        require(swap.status == SwapStatus.ACTIVE, "Swap is not active");
        require(block.timestamp >= swap.expiresAt, "Swap has not expired yet");
        
        // Transfer NFT back to creator
        IERC721(swap.offerNftContract).safeTransferFrom(
            address(this), 
            swap.creator, 
            swap.offerNftId
        );
        
        // Update swap status
        swap.status = SwapStatus.EXPIRED;
        
        emit SwapExpired(_swapId);
    }
    
    /**
     * @dev Update the platform fee percentage (only callable by owner)
     * @param _newFeePercentage New fee percentage in basis points (100 = 1%)
     */
    function updatePlatformFee(uint256 _newFeePercentage) external onlyOwner {
        require(_newFeePercentage <= 1000, "Fee percentage cannot exceed 10%");
        revert("Fee is fixed for this deployment");
    }
    
    /**
     * @dev Update the treasury address (only callable by owner)
     * @param _newTreasury New treasury address
     */
    function updateTreasury(address _newTreasury) external onlyOwner {
        require(_newTreasury != address(0), "Cannot set treasury to zero address");
        treasury = _newTreasury;
    }
    
    /**
     * @dev Get details of a swap
     * @param _swapId ID of the swap
     * @return swap The swap offer details
     */
    function getSwap(uint256 _swapId) external view returns (SwapOffer memory) {
        require(_swapId < _swapIdCounter, "Swap does not exist");
        return swapOffers[_swapId];
    }
    
    /**
     * @dev Get the current swap count
     * @return The current number of swaps
     */
    function getSwapCount() external view returns (uint256) {
        return _swapIdCounter;
    }
    
}
