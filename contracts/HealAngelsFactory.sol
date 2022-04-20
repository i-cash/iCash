// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @co-author: interchained
/// @co-author: billaure
import "./standard/ERC721.sol";
import "./interface/IFactoryERC721.sol";

/*
                                                                            
:::    ::: ::::::::::     :::     :::                 :::     ::::    :::  ::::::::  :::::::::: :::        ::::::::  
:+:    :+: :+:          :+: :+:   :+:               :+: :+:   :+:+:   :+: :+:    :+: :+:        :+:       :+:    :+: 
+:+    +:+ +:+         +:+   +:+  +:+              +:+   +:+  :+:+:+  +:+ +:+        +:+        +:+       +:+        
+#++:++#++ +#++:++#   +#++:++#++: +#+             +#++:++#++: +#+ +:+ +#+ :#:        +#++:++#   +#+       +#++:++#++ 
+#+    +#+ +#+        +#+     +#+ +#+             +#+     +#+ +#+  +#+#+# +#+   +#+# +#+        +#+              +#+ 
#+#    #+# #+#        #+#     #+# #+#             #+#     #+# #+#   #+#+# #+#    #+# #+#        #+#       #+#    #+# 
###    ### ########## ###     ### ##########      ###     ### ###    ####  ########  ########## ########## ########    

                    ==                     ==
                 <^\()/^>               <^\()/^>
                  \/  \/                 \/  \/
                   /__\      .  '  .      /__\ 
      ==            /\    .     |     .    /\            ==
   <^\()/^>       !_\/       '  |  '       \/_!       <^\()/^>
    \/  \/     !_/I_||  .  '   \'/   '  .  ||_I\_!     \/  \/
     /__\     /I_/| ||      -== + ==-      || |\_I\     /__\
     /_ \   !//|  | ||  '  .   /.\   .  '  || |  |\\!   /_ \
    (-   ) /I/ |  | ||       .  |  .       || |  | \I\ (=   )
     \__/!//|  |  | ||    '     |     '    || |  |  |\\!\__/
     /  \I/ |  |  | ||       '  .  '    *  || |  |  | \I/  \
    {_ __}  |  |  | ||                     || |  |  |  {____}
 _!__|= ||  |  |  | ||   *      +          || |  |  |  ||  |__!_
 _I__|  ||__|__|__|_||          A          ||_|__|__|__||- |__I_
 -|--|- ||--|--|--|-||       __/_\__  *    ||-|--|--|--||= |--|-
  |  |  ||  |  |  | ||      /\-'o'-/\      || |  |  |  ||  |  |
  |  |= ||  |  |  | ||     _||:<_>:||_     || |  |  |  ||= |  |
  |  |- ||  |  |  | || *  /\_/=====\_/\  * || |  |  |  ||= |  |
  |  |- ||  |  |  | ||  __|:_:_[I]_:_:|__  || |  |  |  ||- |  | 
 _|__|  ||__|__|__|_||:::::::::::::::::::::||_|__|__|__||  |__|_
 -|--|= ||--|--|--|-||:::::::::::::::::::::||-|--|--|--||- |--|-
  int|- ||  |  |  | ||:::::::::::::::::::::|| |  |  |  ||= |  | 
~~~~~~~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^~~~~~~~~~
*/

