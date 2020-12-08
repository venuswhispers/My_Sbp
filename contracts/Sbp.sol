// SPDX-License-Identifier: MIT

pragma solidity >=0.4.22 <0.8.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Sbp is Ownable {
  using SafeMath for uint;

  Event[] public events;
  Bet[] public bets;

  // Hardcode 1:1 static payout odds for now
  uint8[] public payoutOdds = [1, 1];

  // Since Solidity does not support fixed point numbers, a scale factor is used to scale up the
  // payout odd factors when calculating the payout amount
  uint private constant scaleFactor = 1000000;

  struct Event {
    string option1;
    string option2;
    uint startTime;
    uint8 result;
  }

  struct Bet {
    address payable bettor;
    uint eventId;
    uint option;
    uint8[] payoutOdds;
    uint amount;
  }

  function balanceOf() external view returns(uint) {
    return address(this).balance;
  }

  function addEvent(string memory _option1, string memory _option2, uint _startTime) external onlyOwner {
    Event memory newEvent = Event(_option1, _option2, _startTime, 0);
    events.push(newEvent);
  }

  function setEventResult(uint _eventId, uint8 _result) external onlyOwner {
    events[_eventId].result = _result;
  }

  function placeBet(uint _eventId, uint _option) external payable {
    require(events[_eventId].startTime > block.timestamp, "Bets cannot be placed after event has started");

    Bet memory bet = Bet(msg.sender, _eventId, _option, payoutOdds, msg.value);
    bets.push(bet);
  }

  function calculateBetPayoutAmount(Bet memory _bet) pure internal returns(uint) {
    uint payoutMultiplier = SafeMath.div((_bet.payoutOdds[0] * scaleFactor), _bet.payoutOdds[1]);
    uint betProfit = uint(_bet.amount.mul(payoutMultiplier) / scaleFactor);

    return _bet.amount.add(betProfit);
  }

  function claimBetPayout(uint _betId) external {
    Bet memory bet = bets[_betId];
    Event memory betEvent = events[bet.eventId];

    require(msg.sender == bet.bettor, "Only original bettor address can claim payout");
    require(betEvent.result == bet.option, "Only winning bets can claim payout");

    uint payoutAmount = calculateBetPayoutAmount(bet);
    msg.sender.transfer(payoutAmount);
  }
}
