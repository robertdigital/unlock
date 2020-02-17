pragma solidity 0.5.16;

import './KeyPurchaser.sol';
import 'hardlydifficult-ethereum-contracts/contracts/proxies/CloneFactory.sol';

/**
 * @notice A factory for creating keyPurchasers.
 * This contract acts as a registry to discover purchasers for a lock
 * and by creating each purchaser itself, it's a single tx and this garantees
 * a consistent implementation and that it was created by the lock owner.
 */
contract KeyPurchaserFactory
{
  using CloneFactory for address;

  address public keyPurchaserTemplate;
  mapping(address => address[]) internal lockToKeyPurchasers;

  constructor() public
  {
    keyPurchaserTemplate = address(new KeyPurchaser());
  }

  /**
   * @notice Deploys a new KeyPurchaser for a lock and stores the address for reference.
   */
  function deployKeyPurchaser(
    address _lock,
    uint _maxKeyPrice,
    uint _renewWindow,
    uint _renewMinFrequency,
    bool _isSubscription
  ) public
  {
    require(_lock.owner() == msg.sender, 'ONLY_OWNER');
    address purchaser = keyPurchaserTemplate._createClone();
    KeyPurchaser(purchaser).initialize(IPublicLock(_lock), _maxKeyPrice, _renewWindow, _renewMinFrequency, _isSubscription);
    lockToKeyPurchasers[_lock].push(purchaser);
  }

  /**
   * @notice Returns all the KeyPurchasers for a given lock.
   * @dev Some KeyPurchasers in this list may have been disabled or stopped.
   */
  function getKeyPurchasers(
    address _lock
  ) public view
    returns (address[] memory)
  {
    return lockToKeyPurchasers[_lock];
  }
}