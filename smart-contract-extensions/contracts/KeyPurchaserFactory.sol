pragma solidity 0.5.16;

import './KeyPurchaser.sol';
import 'hardlydifficult-ethereum-contracts/contracts/proxies/CloneFactory.sol';

/**
 * @notice A factory for creating keyPurchasers.
 * This contract acts as a registry to discover purchasers for a lock
 * and by creating each purchaser itself, garantees a consistent implementation.
 */
contract KeyPurchaserFactory
{
  using CloneFactory for address;

  KeyPurchaser public keyPurchaserTemplate;
  mapping(address => address[]) internal lockToKeyPurchasers;

  constructor() public
  {
    keyPurchaserTemplate = new KeyPurchaser();
  }

  function deployKeyPurchaser(
    address _lock,
    uint _maxKeyPrice,
    uint _renewWindow,
    uint _renewMinFrequency
  ) public
  {
    KeyPurchaser purchaser = KeyPurchaser(keyPurchaserTemplate._createClone());
    purchaser.initialize(_lock, _maxKeyPrice, _renewWindow, _renewMinFrequency);
    lockToKeyPurchasers[_lock] = purchaser;
  }

  function getKeyPurchasers(
    address _lock
  ) public
    returns (address[] memory)
  {
    return lockToKeyPurchasers[_lock];
  }
}