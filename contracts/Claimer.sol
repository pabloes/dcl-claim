pragma solidity ^0.5.16;

interface ERC721Collection {
    function issueToken(address _beneficiary, string calldata _wearableId) external;
}

contract Claimer {
    mapping(address => mapping(string => uint8)) addressClaims; //player -> wearableId -> numClaimed
    address public signerAddress;
    uint8 public mintLimit = 12;
    uint8 public totalMints = 0;
    ERC721Collection public collection;
    
    constructor(ERC721Collection _collection) public{
        signerAddress = msg.sender;
        collection = _collection;
    }

    function setMintLimit(uint8 limit) public {
        require(msg.sender == signerAddress);
        mintLimit = limit;
    }
       
    function claim(string memory wearableId, uint8 nonceCount, bytes memory signature) public {
        address winnerAdress = msg.sender;        
        require(getClaimCount(wearableId) == nonceCount, "wrong number");        
        require(recoverAddressFromTypedSign(signature, wearableId, nonceCount, winnerAdress) == signerAddress, "wrong signature");
        totalMints = totalMints + 1;
        addClaimCount(wearableId);
        collection.issueToken(winnerAdress, wearableId);        
    }

    function recoverAddressFromTypedSign(bytes memory _sign, string memory wearableId, uint8 nonceCount, address winnerAddress) public pure returns (address) {
        bytes32 typeHash = keccak256(abi.encodePacked('string wearableId', 'uint8 nonceCount', 'address winnerAddress'));
        bytes32 valueHash = keccak256(abi.encodePacked(wearableId, nonceCount, winnerAddress));
        return recover(keccak256(abi.encodePacked(typeHash, valueHash)), _sign);
    }

    function getClaimCount(string memory wearableId) public view returns (uint8){
        return addressClaims[msg.sender][wearableId];
    }
    
    function addClaimCount(string memory wearableId) public returns (uint8) {
        uint8 currentCount = addressClaims[msg.sender][wearableId];
        uint8 newValue = currentCount + 1;
        addressClaims[msg.sender][wearableId] = newValue;
        return newValue;
    }

    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        (v, r, s) = splitSignature(signature);

        if (v < 27) {
            v += 27;
        }

        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            return ecrecover(hash, v, r, s);
        }
    }

    function splitSignature(bytes memory sig) internal pure returns (uint8, bytes32, bytes32) {
        require(sig.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
        return (v, r, s);
    }
    
}