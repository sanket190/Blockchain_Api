// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EnergyMarket {
    struct Offer {
        address seller;
        uint256 quantity;
        uint256 pricePerUnit;
        uint256 duration;
        uint256 timestamp;
        uint256 offerId;
        bool active;
    }

    struct Bid {
        address buyer;
        uint256 quantity;
        uint256 pricePerUnit;
        bool active;
    }

    Offer[] public offers;
    mapping (uint256 => Bid[]) public bids;
    uint256 offerId=0;

    function createOffer(uint256 _quantity, uint256 _pricePerUnit, uint256 _duration) public {
        offers.push(Offer({
            seller: msg.sender,
            quantity: _quantity,
            pricePerUnit: _pricePerUnit,
            duration: _duration,
            timestamp: block.timestamp,
            offerId: offerId,
            active: true
        }));
        offerId+=1;
    }

    function getOfferLength() public view returns (uint256) {
        return offers.length;
    }
  

    function placeBid(uint256 _offerId, uint256 _quantity, uint256 _pricePerUnit, bool _active) public {
        require(offers[_offerId].active, "Offer is no longer active");

        bids[_offerId].push(Bid({
            buyer: msg.sender,
            quantity: _quantity,
            pricePerUnit: _pricePerUnit,
            active: _active
        }));
    }

    
    function determineMarketPrice(uint256 totalDemand, uint256 totalSupply, uint256 minPrice, uint256 maxPrice) internal pure returns (uint256) {
        uint256 marketPrice;

        if (totalDemand == 0) {
            marketPrice = minPrice;
        } else if (totalDemand >= totalSupply) {
            marketPrice = maxPrice;
        } else {
            uint256 priceRange = maxPrice - minPrice;
            uint256 demandRatio = totalDemand * (10**18) / totalSupply;
            marketPrice = minPrice + (priceRange * demandRatio / (10**18));
        }

        return marketPrice;
    }

    function selectBid(uint256 _offerId) public payable {
        Offer storage offer = offers[_offerId];
        require(offer.active, "Offer is not active");

        uint256 totalDemand = 0;
        uint256 totalSupply = offer.quantity;
        uint256 minPrice = 0;
        uint256 maxPrice = 0;
        
        // calculate total demand and min/max price
        for (uint256 i = 0; i < bids[_offerId].length; i++) {
            Bid storage bid = bids[_offerId][i];
            if (bid.active) {
                totalDemand += bid.quantity;
                if (minPrice == 0 || bid.pricePerUnit < minPrice) {
                    minPrice = bid.pricePerUnit;
                }
                if (bid.pricePerUnit > maxPrice) {
                    maxPrice = bid.pricePerUnit;
                }
            }
        }

        require(totalDemand > 0, "No active bids found");

        // Calculate the uniform price using determineMarketPrice()
        uint256 marketPrice = determineMarketPrice(totalDemand, totalSupply, minPrice, maxPrice);

        // Verify that the buyer has sufficient funds to purchase the energy
        // uint256 totalCost = totalDemand * uniformPrice;
        // require(msg.value >= totalCost, "Insufficient funds");

        // // Transfer the energy from the seller to the buyer
        // offer.quantity -= totalDemand;
        // for (uint256 i = 0; i < bids[_offerId].length; i++) {
        //     Bid storage bid = bids[_offerId][i];
        //     if (bid.active) {
        //         bid.active = false;
        //         payable(bid.buyer).transfer(bid.quantity * uniformPrice);
        //     }
        // }
        for (uint256 i = 0; i < bids[_offerId].length; i++) {
            Bid storage bid = bids[_offerId][i];
            if (bid.active) {
                uint256 energyAllocated = (bid.quantity * marketPrice) / 1 ether;
                if (offer.quantity >= energyAllocated) {
                    payable(bid.buyer).transfer(energyAllocated * 1 ether);
                    offer.quantity -= energyAllocated;
                } else {
                    uint256 partialAllocation = (offer.quantity * 1 ether) / marketPrice;
                    payable(bid.buyer).transfer(partialAllocation);
                    offer.quantity = 0;
                }
                bid.active = false;
            }
        }

    // Mark the offer as inactive
    offer.active = false;
    }




}