// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract NFTMeta is ERC721Enumerable, Ownable {
    using Strings for uint256;

    // 控制銷售和揭示狀態
    bool public _isSaleActive = false; // 是否開啟銷售
    bool public _revealed = false; // 是否已揭示 NFT

    uint256 public constant MAX_SUPPLY = 100; // 可以鑄造的最大 NFT 數量
    uint256 public mintPrice = 0.01 ether; // 每個 NFT 的價格
    uint256 public maxBalance = 10; // 每個地址最多可以持有的 NFT 數量
    uint256 public maxMint = 1; // 每次交易最多可以鑄造的 NFT 數量

    string baseURI; // 基本 URI，所有 NFT 的基礎路徑
    string public notRevealedUri; // 揭示前的 URI，用於顯示未揭示 NFT 的資訊
    string public baseExtension = ".json"; // 檔案擴展名，通常用於 JSON 元數據

    mapping(uint256 => string) private _tokenURIs; // 儲存每個 token 的 URI

    // 自定義錯誤
    error ExceedsMaxSupply(); // 超過最大供應量
    error SaleInactive(); // 銷售未啟動
    error ExceedsMaxBalance(); // 超過最大持有數量
    error InsufficientEther(); // 以太幣不足
    error ExceedsMaxMint(); // 超過每次鑄造的最大數量

    // 建構函數，初始化合約時設定基本 URI 和未揭示 URI
    constructor(
        string memory initBaseURI,
        string memory initNotRevealedUri
    ) ERC721("NFT Meta", "NFT") {
        setBaseURI(initBaseURI);
        setNotRevealedURI(initNotRevealedUri);
    }

    // 鑄造 NFT 的函數
    function mintNFTMeta(uint256 tokenQuantity) public payable {
        if (totalSupply() + tokenQuantity > MAX_SUPPLY)
            revert ExceedsMaxSupply(); // 檢查是否超過最大供應量
        if (!_isSaleActive) revert SaleInactive(); // 檢查銷售是否開啟
        if (balanceOf(msg.sender) + tokenQuantity > maxBalance)
            revert ExceedsMaxBalance(); // 檢查是否超過每個地址的最大持有量
        if (tokenQuantity * mintPrice > msg.value) revert InsufficientEther(); // 檢查是否足夠的以太幣
        if (tokenQuantity > maxMint) revert ExceedsMaxMint(); // 檢查是否超過每次鑄造的最大數量

        _mintNFTMeta(tokenQuantity); // 執行實際的鑄造操作
    }

    // 實際的 NFT 鑄造操作
    function _mintNFTMeta(uint256 tokenQuantity) internal {
        for (uint256 i = 0; i < tokenQuantity; i++) {
            uint256 mintIndex = totalSupply(); // 確定新 NFT 的 ID
            if (totalSupply() < MAX_SUPPLY) {
                _safeMint(msg.sender, mintIndex); // 鑄造 NFT 並安全地發送到調用者地址
            }
        }
    }

    // 返回每個 token 的 URI
    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        ); // 確保 token 存在

        if (!_revealed) {
            return notRevealedUri; // 如果未揭示，返回未揭示的 URI
        }

        string memory _tokenURI = _tokenURIs[tokenId]; // 獲取特定 token 的 URI
        string memory base = _baseURI(); // 獲取基本 URI

        if (bytes(base).length == 0) {
            return _tokenURI; // 如果沒有基本 URI，僅返回 token 的 URI
        }
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI)); // 如果有基本 URI 和 token URI，將它們拼接在一起
        }
        return
            string(abi.encodePacked(base, tokenId.toString(), baseExtension)); // 如果只有基本 URI，返回基本 URI 加上 token ID 和擴展名
    }

    // 內部函數，返回基本 URI
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // 只限擁有者的功能

    // 切換銷售狀態（開啟或關閉）
    function flipSaleActive() public onlyOwner {
        _isSaleActive = !_isSaleActive;
    }

    // 切換 NFT 揭示狀態（揭示或隱藏）
    function flipReveal() public onlyOwner {
        _revealed = !_revealed;
    }

    // 設定每個 NFT 的鑄造價格
    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
    }

    // 設定未揭示的 URI
    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    // 設定基本 URI
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    // 設定檔案擴展名
    function setBaseExtension(
        string memory _newBaseExtension
    ) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    // 設定每個地址的最大持有量
    function setMaxBalance(uint256 _maxBalance) public onlyOwner {
        maxBalance = _maxBalance;
    }

    // 設定每次鑄造的最大數量
    function setMaxMint(uint256 _maxMint) public onlyOwner {
        maxMint = _maxMint;
    }

    // 提取合約中的以太幣，轉移到指定地址
    function withdraw(address to) public onlyOwner {
        uint256 balance = address(this).balance;
        payable(to).transfer(balance);
    }
}