/// @author Interchained modified a version of original code by 1001.digital
/// @title A token tracker that limits the token supply and increments token IDs on each new mint.
abstract contract HealAngelsSupply {
	/*
	 * Public Variables
	 */
	uint128 public immutable MAX_ANGELS_SUPPLY = 1000; // Heal Angels collection size (including Whitelist)
	uint128 public immutable MAX_ANGELS_PER_MINTER = 5; // Heal Angels anti-whale  
	uint128 public immutable NUMBER_OF_WHITELIST_ANGELS = 50; // there are 50 Heal Angels available to the Whitelist 

	// Keeps track of how many we have minted
	uint256 public _tokenCount;

	/// @dev The maximum count of tokens this token tracker will issue.
	uint256 public immutable _maxAvailableSupply;

	/// Initializes the contract
	constructor() {
		_maxAvailableSupply = MAX_ANGELS_SUPPLY;
	}

	function maxAvailableSupply() public view returns (uint256) {
		return _maxAvailableSupply;
	}

	/// @dev Get the current token count
	/// @return the created token count
	function tokenCount() public view returns (uint256) {
		return _tokenCount;
	}

	/// @dev Check whether tokens are still available
	/// @return the available token count
	function availableTokenCount() public view returns (uint256) {
		return maxAvailableSupply() - tokenCount();
	}

	/// @dev Increment the token count and fetch the latest count
	/// @return the next token id
	function nextToken() internal virtual ensureAvailability returns (uint256) {
		return _tokenCount++;
	}

	/// @dev Check whether another token is still available
	modifier ensureAvailability() {
		require(availableTokenCount() > 0, 'No more tokens available');
		_;
	}

	/// @param amount Check whether number of tokens are still available
	/// @dev Check whether tokens are still available
	modifier ensureAvailabilityFor(uint256 amount) {
		require(availableTokenCount() >= amount,'Requested number of tokens not available');
		_;
	}
}
/// @author Interchained modified version of original code by 1001.digital
/// @title Randomly assign tokenIDs from a given set of tokens.
abstract contract AssignRandomAngel is HealAngelsSupply {
	// Used for random index assignment
	mapping(uint256 => uint256) private tokenMatrix;

	// The initial token ID
	uint256 private immutable startFrom;

	/// Initializes the contract
	constructor() HealAngelsSupply(MAX_ANGELS_SUPPLY) {
		startFrom = 0;
	}

	/// Get the next token ID
	/// @dev Randomly gets a new token ID and keeps track of the ones that are still available.
	/// @return the next token ID
	function nextToken() internal override returns (uint256) {
		uint256 maxIndex = maxAvailableSupply() - tokenCount();
		uint256 random = uint256(
			keccak256(
				abi.encodePacked(
					msg.sender,
					block.coinbase,
					block.difficulty,
					block.gaslimit,
					block.timestamp
				)
			)
		) % maxIndex;

		uint256 value = 0;
		if (tokenMatrix[random] == 0) {
			// If this matrix position is empty, set the value to the generated random number.
			value = random;
		} else {
			// Otherwise, use the previously stored number from the matrix.
			value = tokenMatrix[random];
		}

		// If the last available tokenID is still unused...
		if (tokenMatrix[maxIndex - 1] == 0) {
			// ...store that ID in the current matrix position.
			tokenMatrix[random] = maxIndex - 1;
		} else {
			// ...otherwise copy over the stored number to the current matrix position.
			tokenMatrix[random] = tokenMatrix[maxIndex - 1];
		}

		// Increment counts (ie. qty minted)
		super.nextToken();

		return value + startFrom;
	}
}
contract HealAngelsFactory is IHealAngels, Ownable, AssignRandomAngel, ReentrancyGuard {
    using Address for address;
    using Strings for uint256;
    using SafeMath for uint8;
    using SafeMath for uint16;
    using SafeMath for uint128;
    using SafeMath for uint248;
    using Counters for Counters.Counter;

    event MintingLaunched(bool update);
    event MintingLocked(bool status);
    event MetadataFROZEN(bool freezer);
    event OperatorClaimedDonations(bool claimed, address recipient, uint256 amount);
    event OperatorSharedDonations(bool claimed, address recipient, uint256 amount);
    event OperatorWithdrewAllDonations(bool claimed, address recipient, uint256 amount);

	struct MintStats {
		uint256 _mintQtyByAddress;
		uint256 tokenId;
	}

	enum SeedPhase {
		Locked,
		Whitelist,
		Public
	}

	/*
	 * Variables
	 */
	IHealAngels public nftFactoryContract;
	HealAngels nftContractAddress;
    	address payable private _cryptocurrencyDevelopers = payable(msg.sender);
	address payable _healAngelsDonationsAddress;
    	address payable public proxyRegistryAddress;

	string private baseURI = "https://raw.githubusercontent.com/Heal-The-World-Charity-Foundation/Heal-Angel/main/meta/";
	string public _tokenBaseURI;

	bool private seeded = false;
	bool private soldOut = false;
	bool private claimActive = false;
	bool private freezeMeta = false;

    	Counters.Counter private _tokenIdCounter;
	SeedPhase public phase = SeedPhase.Locked;

    	uint128 public _burnedSupply;
	uint128 public totalDonated;
	uint128 public mintDonation = 0.1 ether;
    	uint128 public _maxWhitelist = NUMBER_OF_WHITELIST_ANGELS;  
	uint248 public developmentDonationsFactor = 90; // 10% donated to devs

    	uint256 public _totalSupply;
    	uint256 public _maxSupply = MAX_ANGELS_SUPPLY;

    	mapping (address => string) private _holdersNFT;
    	mapping (uint256 => string) private _tokenURIs;
	mapping(address => MintStats) public minterAddress;
    	mapping (address => bool) public _whitelisted;

	/*
	 * Constructor
	 */
	constructor(address operator) Ownable(payable(msg.sender)) {
        _tokenIdCounter.increment();
        if (block.chainid == 4) {
            proxyRegistryAddress = payable(0x1E525EEAF261cA41b809884CBDE9DD9E1619573A);
        } else if(block.chainid == 137) {
            proxyRegistryAddress = payable(0x58807baD0B376efc12F5AD86aAc70E78ed67deaE);
        } else if(block.chainid == 1) {
            proxyRegistryAddress = payable(0xa5409ec958C83C3f309868babACA7c86DCB077c1);
        } else {
            proxyRegistryAddress = payable(0xa5409ec958C83C3f309868babACA7c86DCB077c1);
        }
        nftContractAddress = new HealAngels();
		_tokenBaseURI = baseURI;
        _healAngelsDonationsAddress = payable(this);
		transferOwnership(payable(operator));
	}

	// ======================================================== Modifiers

	/// Modifier to validate Eth payments on payable functions
	/// @dev compares the product of the state variable `_mintDonation` and supplied `count` to msg.value
	/// @param count factor to multiply by
	modifier verifyAmountETH(uint128 count) {
		require(uint128(mintDonation) * count <= msg.value,'Ether value sent is not correct');
		_;
	}

	// ======================================================== Owner Functions

	// Set Development Donations
	// @dev altering developmentDonationsFactor will adjust contributions towards development.
	// Donations are calculated with the following equations below.
	// (EXAMPLE) uint256 donationAmount = 0.1 ether;
	// organizationDonations = (donationAmount * developmentDonationsFactor) / 100; (organization receives 0.09 ether)
	// developmentDonations = donationAmount - organizationDonations; (organization receives 0.01 ether)
	function setDevelopmentDonations(uint248 developmentDonationsDivisor) public onlyOwner {
		developmentDonationsFactor = developmentDonationsDivisor;
	}

	/// Approve to Whitelist 
	/// @dev approve wallet to be whitelisted
	function whitelistUser(address _wallet) public onlyOwner {
        _whitelisted[_wallet] = true;
    	}

	/// Remove from Whitelist 
	/// @dev deauthorize whitelisted account
    	function removeWhitelistUser(address _wallet) public onlyOwner {
        	_whitelisted[_wallet] = false;
    	}

	/// Set the base URI for the metadata
	/// @dev modifies the state of the `_tokenBaseURI` variable
	/// @param URI the URI to set as the base token URI
	function setBaseURI(string memory URI) external onlyOwner {
		require(!freezeMeta, 'Metadata is frozen');
		_tokenBaseURI = URI;
	}

	/// Adjust the mint donation
	/// @dev modifies the state of the `mintDonation` variable
	/// @notice sets the donation rate for minting a token
	/// @param newDonation_ The new price for minting
	function adjustMintDonation(uint128 newDonation_) external onlyOwner {
		mintDonation = newDonation_;
	}

	/// Launch Phase
	/// @dev Advance the seed phase state
	/// @notice Launches Whitelist seed phase  
	function launchSeedPhase() external onlyOwner returns(bool)  {
		phase = SeedPhase.Whitelist;
		return true;
	}

	/// Advance Phase
	/// @dev Advance the seed phase state
	/// @notice Advances seed phase state 
	function seedPhaseSequence() private {       
		if(phase == SeedPhase.Whitelist && totalSupply() >= NUMBER_OF_WHITELIST_ANGELS){
			seeded = true;
            phase == SeedPhase.Public;
		} else if(phase == SeedPhase.Whitelist && _tokenIdCounter.current() >= NUMBER_OF_WHITELIST_ANGELS){
			seeded = true;
            phase == SeedPhase.Public;
		} else {
			seeded = false;
            phase == SeedPhase.Whitelist;
		}
	}
	
	/// Public Phase (backup fn)
	/// @dev Advance the seed phase state
	/// @notice Launches Public seed phase  
	function launchPublicPhase() external onlyOwner returns(bool) {
		phase = SeedPhase.Public;
		emit MintingLaunched(true);
		return true;
	}

	/// Lock Phase
	/// @dev Lock the seed phase state
	/// @notice Locks seed phase state 
	function lockSeedPhase() external onlyOwner returns(bool) {
		phase = SeedPhase.Locked;
    	emit MintingLocked(true);
		return true;
	}

	/// Freezes the metadata
	/// @dev sets the state of `freezeMeta` to true
	function freezeMetadata(bool status) external onlyOwner returns(bool) {
		require(!freezeMeta, 'Metadata is already frozen');
		freezeMeta = true;
    	emit MetadataFROZEN(true);
		return true;
	}

	/// Make a payment
	/// @dev internal fn called by `claimPayments` to send Ether to an address
	function withdrawETH(address payable recipient, uint256 amt_) public onlyOwner {
		(bool success, ) = recipient.call{value: amt_}('');
		require(success, 'Transfer failed.');
    	emit OperatorClaimedDonations(true, recipient, amt_);
	}

	/// Disburse payments
	/// @dev transfers amounts that correspond to addresses passeed in as args
	/// @param payees_ recipient addresses
	/// @param amounts_ amount to payout to address with corresponding index in the `payees_` array
	function claimPayments(address payable[] memory payees_, uint256[] memory amounts_) public onlyOwner {
		require(payees_.length == amounts_.length, 'Payees and amounts length mismatch');
		for (uint256 i; i < payees_.length; i++) {
			withdrawETH(payable(payees_[i]), amounts_[i]);
    		emit OperatorSharedDonations(true, payees_[i], amounts_[i]);
		}
	}

	/// Make a payment
	/// @dev internal fn called by `claimPayments` to send Ether to an address
	function withdrawAllETH(address payable recipient) public onlyOwner {
        // get the amount of Ether stored in this contract
        uint256 contractETHBalance = address(this).balance;
		(bool success, ) = recipient.call{value: contractETHBalance}('');
		require(success, 'Transfer failed.');    	
		emit OperatorWithdrewAllDonations(true, recipient, contractETHBalance);
	}   
    
	/// Rescue any accidental tokens sent to contract
	/// @dev public fn called by `rescueStuckTokens` to extract ERC20 tokens to an address
    function rescueStuckTokens(address _tok, address payable recipient, uint256 amount) public payable onlyOwner {
        uint256 contractTokenBalance = IERC20(_tok).balanceOf(address(this));
        require(amount <= contractTokenBalance, "Request exceeds contract token balance.");
        // rescue stuck tokens 
        IERC20(_tok).transfer(recipient, amount);
    }

	// ======================================================== External / Public Functions
    
	/// DONATE 
    // public function to make donations to organization & development
    function donate() public payable returns(bool) {
    	uint248 contributions = uint248(msg.value);
	uint248 organizationDonations = uint248(contributions).mul(uint248(developmentDonationsFactor)).div(100);
	uint248 devDonations = uint248(contributions).sub(organizationDonations);
        (bool donatedToOrg,) = _healAngelsDonationsAddress.call{value: organizationDonations}("");
        require(donatedToOrg, "Invalid, failed to send organization donations. Kindly try again, or send coins & tokens directly to this contract Thank you! ");
        (bool donatedToDevs,) = _cryptocurrencyDevelopers.call{value: devDonations}("");
        require(donatedToDevs, "Invalid, failed to send develepment donations. Kindly try again, or send coins & tokens directly to this contract. Thank you! ");
		return true;
    }

	/// Get burned supply
    function burnedSupply() public pure returns (uint) {
        return _burnedSupply; 
    }

	/// Get total supply
    function totalSupply() public pure returns (uint) {
    	try _totalSupply.sub(_burnedSupply) returns (uint) {
		_totalSupply = _totalSupply.sub(_burnedSupply);
	} catch { 
		return _totalSupply;
	} 
    }

	/// Get max supply
    function getMaxSupply() public pure returns (uint) {
		return _maxSupply;
    }
  
	/// Get total donations 
    // public function to return the amount of donations
    function getTotalDonations() view public returns(uint128) {
        return totalDonated;
    }

	/// Mint exclusively for Whitelisted addresses
	/// @notice mints tokens with randomized token IDs to addresses eligible for presale
	/// @param count number of tokens to mint in transaction
	function mintWhitelist(uint256 count) public payable nonReentrant ensureAvailabilityFor(count) verifyAmountETH(count) returns(bool) {
		require(phase != SeedPhase.Locked, 'EXPIRED: SeedPhase Locked');
		require(msg.value != 0, "Invalid, not enough ETH included in transaction. ");
		require(_whitelisted[address(msg.sender)] == true, 'Whitelist only event, try again during the public event. ');
		if(phase == SeedPhase.Public){
		    return mintOnBehalf(msg.sender, count);
		}
		require(msg.value >= mintDonation, "Invalid, not enough ETH included in transaction. ");
		require(phase == SeedPhase.Whitelist, 'Whitelist event is not active. ');
		require(count <= MAX_ANGELS_PER_MINTER, 'Invalid, amount to mint exceeds whitelisted reserves! Tell your friends! ');
		require(minterAddress[msg.sender]._mintQtyByAddress.add(count) <= MAX_ANGELS_PER_MINTER, 'Max 5 Heal Angels could be minted by a single EOA. ');
        	require(_tokenIdCounter.current().add(count) <= MAX_ANGELS_SUPPLY, "Tokens number to mint exceeds number of public tokens. ");
		if(uint(totalSupply()) >= uint(NUMBER_OF_WHITELIST_ANGELS)){
		    seedPhaseSequence();
		    return mintOnBehalf(payable(msg.sender), count);
		}
		for (uint256 i; i < count; i++) {
		    minterAddress[msg.sender]._mintQtyByAddress += 1;   
		    _totalSupply += 1;   
		    _tokenIdCounter.increment();
		    uint256 id = nextToken();
		    assert(id <= MAX_ANGELS_SUPPLY);
		    nftContractAddress._safeMint(payable(msg.sender), id);
		    _holdersNFT[msg.sender] = id;
		    _setTokenURI(id, id.toString());
		}
		uint256 contributions = msg.value;
		uint256 organizationDonations = contributions.mul(developmentDonationsFactor).div(100);
		uint256 devDonations = contributions.sub(organizationDonations);
		(bool donatedToOrg,) = _healAngelsDonationsAddress.call{value: organizationDonations}("");
		require(donatedToOrg, "Invalid, failed to send organization donations. Please try again. Thank you! ");
		(bool donatedToDevs,) = _cryptocurrencyDevelopers.call{value: devDonations}("");
		require(donatedToDevs, "Invalid, failed to send develepment donations. Please try again. Thank you! ");
		totalDonated = totalDonated += msg.value;
		return true;
	}

	/// Public minting
	/// @notice mints tokens with random IDs to msg.sender
	/// @param count number of tokens to mint in transaction
	function mintOnBehalf(address payable receiver, uint256 count) public payable nonReentrant verifyAmountETH(count) ensureAvailabilityFor(count) returns(bool) {
		require(phase != SeedPhase.Locked, 'EXPIRED: SeedPhase Locked');
		require(msg.value != 0, "Invalid, not enough ETH included in transaction. ");
		require(phase == SeedPhase.Public, 'Public sale is not active');
		require(msg.value >= mintDonation, "Invalid, not enough ETH included in transaction. ");
		require(count <= MAX_ANGELS_PER_MINTER, 'Invalid, amount to mint exceeds whitelisted reserves! Tell your friends! ');
		require(minterAddress[msg.sender]._mintQtyByAddress.add(count) <= MAX_ANGELS_PER_MINTER, 'Max 5 Heal Angels could be minted by a single EOA.');
        	require(_tokenIdCounter.current().add(count) <= MAX_ANGELS_SUPPLY, "Tokens number to mint exceeds number of public tokens");
		
		for (uint256 i; i < count; i++) {    
			minterAddress[msg.sender]._mintQtyByAddress += 1;   
			_totalSupply += 1;    
			uint256 id = nextToken();
			assert(id <= MAX_ANGELS_SUPPLY);
			nftContractAddress._safeMint(payable(receiver), id);
			_holdersNFT[address(receiver)] = id;
			_setTokenURI(id, id.toString());
		}
		uint256 contributions = msg.value;
		uint256 organizationDonations = contributions.mul(developmentDonationsFactor).div(100);
		uint256 devDonations = contributions.sub(organizationDonations);
		(bool donatedToOrg,) = _healAngelsDonationsAddress.call{value: organizationDonations}("");
		require(donatedToOrg, "Invalid, failed to send organization donations. Please try again. Thank you! ");
		(bool donatedToDevs,) = _cryptocurrencyDevelopers.call{value: devDonations}("");
		require(donatedToDevs, "Invalid, failed to send develepment donations. Please try again. Thank you! ");
		totalDonated = totalDonated += msg.value;
		return true;
	}

	/// Public minting
	/// @notice mints tokens with random IDs to msg.sender
	/// @param count number of tokens to mint in transaction
	function mint(uint256 count) public payable nonReentrant verifyAmountETH(count) ensureAvailabilityFor(count) returns(bool) {
		require(phase != SeedPhase.Locked, 'EXPIRED: SeedPhase Locked');
		require(msg.value != 0, "Invalid, not enough ETH included in transaction. ");
		require(msg.value >= mintDonation, "Invalid, not enough ETH included in transaction. ");
		require(phase == SeedPhase.Public, 'Public sale is not active');
		require(count <= MAX_ANGELS_PER_MINTER, 'Invalid, amount to mint exceeds whitelisted reserves! Tell your friends! ');
		require(minterAddress[msg.sender]._mintQtyByAddress.add(count) <= MAX_ANGELS_PER_MINTER, 'Max 5 Heal Angels could be minted by a single EOA.');
        	require(_tokenIdCounter.current().add(count) <= MAX_ANGELS_SUPPLY, "Tokens number to mint exceeds number of public tokens");
		
        	for (uint256 i; i < count; i++) {      
		   	 minterAddress[msg.sender]._mintQtyByAddress += 1;   
            		_totalSupply += 1;    
			uint256 id = nextToken();
			assert(id <= MAX_ANGELS_SUPPLY);
			nftContractAddress._safeMint(payable(msg.sender), id);
			_holdersNFT[msg.sender] = id;
			_setTokenURI(id, id.toString());
		}
		uint256 contributions = msg.value;
		uint256 organizationDonations = contributions.mul(developmentDonationsFactor).div(100);
		uint256 devDonations = contributions.sub(organizationDonations);
		(bool donatedToOrg,) = _healAngelsDonationsAddress.call{value: organizationDonations}("");
		require(donatedToOrg, "Invalid, failed to send organization donations. Please try again. Thank you! ");
		(bool donatedToDevs,) = _cryptocurrencyDevelopers.call{value: devDonations}("");
		require(donatedToDevs, "Invalid, failed to send develepment donations. Please try again. Thank you! ");
		totalDonated = totalDonated += msg.value;
		return true;
	}    
    
	/// Public burning
	/// @notice burns tokens to dead address, reduces totalSupply
	/// @param tokenId tokens ID to burn in transaction
    	function burn(uint256 tokenId) public virtual nonReentrant {
		//solhint-disable-next-line max-line-length
		require(nftContractAddress._isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
		uint256 count = 1;
		minterAddress[msg.sender]._mintQtyByAddress.sub(count, "Insufficient Allowance");

		_burnedSupply += count;
		nftContractAddress._burn(tokenId);
    	}
    
	// ======================================================== Overrides

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    	function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual override {
		require(nftContractAddress._exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
		string memory packJson = _tokenURI.toString()+".json";
		_tokenURIs[tokenId] = packJson;
		nftContractAddress._setTokenURI(tokenId, packJson);
   	}

    /**
    * @dev Returns the base URI set via {_setBaseURI}. This will be
    * automatically added as a prefix in {tokenURI} to each token's URI, or
    * to the token ID if no specific URI is set for that token ID.
    */
    function _baseURI() public view virtual override(HealAngels) returns (string memory) {
        return baseURI;
    }
	
    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override(HealAngels) returns (string memory) {
        require(nftContractAddress._exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI.toString()));
        }

        return super.tokenURI(tokenId);
    }


	/// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual override onlyOwner {
        emit OwnershipTransferred(_owner, payable(0));
        _owner = payable(0);
        owner = _owner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address payable newOwner) public virtual override onlyOwner {
        if(newOwner == payable(0)){
            return renounceOwnership();
        }
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
        owner = _owner;
    }
}
