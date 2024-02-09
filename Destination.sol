// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./BridgeToken.sol";

contract Destination is AccessControl {
    bytes32 public constant WARDEN_ROLE = keccak256("BRIDGE_WARDEN_ROLE");
    bytes32 public constant CREATOR_ROLE = keccak256("CREATOR_ROLE");
    bytes32 public constant UNWRAPPER_ROLE = keccak256("UNWRAPPER_ROLE");

	mapping( address => address) public underlying_tokens;
	mapping( address => address) public wrapped_tokens;
	address[] public tokens;

	event Creation( address indexed underlying_token, address indexed wrapped_token );
	event Wrap( address indexed underlying_token, address indexed wrapped_token, address indexed to, uint256 amount );
	event Unwrap( address indexed underlying_token, address indexed wrapped_token, address frm, address indexed to, uint256 amount );

    constructor( address admin ) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(CREATOR_ROLE, admin);
        _grantRole(WARDEN_ROLE, admin);
        _grantRole(UNWRAPPER_ROLE, admin); // Grant the UNWRAPPER_ROLE to the admin
    }

	function createToken(address _underlying_token, string memory name, string memory symbol ) public onlyRole(CREATOR_ROLE) returns(address) {
    
        BridgeToken newBridgeToken = new BridgeToken(_underlying_token, name, symbol, msg.sender);
        address newBridgeTokenAddress = address(newBridgeToken);
        underlying_tokens[_underlying_token] = newBridgeTokenAddress;
        wrapped_tokens[newBridgeTokenAddress] = _underlying_token;
        tokens.push(_underlying_token);

        emit Creation(_underlying_token, newBridgeTokenAddress);

        return newBridgeTokenAddress;
	}
        
	function wrap(address _underlying_token, address _recipient, uint256 _amount ) public onlyRole(WARDEN_ROLE) {
		require(underlying_tokens[_underlying_token] != address(0), "Underlying asset not registered");

        BridgeToken wrappedToken = BridgeToken(underlying_tokens[_underlying_token]);
        wrappedToken.mint(_recipient, _amount);

        emit Wrap(_underlying_token, address(wrappedToken), _recipient, _amount);

	}

	function unwrap2(address _wrapped_token, address _recipient, uint256 _amount ) public {
		//  Ensure the wrapped token address corresponds to a registered BridgeToken contract
        require(wrapped_tokens[_wrapped_token] != address(0), "Wrapped token not registered");

        // Create an instance of the BridgeToken to interact with
        BridgeToken wrappedToken = BridgeToken(_wrapped_token);

        // The caller must own the tokens they are trying to unwrap, 
        // the burn function within the BridgeToken contract will revert if the caller does not have enough tokens
        wrappedToken.burnFrom(msg.sender, _amount);

        emit Unwrap(wrapped_tokens[_wrapped_token], _wrapped_token, msg.sender, _recipient, _amount);

	}

    function unwrap(address _wrapped_token, address _recipient, uint256 _amount) public {
        // Ensure the wrapped token address corresponds to a registered BridgeToken contract
        require(wrapped_tokens[_wrapped_token] != address(0), "Wrapped token not registered");

        // Create an instance of the BridgeToken to interact with
        BridgeToken wrappedToken = BridgeToken(_wrapped_token);

        // Check if msg.sender has enough tokens to burn
        require(wrappedToken.balanceOf(msg.sender) >= _amount, "Insufficient token balance");

        // The caller must own the tokens they are trying to unwrap, 
        // the burn function within the BridgeToken contract will revert if the caller does not have enough tokens.
        // Additionally, we could check if the caller has approved the Destination contract to burn tokens on their behalf,
        // but since burnFrom is called by the contract itself and uses msg.sender's tokens, this is not necessary here.

        wrappedToken.burnFrom(msg.sender, _amount);

        emit Unwrap(wrapped_tokens[_wrapped_token], _wrapped_token, msg.sender, _recipient, _amount);
    }

    function unwrap3(address _wrapped_token, address _recipient, uint256 _amount) public onlyRole(UNWRAPPER_ROLE) {
        // Ensure the wrapped token address corresponds to a registered BridgeToken contract
        require(wrapped_tokens[_wrapped_token] != address(0), "Wrapped token not registered");

        // Create an instance of the BridgeToken to interact with
        BridgeToken wrappedToken = BridgeToken(_wrapped_token);

        // The caller must own the tokens they are trying to unwrap, 
        // the burn function within the BridgeToken contract will revert if the caller does not have enough tokens.
        wrappedToken.burnFrom(msg.sender, _amount);

        emit Unwrap(wrapped_tokens[_wrapped_token], _wrapped_token, msg.sender, _recipient, _amount);
    }







}


