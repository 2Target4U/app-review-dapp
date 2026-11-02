// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title AppReviews
/// @notice Only wallet-verified users can rate an app, and only once per app.
contract AppReviews {
    address public owner;

    struct App {
        string name;
        uint256 totalStars;
        uint256 ratingCount;
    }

    struct Review {
        address reviewer;
        uint8 stars;
        string comment;
        uint256 timestamp;
    }

    uint256 public appCount;
    mapping(uint256 => App) public apps;
    mapping(uint256 => Review[]) private reviews;

    // wallet => verified by the owner?
    mapping(address => bool) public verifiedUsers;
    // appId => wallet => has already rated?
    mapping(uint256 => mapping(address => bool)) public hasRated;

    event AppAdded(uint256 indexed appId, string name);
    event UserVerified(address indexed user);
    event AppRated(uint256 indexed appId, address indexed reviewer, uint8 stars);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can do this");
        _;
    }

    constructor() {
        owner = msg.sender;
        verifiedUsers[msg.sender] = true;
    }

    // ---------- Admin ----------

    function addApp(string calldata name) external onlyOwner {
        require(bytes(name).length > 0, "Name is empty");
        apps[appCount] = App(name, 0, 0);
        emit AppAdded(appCount, name);
        appCount++;
    }

    function verifyUser(address user) external onlyOwner {
        verifiedUsers[user] = true;
        emit UserVerified(user);
    }

    // ---------- Reviewers ----------

    function rateApp(uint256 appId, uint8 stars, string calldata comment) external {
        require(appId < appCount, "App does not exist");
        require(verifiedUsers[msg.sender], "Wallet is not verified");
        require(!hasRated[appId][msg.sender], "You already rated this app");
        require(stars >= 1 && stars <= 5, "Stars must be 1 to 5");

        hasRated[appId][msg.sender] = true;
        apps[appId].totalStars += stars;
        apps[appId].ratingCount += 1;
        reviews[appId].push(Review(msg.sender, stars, comment, block.timestamp));

        emit AppRated(appId, msg.sender, stars);
    }

    // ---------- Views ----------

    /// @return average rating multiplied by 100 (e.g. 425 means 4.25)
    function getAverage(uint256 appId) external view returns (uint256) {
        App storage a = apps[appId];
        if (a.ratingCount == 0) return 0;
        return (a.totalStars * 100) / a.ratingCount;
    }

    function getReviews(uint256 appId) external view returns (Review[] memory) {
        return reviews[appId];
    }
}
