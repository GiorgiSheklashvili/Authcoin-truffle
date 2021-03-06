
// File: installed_contracts\zeppelin\contracts\ownership\Ownable.sol

pragma solidity ^0.4.11;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

// File: contracts\Identifiable.sol

/**
 * @title Identifiable
 * @dev The Identifiable contract has an owner and creator address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Identifiable {

    address private creator;

    address public owner;

    /**
   * @dev The Identifiable constructor sets the original `creator` of the contract to the sender
   * account.
   */
    function Identifiable() {
        creator = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyCreator() {
        require(msg.sender == creator);
        _;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function getCreator() public view returns (address) {
        return creator;
    }
}

// File: contracts\signatures\SignatureVerifier.sol

pragma solidity ^0.4.17;


contract SignatureVerifier {

    /**
    * @dev Verifies signature.
    *
    * @param messageHash message hash to verify against signature
    * @param signature signature of a message
    * @param signer signer of signature
    * @return true if message hash is contained in signature.
    */
    function verify(bytes32 messageHash, bytes signature, bytes signer) public view returns (bool);

    /**
    * @dev Verifies signature.
    *
    * @param message message to verify against signature
    * @param signature signature of a message
    * @param signer signer of signature
    * @return true if message hash is contained in signature.
    */
    function verify(bytes message, bytes signature, bytes signer) public view returns (bool);

    /**
    * @dev Verifies signature.
    *
    * @param message message to verify against signature
    * @param signature signature of a message
    * @param signer signer of signature
    * @return true if message hash is contained in signature.
    */
    function verify(string message, bytes signature, bytes signer) public view returns (bool);

    /**
    * @dev Verifies signature.
    *
    * @param signature signature of a message
    * @param signer signer of signature
    * @return true if hash of signer is contained in signature.
    */
    function verifyDirectKeySignature(bytes signature, bytes signer) public view returns (bool);

}

// File: contracts\utils\BytesUtils.sol

pragma solidity ^0.4.17;

library BytesUtils {

    /**
     * @dev Copies bytes from source to destination.
     *
     * Not safe to use if `src` and `dest` overlap.
     *
     * @param src The source slice.
     * @param srcoffset Offset into the source slice.
     * @param dst The destination bytes.
     * @param dstoffset Offset into the destination slice.
     * @param len Number of bytes to copy.
     */
    function memcopy(bytes src, uint srcoffset, bytes dst, uint dstoffset, uint len) pure internal {
        assembly {
            src := add(src, add(32, srcoffset))
            dst := add(dst, add(32, dstoffset))

            // copy 32 bytes at once
            for
            {}
            iszero(lt(len, 32))
            {
            dst := add(dst, 32)
            src := add(src, 32)
            len := sub(len, 32)
            }
            { mstore(dst, mload(src)) }

                // copy the remainder (0 < len < 32)
            let mask := sub(exp(256, sub(32, len)), 1)
            let srcpart := and(mload(src), not(mask))
            let dstpart := and(mload(dst), mask)
            mstore(dst, or(srcpart, dstpart))
        }
    }

    function copyToBytes32(bytes src, uint offset) pure internal returns (bytes32) {
        bytes32 out;
        for (uint i = 0; i < 32; i++) {
            out |= bytes32(src[offset + i] & 0xFF) >> (i * 8);
        }
        return out;
    }

	function char(byte b) pure internal returns (byte c) {
        if (b < 10) return byte(uint8(b) + 0x30);
        else return byte(uint8(b) + 0x57);
    }

    function bytesToString(bytes src) pure internal returns (string) {
        uint l = src.length;
        bytes memory s = new bytes(l*2);

        for (uint i = 0; i < l; i++) {
            byte b = byte(src[i]);
            byte hi = byte(uint8(b) / 16);
            byte lo = byte(uint8(b) - 16 * uint8(hi));
            s[i*2] = char(hi);
            s[i*2+1] = char(lo);
        }

        return string(s);
    }

    function bytes32ToString(bytes32 b32) pure internal returns (string) {
        bytes memory s = new bytes(64);

        for (uint8 i = 0; i < 32; i++) {
            byte b = byte(b32[i]);
            byte hi = byte(uint8(b) / 16);
            byte lo = byte(uint8(b) - 16 * uint8(hi));
            s[i*2] = char(hi);
            s[i*2+1] = char(lo);
        }

        return string(s);
    }

	function bytesToAddress(bytes _address) pure internal returns (address) {
		uint160 m = 0;
		uint160 b = 0;

		for (uint8 i = 0; i < 20; i++) {
		  m *= 256;
		  b = uint160(_address[i]);
		  m += (b);
		}

		return address(m);
	}

	function addressToBytes(address a) pure internal returns (bytes b){
	   assembly {
			let m := mload(0x40)
			mstore(add(m, 20), xor(0x140000000000000000000000000000000000000000, a))
			mstore(0x40, add(m, 52))
			b := m
	   }
	}
}

// File: contracts\EntityIdentityRecord.sol

pragma solidity ^0.4.17;





/**
* @dev Entity Identity Record (EIR) contains information that links an entity to a certain
* identity and the corresponding public key or certificate. EIR is created during the key
* generation process and posted to the blockchain. 'content' field is used to store public
* key or certificate and it must be unique.
*/
contract EntityIdentityRecord is Identifiable {

    bytes32 private id;

    bytes32 private contentType;

    bytes private content;

    bytes32[] private identifiers;

    bool private revoked;

    uint private blockNumber;

    bytes32 private hash;

    bytes private signature;

    SignatureVerifier private signatureVerifier;

    event LogRevokedEir(bytes32 indexed id);

    function EntityIdentityRecord(
        bytes32[] _identifiers,
        bytes _content,
        bytes32 _contentType,
        bytes32 _hash,
        bytes _signature,
        SignatureVerifier _signatureVerifier,
        address _owner) {
        id = keccak256(_content);
        blockNumber = block.number;
        content = _content;
        contentType = _contentType;
        revoked = false;
        identifiers = _identifiers;
        hash = _hash;
        signature = _signature;
        signatureVerifier = _signatureVerifier;
        owner = _owner;
    }

    function getId() public view returns (bytes32) {
        return id;
    }

    function getBlockNumber() public view returns (uint) {
        return blockNumber;
    }

    function getContent() public view returns (bytes) {
        return content;
    }

    function getContentType() public view returns (bytes32) {
        return contentType;
    }

    function isRevoked() public view returns (bool) {
        return revoked;
    }

    function getIdentifiersCount() public view returns (uint) {
        return identifiers.length;
    }

    function getIdentifier(uint index) public view returns (bytes32) {
        return identifiers[index];
    }

    function getIdentifiers() public view returns (bytes32[]) {
        return identifiers;
    }

    function getHash() public view returns (bytes32) {
        return hash;
    }

    function getSignature() public view returns (bytes) {
        return signature;
    }

    function getData() public view returns(
        bytes32,
        uint,
        bytes,
        bytes32,
        bool,
        bytes32[],
        bytes32,
        bytes) 
        {
        return (
            id,
            blockNumber,
            content,
            contentType,
            revoked,
            identifiers,
            hash,
            signature
        );
    }

    function revoke(bytes revokingSignature) onlyCreator public returns(bool) {
        if(signatureVerifier.verify(BytesUtils.bytes32ToString(keccak256(id, contentType, content, identifiers, true)), revokingSignature, content)) {
            revoked = true;
            LogRevokedEir(id);
            return true;
        } else {
            return false;
        }
    }

    function verifySignature(string message, bytes signature) public returns(bool) {
        return signatureVerifier.verify(message, signature, content);
    }

}

// File: contracts\ValidationAuthenticationEntry.sol

pragma solidity ^0.4.17;




/*
* @dev Tracks and stores the information produced by single validation & authentication process. During the V&A process,
* the verifier and target:
*   1. exchange challenges (CR - ChallengeRecord) with each other and
*   2. create the corresponding responses (RR - ResponseRecord) and
*   3. both entities evaluate the received responses and create corresponding signatures (SR - SignatureRecord)
*      depending on whether they are satisfied with the received response or not.
*/
contract ValidationAuthenticationEntry is Identifiable {

    struct ChallengeRecord {
        bytes32 id;
        uint blockNumber;
        bytes32 challengeType;
        bytes challenge;
        address verifierEir;
        address targetEir;
        bytes32 hash;
        bytes signature;
        address creator;
    }

    struct ChallengeResponseRecord {
        bytes32 vaeId;
        bytes32 challengeRecordId;
        uint blockNumber;
        bytes response;
        bytes32 hash;
        bytes signature;
        address creator;
    }

    struct ChallengeSignatureRecord {
        bytes32 vaeId;
        bytes32 challengeRecordId;
        uint blockNumber;
        uint expirationBlock;
        bool revoked;
        bool successful;
        bytes32 hash;
        bytes signature;
        address creator;
    }

    // Identifier used to track the VAE throughout the hole V&A process.
    bytes32 private vaeId;

    // Block number when the VAE was created and the first CR was attached to the VAE by verifier. If 'target'
    // does not create a corresponding challenge for the verifier within 24h, we assume the V&A procedure to
    // be failed.
    uint private blockNumber;

    // cr_id = >CR
    mapping(bytes32 => ChallengeRecord) private challenges;
    // cr_id array
    bytes32[] private challengeIdArray;

    // cr_id => ChallengeResponseRecord
    mapping(bytes32 => ChallengeResponseRecord) private responses;

    // cr_id array
    bytes32[] private responseIdArray;

    // cr_id => ChallengeSignatureRecord
    mapping(bytes32 => ChallengeSignatureRecord) private signatures;

    // cr_id array
    bytes32[] private signatureIdArray;

    event LogNewChallengeRecord(ChallengeRecord cr, bytes32 challengeType, bytes32 id, bytes32 vaeId);

    event LogNewChallengeResponseRecord(ChallengeResponseRecord responseAddress, bytes32 challengeId);

    event LogNewChallengeSignatureRecord(ChallengeSignatureRecord sr, bytes32 challengeId, bytes32 vaeId);

    // Constructor to create a new V&A entry.
    function ValidationAuthenticationEntry(
        bytes32 _vaeId,
        address _owner) {
        vaeId = _vaeId;
        blockNumber = block.number;
        owner = _owner;
    }

    function getVaeId() public view returns(bytes32) {
        return vaeId;
    }

    function getBlockNumber() public view returns(uint) {
        return blockNumber;
    }

    function addChallengeRecord(
        bytes32 _crId,
        bytes32 _vaeId,
        bytes32 _challengeType,
        bytes _challenge,
        address _verifierEir,
        address _targetEir,
        bytes32 _hash,
        bytes _signature,
        address _creator
    ) onlyCreator public returns (bool) 
    {
        require(vaeId == _vaeId);
        // 0 or 1 challenges
        require(challengeIdArray.length < 2); // test ok

        ChallengeRecord memory cr = ChallengeRecord(
            _crId,
            block.number,
            _challengeType,
            _challenge,
            _verifierEir,
            _targetEir,
            _hash,
            _signature,
            _creator
        );
        // TODO CR is signed by correct EIR

        if (challengeIdArray.length == 1) {
            require(challenges[_crId].creator == address(0)); // test ok
            ChallengeRecord previous = challenges[challengeIdArray[0]];
            require(previous.verifierEir == _targetEir); // test ok
            require(_verifierEir == previous.targetEir); // test ok
        }

        challenges[_crId] = cr;
        challengeIdArray.push(_crId);
        LogNewChallengeRecord(
             cr,
             _challengeType,
             _crId,
             _vaeId
         );
        return true;
    }

    function addChallengeResponseRecord(
        bytes32 _vaeId,
        bytes32 _challengeRecordId,
        bytes _response,
        bytes32 _hash,
        bytes _signature,
        address _creator
    ) onlyCreator public returns (bool) 
    {
        require(challengeIdArray.length == 2);
        require(responseIdArray.length < 2);

        require(vaeId == _vaeId);
        // challenge exists
        require(challenges[_challengeRecordId].creator != address(0));
        // challenge response doesn't exist
        require(responses[_challengeRecordId].creator == address(0));

        // ensure CRR hash is correct
        require(keccak256(_vaeId, _challengeRecordId, _response) == _hash);

        // ensure CRR signature is correct
        ChallengeRecord cr = challenges[_challengeRecordId];
        require(EntityIdentityRecord(cr.targetEir).verifySignature(BytesUtils.bytes32ToString(_hash), _signature));

        ChallengeResponseRecord memory rr = ChallengeResponseRecord(
            _vaeId,
            _challengeRecordId,
            block.number,
            _response,
            _hash,
            _signature,
            _creator
        );

        responses[_challengeRecordId] = rr;
        responseIdArray.push(_challengeRecordId);

        LogNewChallengeResponseRecord(rr, _challengeRecordId);
        return true;
    }

    function addChallengeSignatureRecord(
        bytes32 _vaeId,
        bytes32 _challengeRecordId,
        uint _expirationBlock,
        bool _successful,
        bytes32 _hash,
        bytes _signature,
        address _creator
    ) onlyCreator public returns (bool) 
    {
        require(challengeIdArray.length == 2); // ok
        require(responseIdArray.length == 2); // ok
        require(signatureIdArray.length < 2);

        // challenge exists
        ChallengeRecord cr = challenges[_challengeRecordId];
        require(cr.creator != address(0));
        // challenge response exist
        require(responses[_challengeRecordId].creator != address(0));
        // challenge response doesn't exist
        require(signatures[_challengeRecordId].creator == address(0));
        // ensure SR hash is correct
        require(keccak256(_vaeId, _challengeRecordId, _expirationBlock, _successful) == _hash);
        // ensure SR signature is correct

        require(EntityIdentityRecord(cr.verifierEir).verifySignature(BytesUtils.bytes32ToString(_hash), _signature));

        ChallengeSignatureRecord memory sr = ChallengeSignatureRecord(
            _vaeId,
            _challengeRecordId,
            block.number,
            _expirationBlock,
            false,
            _successful,
            _hash,
            _signature,
            _creator
        );

        signatures[_challengeRecordId] = sr;
        signatureIdArray.push(_challengeRecordId);
        LogNewChallengeSignatureRecord(sr, _challengeRecordId, _vaeId);
        return true;
    }

    function getChallengeCount() public view returns(uint) {
        return challengeIdArray.length;
    }

    function getChallengeIds() public view returns(bytes32[]) {
        return challengeIdArray;
    }

    function getChallenge(bytes32 challengeId) public view returns(ChallengeRecord) {
        return challenges[challengeId];
    }

    function isParticipant(bytes32 eirId) public view returns(bool) {
        for (uint i = 0; i < challengeIdArray.length; i++) {
            ChallengeRecord cr = challenges[challengeIdArray[i]];
            if (EntityIdentityRecord(cr.verifierEir).getId() == eirId || EntityIdentityRecord(cr.targetEir).getId() == eirId) {
                return true;
            }
        }
        return false;
    }

    function getChallengeResponseCount() public view returns(uint) {
        return responseIdArray.length;
    }

    function getChallengeResponseIds() public view returns(bytes32[]) {
        return responseIdArray;
    }

    function getChallengeResponse(bytes32 challengeId) public view returns(ChallengeResponseRecord) {
        return responses[challengeId];
    }

    function getChallengeSignatureCount() public view returns(uint) {
        return signatureIdArray.length;
    }

    function getChallengeSignatureIds() public view returns(bytes32[]) {
        return signatureIdArray;
    }

    function getChallengeSignature(bytes32 challengeId) public view returns(ChallengeSignatureRecord) {
        return signatures[challengeId];
    }

    function getChallengeRecordData(bytes32 challengeId) public view returns(
        bytes32,
        uint,
        bytes32,
        bytes,
        address,
        address,
        bytes32,
        bytes) 
        {
        ChallengeRecord storage cr = challenges[challengeId];
        bytes memory challenge = copyArray(cr.challenge);
        bytes memory signature = copyArray(cr.signature);
        return (
        cr.id,
        cr.blockNumber,
        cr.challengeType,
        challenge,
        cr.verifierEir,
        cr.targetEir,
        cr.hash,
        signature);
    }

    function getChallengeResponseRecordData(bytes32 challengeId) public view returns(
        bytes32, // vaeId
        bytes32, // challengeRecordId
        uint, // blockNumber
        bytes, // response
        bytes32, // hash
        bytes) 
        {
        ChallengeResponseRecord storage rr = responses[challengeId];
        bytes memory response = copyArray(rr.response);
        bytes memory signature = copyArray(rr.signature);
        return (
            rr.vaeId,
            rr.challengeRecordId,
            rr.blockNumber,
            response,
            rr.hash,
            signature
        );
    }

    function getChallengeSignatureRecordData(bytes32 challengeId) public view returns(
        bytes32, // vaeId;
        bytes32, // challengeRecordId;
        uint, // blockNumber;
        uint, // expirationBlock;
        bool, // revoked;
        bool, // successful;
        bytes32, // hash;
        bytes// signature
    ) 
    {
        ChallengeSignatureRecord storage sr = signatures[challengeId];
        return (
            sr.vaeId,
            sr.challengeRecordId,
            sr.blockNumber,
            sr.expirationBlock,
            sr.revoked,
            sr.successful,
            sr.hash,
            copyArray(sr.signature)
        );
    }

    function copyArray(bytes a) private pure returns(bytes) {
        bytes memory second = new bytes(a.length);

        for (uint i = 0; i < a.length; i++) {
            second[i] = a[i];
        }
        return second;
    }

}

// File: contracts\signatures\DummyVerifier.sol

pragma solidity ^0.4.17;



contract DummyVerifier is SignatureVerifier {

    function verify(bytes32 message, bytes signature, bytes signer) public view returns (bool) {
        return true;
    }

    function verify(bytes message, bytes signature, bytes signer) public view returns (bool) {
        return true;
    }

    function verify(string message, bytes signature, bytes signer) public view returns (bool) {
        return true;
    }

    function verifyDirectKeySignature(bytes signature, bytes signer) public view returns (bool) {
        return true;
    }

}

// File: contracts\AuthCoin.sol

pragma solidity ^0.4.17;







/**
* @title AuthCoin
* @dev Main entry point for Authcoin protocol. Authcoin is an alternative approach to the commonly used public key infrastructures
* such as central authorities and the PGP web of trust. It combines a challenge response-based validation and authentication process
* for domains, certificates, email accounts and public keys with the advantages of a block chain-based storage system. Due to its
* transparent nature and public availability, it is possible to track the whole validation and authentication process history of each
* entity in the Authcoin system which makes it much more difficult to introduce sybil nodes and prevent such nodes from getting
* detected by genuine users.
*
* This contract can be used to register new entity identity records, create challenges and challenge responses and add challenge
* signature records. Also it supports revocation of entity identity and signature records.
*/
contract AuthCoin is Ownable {

    // stores EIR values (eir_id => EntityIdentityRecord)
    mapping (bytes32 => EntityIdentityRecord) private eirIdToEir;

    // stores the id's of Entity Identity Records
    bytes32[] private eirIdList;

    // stores the values of ValidationAuthenticationEntry (vae_id => ValidationAuthenticationEntry)
    mapping (bytes32 => ValidationAuthenticationEntry) private vaeIdToVae;

    // stores the id's of ValidationAuthenticationEntry
    bytes32[] private vaeIdList;

    // stores known signature verifier contracts (eir type =>  SignatureVerifier)
    mapping (bytes32 => SignatureVerifier) private signatureVerifiers;

    // stores known signature verifier id's
    bytes32[] private verifierIdList;

    event LogNewEir(bytes32 id, EntityIdentityRecord eir, bytes32 contentType);

    event LogNewVae(address vaeAddress, bytes32 id);

    event LogNewSignatureVerifier(SignatureVerifier a, bytes32 eirType);

    function AuthCoin() {
        registerSignatureVerifier(new DummyVerifier(), bytes32("test"));
    }

    /**
    * @dev Adds new EIR to the blockchain.
    */
    function registerEir(
        bytes _content,
        bytes32 _contentType,
        bytes32[] _identifiers, // e-mail address, username, age, etc
        bytes32 _hash,
        bytes _signature) public returns (bool)
    {

        // ensure content type exists
        SignatureVerifier signatureVerifier = signatureVerifiers[_contentType];
        require(signatureVerifier != address(0));

        // ensure EIR hash is correct
        require(keccak256(keccak256(_content), _contentType, _content, _identifiers, false) == _hash);

        // ensure signature is correct
        require(signatureVerifier.verify(BytesUtils.bytes32ToString(_hash), _signature, _content));

        // create new contract and store it
        EntityIdentityRecord eir = new EntityIdentityRecord(
            _identifiers,
            _content,
            _contentType,
            _hash,
            _signature,
            signatureVerifier,
            msg.sender
        );

        // ensure it doesn't exist
        bytes32 id = eir.getId();
        require(eirIdToEir[id] == address(0));

        eirIdToEir[id] = eir;
        eirIdList.push(id);

        LogNewEir(id, eir, _contentType);
        return true;
    }

    function revokeEir(bytes32 eirId, bytes revokingSignature) public {
        EntityIdentityRecord eir = eirIdToEir[eirId];
        require(address(eir) != address(0));
        eir.revoke(revokingSignature);
    }

    /**
    * @dev Adds a new challenge record to the blockchain.
    */
    function registerChallengeRecord(
        bytes32 _id,
        bytes32 _vaeId,
        bytes32 _challengeType,
        bytes _challenge,
        bytes32 _verifierEir,
        bytes32 _targetEir,
        bytes32 _hash,
        bytes _signature) public returns (bool)
    {

        // verifier exists
        EntityIdentityRecord verifier = getEir(_verifierEir);
        require(address(verifier) != address(0));
        require(verifier.isRevoked() == false);
        require(this == verifier.getCreator());

        // target exists
        EntityIdentityRecord target = getEir(_targetEir);
        require(address(target) != address(0));
        require(target.isRevoked() == false);
        require(this == target.getCreator());

        // ensure CR hash is correct
        require(keccak256(_id, _vaeId, _challengeType, _challenge, _verifierEir, _targetEir) == _hash);

        // ensure CR signature is correct
        require(verifier.verifySignature(BytesUtils.bytes32ToString(_hash), _signature));

        //TODO check if EIR is revoked or not.

        // check VAE
        ValidationAuthenticationEntry vae = vaeIdToVae[_vaeId];
        bool isInitialized = (address(vae)!=address(0));

        if (!isInitialized) {
            vae = new ValidationAuthenticationEntry(_vaeId, msg.sender);
            vaeIdToVae[_vaeId] = vae;
            vaeIdList.push(_vaeId);
            LogNewVae(vae, _vaeId);
        } else {
            require(this == vae.getCreator());
        }

        vae.addChallengeRecord(_id,
            _vaeId,
            _challengeType,
            _challenge,
            verifier,
            target,
            _hash,
            _signature,
            msg.sender
        );

        return true;
    }

    /**
    * @dev Registers a challenge response record.
    */
    function registerChallengeResponse(
        bytes32 _vaeId,
        bytes32 _challengeId,
        bytes _response,
        bytes32 _hash,
        bytes _signature) public returns (bool)
    {
        ValidationAuthenticationEntry vae = vaeIdToVae[_vaeId];
        require(address(vae) != address(0));
        require(this == vae.getCreator());

        require(vae.addChallengeResponseRecord(
            _vaeId,
            _challengeId,
            _response,
            _hash,
            _signature,
            msg.sender
        ));

        return true;
    }

    /**
    * @dev Registers a challenge response signature record.
    */
    function registerChallengeSignature(
        bytes32 _vaeId,
        bytes32 _challengeId,
        uint _expirationBlock,
        bool _successful,
        bytes32 _hash,
        bytes _signature) public returns (bool)
    {
        // check vae id. vae must exist and should be in correct status.
        ValidationAuthenticationEntry vae = vaeIdToVae[_vaeId];
        require(address(vae) != address(0));
        // TODO: check correct status

        require(vae.addChallengeSignatureRecord(
            _vaeId,
            _challengeId,
            _expirationBlock,
            _successful,
            _hash,
            _signature,
            msg.sender
        ));

        return true;
    }

    /**
    * @dev Registers signature verifier for some type of EIR. Registering EIR requires corresponding signature
    * verifier. If signature verifier is present then it will be overridden. Only the owner of the AuthCoin
    * contract can add new signature verifiers.
    *
    * @param signatureVerifier signature verifier address
    * @param eirType EIR type the signature verifier is implemented
    * @return true if signature verifier registration is successful.
    */
    function registerSignatureVerifier(SignatureVerifier signatureVerifier, bytes32 eirType) onlyOwner public returns (bool) {
        if (address(signatureVerifiers[eirType]) == address(0)) {
            verifierIdList.push(eirType);
        }
        signatureVerifiers[eirType] = signatureVerifier;
        LogNewSignatureVerifier(signatureVerifier, eirType);
        return true;
    }

    /**
    * @dev Returns registered signature verifier address. If eir type is unknown then zero address will be returned.
    */
    function getSignatureVerifier(bytes32 eirType) public view returns (SignatureVerifier) {
        return signatureVerifiers[eirType];
    }

    /**
    * @dev Returns an array of registered signature verifier types.
    */
    function getSignatureVerifierTypes() public view returns (bytes32[]) {
        return verifierIdList;
    }

    /**
    * @dev Returns the address of the EIR given id. This address can be used to access the actual EIR. Zero address will be
    * returned if EIR id is unknown.
    */
    function getEir(bytes32 eirId) public view returns (EntityIdentityRecord) {
        return eirIdToEir[eirId];
    }

    /**
    * @dev Returns the validation and authentication entry for given VAE id. Zero address will be returned if VAE id is unknown.
    */
    function getVae(bytes32 vaeId) public view returns (ValidationAuthenticationEntry) {
        return vaeIdToVae[vaeId];
    }

    /**
    * @dev Returns the count of registered entity identity records
    */
    function getEirCount() public view returns (uint) {
        return eirIdList.length;
    }

    /**
    * @dev Returns the count of registered validation and authentication entries.
    */
    function getVaeCount() public view returns (uint) {
        return vaeIdList.length;
    }

    /**
    * @dev Returns the validation and authentication entry array where EIR id is a participant (verifier or target).
    */
    function getVaeArrayByEirId(bytes32 eirId) public view returns (ValidationAuthenticationEntry[]) {
        // solidity doesn't have dynamic arrays
        ValidationAuthenticationEntry[] memory eieVaeArray = new ValidationAuthenticationEntry[](vaeIdList.length);
        uint j = 0;
        for (uint i = 0; i < vaeIdList.length; i++) {
            ValidationAuthenticationEntry vae = vaeIdToVae[vaeIdList[i]];
            if (vae.isParticipant(eirId)) {
                eieVaeArray[j] = vae;
                j = j+1;
            }
        }
        if (j == vaeIdList.length) {
            return eieVaeArray;
        }
        // copy only known values
        ValidationAuthenticationEntry[] memory eieVaeArray2 = new ValidationAuthenticationEntry[](j);
        for (uint i2 = 0; i2 < j; i2++) {
            eieVaeArray2[i2] = eieVaeArray[i2];
        }
        return eieVaeArray2;
    }

}
