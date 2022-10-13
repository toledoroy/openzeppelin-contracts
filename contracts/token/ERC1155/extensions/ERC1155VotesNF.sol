// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC1155.sol";
import "../../../governance/utils/Votes.sol";

/**
 * @dev Extension of ERC1155 to support voting and delegation as implemented by {Votes}.
 * Treat as non-fungible -- voting power is equal to the total amuount of tokens held multiplied by the token's power
 * (as determind by {powerOfToken}).
 *
 * Tokens do not count as votes until they are delegated, because votes must be tracked which incurs an additional cost
 * on every transfer. Token holders can either delegate to a trusted representative who will decide how to make use of
 * the votes in governance decisions, or they can delegate to themselves to be their own representative.
 *
 */
abstract contract ERC1155VotesNF is ERC1155, Votes {
    // Track the current undelegated balance for each account.
    // this allows to support different voting power for different tokens
    mapping(address => uint256) private _unitsBalance;

    /**
     * @dev Calculate the voting power of each token
     * token weight expected to remain consistent and immutable.
     */
    function powerOfToken(uint256) public view virtual returns (uint256) {
        return 1;
    }

    /**
     * @dev Must return the voting units held by an account.
     */
    function _getVotingUnits(address account) internal view override returns (uint256) {
        return _unitsBalance[account];
    }

    /**
     * @dev Adjusts votes when tokens are transferred.
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 units = (powerOfToken(ids[i]) * amounts[i]);
            _transferVotingUnits(from, to, units);
        }
        super._afterTokenTransfer(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Track all power-adjusted balances
     */
    function _transferVotingUnits(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if (from != address(0)) {
            //Units Removed
            _unitsBalance[from] = _unitsBalance[from] - amount;
        }
        if (to != address(0)) {
            //Units Added
            _unitsBalance[to] = _unitsBalance[to] + amount;
        }
        super._transferVotingUnits(from, to, amount);
    }
}
