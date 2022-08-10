
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IReflect {
    function setReflectionCriteria(uint256 _minPeriod, uint256 _minReflection) external;
    function setReflection(address payable holder, uint256 amount) external;
    function deposit() external payable;
    function process(uint256 gas) external;
}
