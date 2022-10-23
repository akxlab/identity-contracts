// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface INftIdentity {
	event IdentityCreated(address indexed to, bytes32 ID, address nftAddress);

	function name() external view returns(string memory);
	function symbol() external view returns(string memory);
	function tokenURI(bytes32 ID) external view returns(string memory);


}