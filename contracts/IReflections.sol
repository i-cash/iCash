
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IReflections {
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external;
    function setShare(address payable shareholder, uint256 amount) external;
    function deposit() external payable;
    function process(uint256 gas) external;
}
