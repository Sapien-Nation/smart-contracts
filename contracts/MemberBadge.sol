// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IBadge.sol";
import "./ERC1155Tradable.sol";
import "./TribeToken.sol";

contract MemberBadge is ERC1155Tradable {
    using SafeMath for uint256;

    struct BadgeProp {
        uint256 tribeId;
        uint256 price; // SPN-20
        string uri;
    }

    struct BadgeState {
        uint256 inactive;
        uint256 active;
        uint256 expired;
    }

    // enum BadgeState {
    //     INACTIVE,
    //     ACTIVATED,
    //     EXPIRED
    // }

    mapping(uint256 => BadgeProp) private _badgeProps;
    mapping(uint256 => mapping(address => BadgeState)) private _badgeStates;
    mapping(uint256 => uint256) private _tribeToBadges;

    event MemberBadgeCreated(uint256 id, uint256 tribeId, address indexed creator);

    event MemberBadgeMinted(uint256 id, address indexed recipient, uint256 amount);

    constructor()
        ERC1155Tradable("https://sapien.network/api/member-badge")
    { }

    // modifier existentTribeOnly(
    //     uint256 _tribeId
    // )
    // {
    //     require(_tribeId > 0, "MemberBadge#existentTribeOnly: INVALID_TRIBE");
    //     // todo check if _tribeId exists in TribeToken
    //     _;
    // }

    // modifier existentMemberBadgeOnly(
    //     uint256 _tribeId
    // )
    // {
    //     require(exists(_tribeToBadges[_tribeId]), "MemberBadge#existentMemberBadgeOnly: NON_EXISTENT_MEMBER_BADGE");
    //     _;
    // }

    /**
    * @dev Creates a new token type and assigns _initialSupply to an address
    * @param _initialOwner address of the first owner of the token
    * @param _initialSupply amount to supply the first owner
    * @param _uri Optional URI for this token type
    * @param _data Data to pass if receiver is contract
    * @return The newly created token ID
    */
    function create(
        address _initialOwner,
        uint256 _initialSupply,
        uint256 _tribeId,
        uint256 _price,
        string memory _uri,
        bytes memory _data
    )
        public
        virtual
        returns (uint256)
    {
        uint256 id = create(_initialOwner, _initialSupply, _uri, _data);

        BadgeProp storage badgeProp = _badgeProps[id];
        badgeProp.tribeId = _tribeId;
        badgeProp.price = _price;
        badgeProp.uri = _uri;
        _tribeToBadges[_tribeId] = id;

        BadgeState storage badgeState = _badgeStates[id][_initialOwner];
        badgeState.inactive = _initialSupply;
        // todo transfer SPN-20 from user

        emit MemberBadgeCreated(id, _tribeId, _msgSender());
        return id;
    }

    function mint(
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    )
        public
        virtual
        override
        existentTokenOnly(_id)
    {
        super.mint(_to, _id, _amount, _data);

        BadgeState storage badgeState = _badgeStates[_id][_to];
        badgeState.inactive = badgeState.inactive.add(_amount);
        // todo transfer SPN-20 from user

        emit MemberBadgeMinted(_id, _to, _amount);
    }

    function badgePrice(
        uint256 _id
    )
        public
        virtual
        existentTokenOnly(_id)
        returns (uint256)
    {
        return _badgeProps[_id].price;
    }

    function setBadgePrice(
        uint256 _id,
        uint256 _newPrice
    )
        public
        virtual
        existentTokenOnly(_id)
        creatorOnly(_id)
    {
        uint256 oldPrice = _badgeProps[_id].price;
        require(_newPrice > 0 && _newPrice != oldPrice, "MemberBadge#setBadgePrice: INVALID_BADGE_PRICE");
    }

    function badgeState(
        address _account,
        uint256 _id
    )
        public
        virtual
        existentTokenOnly(_id)
        returns (uint256, uint256, uint256)
    {
        require(balanceOf(_account, _id) > 0, "MemberBadge#badgeState: NO_TOKEN_OWNER");
        BadgeState memory badgeState_ = _badgeStates[_id][_account];
        return (badgeState_.inactive, badgeState_.active, badgeState_.expired);
    }

    function activateBadge(
        address _account,
        uint256 _id
    )
        public
        virtual
        existentTokenOnly(_id)
        creatorOnly(_id)
    {
        require(balanceOf(_account, _id) > 0, "MemberBadge#activateBadge: NO_TOKEN_OWNER");
        _activateBadge(_account, _id);
    }

    function expireBadge(
        address _account,
        uint256 _id
    )
        public
        virtual
        existentTokenOnly(_id)
        creatorOnly(_id)
    {
        require(balanceOf(_account, _id) > 0, "MemberBadge#expireBadge: NO_TOKEN_OWNER");
        _expireBadge(_account, _id);
    }

    function _expireBadge(
        address _account,
        uint256 _id
    )
        internal
        virtual
    {
        BadgeState storage badgeState_ = _badgeStates[_id][_account];
        require(badgeState_.active > 0, "MemberBadge#_expireBadge: NO_ACTIVE_BADGE");
        badgeState_.active--;
        badgeState_.expired++;
    }

    function _activateBadge(
        address _account,
        uint256 _id
    )
        internal
        virtual
    {
        BadgeState storage badgeState_ = _badgeStates[_id][_account];
        require(badgeState_.inactive > 0, "MemberBadge#_activateBadge: NO_INACTIVE_BADGE");
        require(badgeState_.active == 0, "MemberBadge#_activateBadge: ALREADY_ACTIVE_BADGE");
        badgeState_.inactive--;
        badgeState_.active++;
    }

    function _beforeTokenTransfer(
        address _operator,
        address _from,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes memory _data
    )
        internal
        virtual
        override
    {
        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 id = _ids[i];
            uint256 amount = _amounts[i];
            require(_badgeStates[id][_from].inactive >= amount, "MemberBadge#_beforeTokenTransfer: TRANSFER_FAILED");
        }
    }
}
