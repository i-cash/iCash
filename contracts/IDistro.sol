
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IERC20.sol";
interface IDistro {
    function setReflectionCriteria(uint256 _pool, uint256 _minPeriod, uint256 _minDistribution) external;
    function updatePool(uint256 _pool, address payable sender) external;
    function enterStacking(uint256 _amount, uint256 _pool, address payable _stacker) external;
    function leaveStacking(uint256 _amount, uint256 _pool, address payable _stacker) external;
    function pendingIReflect(uint256 _pool, address payable _stacker, bool test) external returns (uint256);
    function claimReflections(uint256 _pool, address payable foundling) external;
    function stackingBalance(uint256 _pool, address payable _stacker) external returns (uint256);
    function updateBlockReflections(uint256 _pool, uint256 reflectionsAmount) external;
    function updateMultiplier(uint256 multiplierNumber) external;
    function createReflectionsPool(IERC20 _stackingToken, IERC20 _reflectionsToken, uint256 _blockReflections, uint256 _minPeriod, uint256 _minDist, uint256 _genesisBlock, uint decimals) external;
    // function process(uint256 _pool, uint256 gas) external;
}