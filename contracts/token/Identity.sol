// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../interfaces/INftIdentity.sol";


contract Identity is INftIdentity, ERC1155, Ownable {

	using Strings for uint256;
	using Counters for Counters.Counter;

	enum IdentityTypes {
		NONE,
		USER,
		FOUNDER,
		MODERATOR,
		ADMIN,
		OWNER
	}

	mapping(uint256 => bool) internal _exists;
	mapping(bytes32 => uint256) internal _Id_to_tokenId;
	mapping(uint256 => bytes32) internal _tokenId_to_Id;
	mapping(IdentityTypes => uint256) internal _countPerIDTypes;
	mapping(string => uint256) internal _usernameToTokenId;
	mapping(uint256 => IdentityTypes) internal _tokenIdToIdTypes;
	mapping(address => uint256) internal _addressToTokenId;
	mapping(address => bool) internal _hasIdentity;
	mapping(address => string) internal _addressToUsername;
	mapping(address => bool) internal _hasUsername;
	mapping(string => bool) internal _usernameExists;
	mapping(uint256 => address) internal _tokenIdToAddress;



	Counters.Counter private currentTokenId;

	bytes32 public constant IDENTITY_PREFIX_ID = keccak256("akx.identity.interface.id");
	string public name = "AKX IDENTITY SERVICE";
	string public symbol = "AKX.ID";
	string public baseMetadataURI;


	constructor(string memory uri_) ERC1155(uri_) {
		setBaseMetadataURI(uri_);
	}

	function tokenURI(bytes32 ID) public view  returns(string memory) {
		string memory idStr =uint256(ID).toString();
		string memory tid = _Id_to_tokenId[ID].toString();

		return string.concat(baseMetadataURI, idStr, tid);
	}

	function bytes32ToString(bytes32 _bytes32) public pure returns (string memory) {
		uint8 i = 0;
		while(i < 32 && _bytes32[i] != 0) {
			i++;
		}
		bytes memory bytesArray = new bytes(i);
		for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
			bytesArray[i] = _bytes32[i];
		}
		return string(bytesArray);
	}

	function uri(uint256 tokenId) public view override returns(string memory) {
		return tokenURI(_tokenId_to_Id[tokenId]);
	}

	function totalIdentities(uint256 idType) public view returns(uint256) {
		IdentityTypes _t = IdentityTypes(idType);
		return _countPerIDTypes[_t];
	}

	function setBaseMetadataURI(
		string memory _newBaseMetadataURI
	) public onlyOwner {
		_setBaseMetadataURI(_newBaseMetadataURI);
	}

	function _setBaseMetadataURI(string memory _newBaseMetadataURI) internal {
		baseMetadataURI = _newBaseMetadataURI;
	}

	function _createId(uint256 tokenId, IdentityTypes idType, bytes32 pwdHash) internal pure returns(bytes32) {
		bytes memory IDpart1 = abi.encodePacked(tokenId, idType);
		bytes memory IDpart2 = abi.encodePacked(IDpart1, pwdHash);
		bytes32 ID = keccak256(abi.encodePacked(IDENTITY_PREFIX_ID, IDpart1, IDpart2));
		return ID;
	}

	function _validateId(bytes32 ID, bytes32 pwdHash) internal view returns(bool) {
		uint256 tokenId_ = _Id_to_tokenId[ID];
		bytes32 toCompare = _createId(tokenId_, _tokenIdToIdTypes[tokenId_], pwdHash);
		return ID == toCompare;
	}

	function useIdentity(address _owner, bytes32 pwdHash) public view returns(bytes32) {
		if(_hasIdentity[msg.sender] != true) {
			revert("invalid identity request");
		}

		uint256 tokenId_ = _addressToTokenId[_owner];
		bytes32 _ID = _tokenId_to_Id[tokenId_];
		if(!_validateId(_ID, pwdHash)) {
			revert("INVALID_ID");
		}
		return _ID;
	}

	function getIDRole(uint256 tokenId) public view returns(IdentityTypes) {
		return _tokenIdToIdTypes[tokenId];
	}

	function isAdmin(uint256 tokenId) public view returns(bool) {
		if(_tokenIdToIdTypes[tokenId] != IdentityTypes.ADMIN) {
			return false;
		}
		return true;
	}

	function isModerator(uint256 tokenId) public view returns(bool) {
		if(_tokenIdToIdTypes[tokenId] != IdentityTypes.MODERATOR) {
			return false;
		}
		return true;
	}

	function isFounder(uint256 tokenId) public view returns(bool) {
		if(_tokenIdToIdTypes[tokenId] != IdentityTypes.FOUNDER) {
			return false;
		}
		return true;
	}

	function isOwner(uint256 tokenId) public view returns(bool) {
		if(_tokenIdToIdTypes[tokenId] != IdentityTypes.OWNER) {
			return false;
		}
		return true;
	}

	function isUser(uint256 tokenId) public view returns(bool) {
		if(_tokenIdToIdTypes[tokenId] == IdentityTypes.NONE) {
			return false;
		}
		return true;
	}

	function create(address _owner, bytes32 pwdHash, bytes memory data) external onlyOwner returns(uint256 __id, bool success) {
		if(_hasIdentity[_owner] == true) {
			revert("already have an identity");
		}
		uint256 _id = currentTokenId.current();
		currentTokenId.increment();
		_hasIdentity[_owner] = true;

		bytes32 bID = _createId(_id, IdentityTypes.USER, pwdHash);
		super._mint(_owner, _id, uint256(1), data);
		_tokenId_to_Id[_id] = bID;
		_Id_to_tokenId[bID] = _id;
		_countPerIDTypes[IdentityTypes.USER] = _countPerIDTypes[IdentityTypes.USER]+=1;
		_exists[_id] = true;
		_tokenIdToIdTypes[_id] = IdentityTypes.USER;
		_addressToTokenId[_owner] = _id;
		_tokenIdToAddress[_id] = _owner;
		emit IdentityCreated(_owner, bID, address(this));
		__id = _id;
		success = true;
	}

	function setUsername(address _owner, string memory _username) public returns (string memory __username, bool success) {
		require(_owner != address(0), "no zero address");
		require(!_hasUsername[_owner], "already have a username");
		require(!_usernameExists[_username], "username already exists");
		_hasUsername[_owner] = true;
		_usernameExists[_username] = true;
		_usernameToTokenId[_username] = _addressToTokenId[_owner];
		_addressToUsername[_owner] = _username;
		__username = _username;
		success = true;
	}

	function getUsername(address _owner) public view returns(string memory _username, bool success) {
		require(_owner != address(0), "no zero address");
		require(_hasUsername[_owner], "do not have a username");
		_username = _addressToUsername[_owner];
		success = true;
	}

	function getUsername(uint256 tokenId) public view returns(string memory _username, bool success){
		address _owner = _tokenIdToAddress[tokenId];
		require(_hasUsername[_owner], "do not have a username");
		_username = _addressToUsername[_tokenIdToAddress[tokenId]];
		success = true;
	}

	function editUsername(string memory oldUsername, string memory _username) public returns(string memory __username, bool success) {
		require(_hasUsername[msg.sender], "do not have a username");
		bytes32 _u = keccak256(abi.encode(_addressToUsername[msg.sender]));
		require(_u  == keccak256(abi.encode(oldUsername)) && keccak256(abi.encode(oldUsername)) != keccak256(abi.encode(_username)), "invalid username");
		require(_usernameToTokenId[oldUsername] == _addressToTokenId[msg.sender], "do not own token");
		require(!_usernameExists[_username], "username already exists");
		_usernameExists[_username] = true;
		_usernameToTokenId[_username] = _addressToTokenId[msg.sender];
		_addressToUsername[msg.sender] = _username;
		__username = _username;
		success = true;
	}

	function getID(address _sender) public view returns(bytes32 ID) {
		ID = _tokenId_to_Id[_addressToTokenId[_sender]];
	}





}