pragma solidity 0.5.16;

import 'hardlydifficult-ethereum-contracts/contracts/lifecycle/Stoppable.sol';
import '@openzeppelin/upgrades/contracts/Initializable.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import 'unlock-abi-1-3/IPublicLockV6.sol';

// the user can remove approval to cancel anytime. We could also add a cancel feature but that would be redundant with token allowance.
  // risk: if the user transfers or cancels themselves, they would naturally expect that also cancels the subscription but it does not.
  // not sure we have a way to deal with this other than in the front-end, unless we change the lock to support this
contract KeyPurchaser is Initializable, Stoppable
{
  using Address for address;

  // set on initialize and cannot change
  IPublicLock public lock;
  uint public maxKeyPrice;
  uint public maxPurchaseCount;
  uint public renewWindow;
  uint public renewMinFrequency;

  // admin can change these anytime
  string public name;
  bool internal disabled;

  // store minimal history
  mapping(address => uint) timeOfLastPurchase;

  function initialize(
    IPublicLock _lock,
    uint _maxKeyPrice,
    uint _renewWindow,
    uint _renewMinFrequency
  ) public initializer()
  {
    require(_lock.owner() == msg.sender, 'ONLY_OWNER');
    require(_maxKeyPrice > 0, 'INVALID_MAX_KEYPRICE');
    require(_renewWindow > 0, 'INVALID_RENEW_WINDOW');
    require(_renewMinFrequency > 0, 'INVALID_RENEW_MINFREQUENCY');

    _initializeAdminRole();
    lock = _lock;
    maxKeyPrice = _maxKeyPrice;
    renewWindow = _renewWindow;
    renewMinFrequency = _renewMinFrequency;
  }

  function config(
    string memory _name,
    bool _disabled
  ) public onlyAdmin()
  {
    name = _name;
    disabled = _disabled;
  }

  /**
   * @notice Indicates if this purchaser should be exposed as an option to users.
   */
  function isActive() public returns(bool)
  {
    return !stopped() && !disabled;
  }

  // anyone can call this
  // optimistic unlock could monitor this call
  function purchaseFor(
    address _user,
    address _referrer,
    bytes memory _data
  ) public
  {
    uint keyPrice = lock.keyPrice();
    require(keyPrice <= maxKeyPrice, 'PRICE_TOO_HIGH');
    uint time = lock.keyExpirationTimestampFor(_user);
    require(time <= now || time - now <= renewWindow, 'OUTSIDE_RENEW_WINDOW');
    time = timeOfLastPurchase[_user];
    require(time < now && now - time >= renewMinFrequency, 'BEFORE_MIN_FREQUENCY');

    IERC20 token = IERC20(lock.tokenAddress());
    token.transferFrom(_user, address(this), keyPrice);
    token.approve(address(lock), keyPrice);
    lock.purchase(keyPrice, _user, _referrer, _data);
    timeOfLastPurchase[_user] = now;
  }
}
