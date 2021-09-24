// @dev - Solidity Task: Build a vanity name registering system resistant against frontrunning

pragma solidity ^0.8.7;

/** DEPENDENCIES */
import "Ownable.sol";
contract NameRegistrationSystem is Ownable{

    /** @dev - FRONT-RUNNING SECURITY */
    uint256 txCounter;
    /** @dev - CONSTANTS */
    uint8 constant public NAME_MIN_LENGTH = 1;
    bytes1 constant public BYTES_DEFAULT_VALUE = bytes1(0x00);

    /** @dev - MAPPINGS */
    // @dev - stores nameHash (bytes32)
    mapping (bytes32 => UserProperties) public UserList;

    /** @dev - STRUCTS */
    // @dev - name structure
    struct UserProperties {
        bytes name;
        address userAddress;
        string nationality;
    }
    /** @dev - EVENTS */
    // @dev - Logs the name registrations
    event LogNameRegistration(
        uint indexed timestamp,
        bytes name
    );

    // @dev - Logs name renewals
    event LogNameRenew(
        uint indexed timestamp, 
        bytes name, 
        address indexed owner
    ); 

    // @dev - Logs name transfers
    event LogNameTransfer(
        uint indexed timestamp, 
        bytes name, 
        address indexed owner, 
        address newOwner
    );
    /** @dev - MODIFIERS */
    // @dev - Secure way to ensure the length of the name being purchased is
    // within the allowed parameters (NAME_MIN_LENGTH)
    modifier nameLengthCheck(bytes memory name) {
  
        // @dev - CHECK if the length of the name provided is allowed
        require(
            name.length >= NAME_MIN_LENGTH,
            "Name is too short"
        );

    _;
    }

    // @dev - Secure way to check if the address sending the transaction 
    // (msg.sender) owns the name
    modifier isNameOwner(bytes memory name) {

        // @dev - GET a hash of the name
        bytes32 nameHash = getNameHash(name);
        
        // @dev - CHECK if the msg.sender owns the name
        require(
            UserList[nameHash].userAddress == msg.sender,
            "You do not own this name"
        );
        
    _;
    }

    // @dev - Secure way to implement the requirement of the transaction counter
    modifier transactionCounter(uint256 _txCounter) {
        // @dev - REQUIRE _txCounter to be equal to the current global txCounter
        _txCounter = getTxCounter();
        require(
            _txCounter == txCounter,
            "Error, possible transaction order issue"
        );

    _;
    }

    // @dev - Contract constructor
    constructor() {
        txCounter = 0;
    }

    /*
     * @dev - GET name hash to be used as a unique identifier
     * @param name
     * @return nameHash
    */
    function getNameHash(bytes memory name) public pure returns(bytes32) {
        // @dev - RETURN keccak256 hash for name
        return keccak256(name);
    } 
    /*
     * @dev - FUNCTION to return transaction counter
    */
    function getTxCounter() public view returns (uint256) {
        return txCounter;
    }

    /*
     * @dev - FUNCTION to register name
     * @param name - name being registered
    */
    function register(bytes memory name, uint256 _txCounter, string memory nationality) public 
        nameLengthCheck(name) 
        transactionCounter(_txCounter) 
    {
        txCounter += 1;
        // @dev - CALCULATE name hash
        bytes32 nameHash = getNameHash(name);
        // @dev - RECORD name to storage
        UserList[nameHash] = UserProperties(name, msg.sender, nationality);
        // @dev - LogNameRegistration event
        emit LogNameRegistration(
            block.timestamp, 
            name
        );
    }

    /*
     * @dev - FUNCTION to renew registration on name
     * @param name - name being renewed
    */
    function renewName(bytes memory name) public 
        isNameOwner(name)
    {             
        // LogNameRenew event
        emit LogNameRenew(
            block.timestamp,
            name,
            msg.sender
        );
    }

    /*
     * @dev - Transfers name ownership
     * @param name - name being transferred
     * @param newOwner - address of the new owner
    */
    function transferName(bytes memory name, address newOwner) public 
        isNameOwner(name)
    {
        // @dev - Standard guard to prevent ownership being transferred to the 0x0 address
        require(newOwner != address(0));
        
        // @dev - CALCULATE the hash of the current name
        bytes32 nameHash = getNameHash(name);
        
        // @dev - ASSIGN the names new owner
        UserList[nameHash].userAddress = newOwner;
    
        // @dev - LogNameTransfer event
        emit LogNameTransfer(
            block.timestamp,
            name,
            msg.sender,
            newOwner
        );
    }
}