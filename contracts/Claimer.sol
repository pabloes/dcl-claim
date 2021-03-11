pragma solidity ^0.5.16;

interface ERC721Collection {
    function issueToken(address _beneficiary, string calldata _wearableId) external;
}

contract Claimer {
    ERC721Collection public collection;
    mapping (address => mapping(string => uint8)) private addressClaims; //player -> wearableId -> numClaimed
    address public signerAddress;
    uint8 public mintLimit = 13;
    uint8 public totalMints = 0; 
    bytes32 private typeHash = keccak256(abi.encodePacked('string wearableId', 'uint8 nonceCount', 'address winnerAddress'));
    
    constructor(ERC721Collection _collection) public {
        signerAddress = msg.sender;
        collection = _collection;
    }

    function setSigner(address newSigner) external {
        require(msg.sender == signerAddress);
        signerAddress = newSigner;
    }

    function setMintLimit(uint8 newLimit) external {
        require(msg.sender == signerAddress);
        mintLimit = newLimit;
    }
       
    function claim(string calldata wearableId, uint8 nonceCount, bytes calldata signature) external {
        require(totalMints < mintLimit);
        address winnerAddress = msg.sender;
        require(getClaimCount(wearableId, winnerAddress) == nonceCount, "wrong number");        
        require(recoverAddressFromTypedSign(signature, wearableId, nonceCount, winnerAddress) == signerAddress, "wrong signature");
        totalMints++;
        addressClaims[msg.sender][wearableId]++;
        collection.issueToken(winnerAddress, wearableId);        
    }

    function recoverAddressFromTypedSign(bytes memory _sign, string memory wearableId, uint8 nonceCount, address winnerAddress) private view returns (address) {        
        bytes32 valueHash = keccak256(abi.encodePacked(wearableId, nonceCount, winnerAddress));
        return recover(keccak256(abi.encodePacked(typeHash, valueHash)), _sign);
    }

    function getClaimCount(string memory wearableId, address winnerAddress) public view returns (uint8){
        return addressClaims[winnerAddress][wearableId];
    }

    function recover(bytes32 hash, bytes memory signature) private pure returns (address) {
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

    function splitSignature(bytes memory sig) private pure returns (uint8, bytes32, bytes32) {
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
