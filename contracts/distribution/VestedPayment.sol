pragma solidity ^0.4.18;

import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import "../token/LifToken.sol";

/**
   @title Vested Payment Schedule for LifToken

   An ownable vesting schedule for the LifToken, the tokens can only be
   claimed by the owner. The contract has a start timestamp, a duration
   of each period in seconds (it can be days, months, years), a total
   amount of periods and a cliff. The available amount of tokens will
   be calculated based on the balance of LifTokens of the contract at
   that time.
 */

contract VestedPayment is Ownable {
  using SafeMath for uint256;

  // When the vested schedule starts
  uint256 public startTimestamp;

  // How many seconds each period will last
  uint256 public secondsPerPeriod;

  // How many periods will have in total
  uint256 public totalPeriods;

  // The amount of tokens to be vested in total
  uint256 public tokens;

  // How many tokens were claimed
  uint256 public claimed;

  // The token contract
  LifToken public token;

  // Duration (in periods) of the initial cliff in the vesting schedule
  uint256 public cliffDuration;

  /**
     @dev Constructor.

     @param _startTimestamp see `startTimestamp`
     @param _secondsPerPeriod see `secondsPerPeriod`
     @param _totalPeriods see `totalPeriods
     @param _cliffDuration see `cliffDuration`
     @param _tokens see `tokens`
     @param tokenAddress the address of the token contract
   */
  function VestedPayment(
    uint256 _startTimestamp, uint256 _secondsPerPeriod,
    uint256 _totalPeriods, uint256 _cliffDuration,
    uint256 _tokens, address tokenAddress
  ) {
    require(_startTimestamp >= block.timestamp);
    require(_secondsPerPeriod > 0);
    require(_totalPeriods > 0);
    require(tokenAddress != address(0));
    require(_cliffDuration < _totalPeriods);
    require(_tokens > 0);

    startTimestamp = _startTimestamp;
    secondsPerPeriod = _secondsPerPeriod;
    totalPeriods = _totalPeriods;
    cliffDuration = _cliffDuration;
    tokens = _tokens;
    token = LifToken(tokenAddress);
  }

  /**
     @dev Change the LifToken address

     @param newToken the new token address
    */
  function changeToken(address newToken) public onlyOwner {
    token = LifToken(newToken);
  }

  /**
     @dev Get how many tokens are available to be claimed

     @return  { " ": "the amount of tokens ready to be claimed" }
   */
  function getAvailableTokens() public view returns (uint256) {
    uint256 period = block.timestamp.sub(startTimestamp)
      .div(secondsPerPeriod);

    if (period < cliffDuration) {
      return 0;
    } else if (period >= totalPeriods) {
      return tokens.sub(claimed);
    } else {
      return tokens.mul(period.add(1)).div(totalPeriods).sub(claimed);
    }
  }

  /**
     @dev Claim the tokens, they can be claimed only by the owner
     of the contract

     @param amount how many tokens to be claimed
   */
  function claimTokens(uint256 amount) public onlyOwner {
    assert(getAvailableTokens() >= amount);

    claimed = claimed.add(amount);
    token.transfer(owner, amount);
  }

}