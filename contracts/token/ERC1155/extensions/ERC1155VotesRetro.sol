// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC1155.sol";
import "../../../governance/utils/Votes.sol";

/** !! THIS DOESN'T WORK !! see _setTokenPower()
 *
 * @dev Extension of ERC1155 to support voting and delegation as implemented by {Votes}.
 * Treat as non-fungible & allow to change the token's power retroactivly
 *
 * Tokens do not count as votes until they are delegated, because votes must be tracked which incurs an additional cost
 * on every transfer. Token holders can either delegate to a trusted representative who will decide how to make use of
 * the votes in governance decisions, or they can delegate to themselves to be their own representative.
 *
 */
abstract contract ERC1155VotesRetro is ERC1155, Votes {
    uint256[] public participatingTokens;

    // List participating tokens & their power
    mapping(uint256 => uint256) private _tokenPower;

    /// THIS FUNCTION IS FOR DEMO PURPOSES ONLY AND SHOULD BE PROTECTED
    function setTokenPower(uint256 tokenId, uint256 power) public {
        return _setTokenPower(tokenId, power);
    }

    /**
     * Set token power & add to participating tokens list
     */
    function _setTokenPower(uint256 tokenId, uint256 power) internal {
        require(power > 0, "ERC1155VotesRetro: removal of token's voting power not yet supported");
        require(_tokenPower[tokenId] == 0, "ERC1155VotesRetro: changing token's voting power not yet supported");

        /* Can't do that - no way to check if token already minted
            require('??' , "ERC1155VotesRetro: must set token's voting power before minting the token");
        */

        // Add to allowed tokens list
        participatingTokens.push(tokenId);
        // Set token power
        _tokenPower[tokenId] = power;

        /* Can't do that - no way to check who alreay has this token
            // Update delegation for all current owners
            _afterTokenTransfer(_msgSender(), address(0), to, ids, amounts);
        */
    }

    /**
     * @dev Calculate the voting power of each token
     * token weight expected to remain consistent and immutable.
     */
    function powerOfToken(uint256 tokenId) public view returns (uint256) {
        return _tokenPower[tokenId];
    }

    /**
     * @dev Must return the voting units held by an account.
     */
    function _getVotingUnits(address account) internal view override returns (uint256 total) {
        for (uint256 i = 0; i < participatingTokens.length; ++i) {
            // Get account's tokens & amounts
            uint256 tokenId = participatingTokens[i];
            uint256 amount = balanceOf(account, tokenId);
            // Multiply by token's power
            if (amount > 0) total += (amount * powerOfToken(tokenId));
        }
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
            uint256 power = powerOfToken(ids[i]);
            if (power > 0) {
                _transferVotingUnits(from, to, power * amounts[i]);
            }
        }
        super._afterTokenTransfer(operator, from, to, ids, amounts, data);
    }
}
