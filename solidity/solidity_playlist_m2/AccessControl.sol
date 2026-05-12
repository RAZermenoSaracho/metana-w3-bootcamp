// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract AccessControl {
    event GrantRole(bytes32 indexed role, address indexed account);
    event RevokeRole(bytes32 indexed role, address indexed account);

    mapping(bytes32 => mapping(address => bool)) public roles;

    bytes32 private constant ADMIN = keccak256(abi.encodePacked("admin"));
    bytes32 private constant USER = keccak256(abi.encodePacked("user"));

    modifier onlyRole(bytes32 role) {
        require(roles[role][msg.sender], "AccessControl: Access denied");
        _;
    }

    constructor() {
        _grantRole(ADMIN, msg.sender);
    }

    function _grantRole(bytes32 role, address account) internal {
        roles[role][account] = true;
        emit GrantRole(role, account);
    }

    function grantRole(bytes32 role, address account) public onlyRole(ADMIN) {
        _grantRole(role, account);
    }

    function _revokeRole(bytes32 role, address account) internal {
        roles[role][account] = false;
        emit RevokeRole(role, account);
    }

    function revokeRole(bytes32 role, address account) public onlyRole(ADMIN) {
        _revokeRole(role, account);
    }
}