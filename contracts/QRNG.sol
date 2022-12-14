// MyEpicNFT.sol
// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

// いくつかの OpenZeppelin のコントラクトをインポートします。
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
// utils ライブラリをインポートして文字列の処理を行います。
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@api3/airnode-protocol/contracts/rrp/requesters/RrpRequesterV0.sol";
import "hardhat/console.sol";

// Base64.solコントラクトからSVGとJSONをBase64に変換する関数をインポートします。
import { Base64 } from "./libraries/Base64.sol";

// インポートした OpenZeppelin のコントラクトを継承しています。
// 継承したコントラクトのメソッドにアクセスできるようになります。
contract QRNG is ERC721URIStorage, Ownable, RrpRequesterV0 {
  // OpenZeppelin　が　tokenIds　を簡単に追跡するために提供するライブラリを呼び出しています
  using Counters for Counters.Counter;
  // _tokenIdsを初期化（_tokenIds = 0）
  Counters.Counter public _tokenIds;

  address public airnode;
  bytes32 public endpointIdUint256;
  address public sponsorWallet;

  mapping(bytes32 => bool) expectingRequestIdToBeFulfilled;
  mapping(bytes32 => address) requestToRequester;
  mapping(bytes32 => uint256) public requestIdToRandomNumber;

  // SVGコードを作成します。
  // 変更されるのは、表示される単語だけです。
  // すべてのNFTにSVGコードを適用するために、baseSvg変数を作成します。
  string baseSvg = "<svg xmlns='http://www.w3.org/2000/svg' preserveAspectRatio='xMinYMin meet' viewBox='0 0 350 350'><style>.base { fill: white; writing-mode: vertical-rl; font-family: 'Hannari', serif; font-size: 17px; }</style><rect width='100%' height='100%' fill='black' /><text x='50%' y='50%' class='base' dominant-baseline='middle' text-anchor='middle'>";

  // 3つの配列 string[] に、それぞれランダムな単語を設定しましょう。
  string[] firstWords = [unicode"世の中は ", unicode"おじさんと ", unicode"イーサリアン ", unicode"ビットコイン ", unicode"ながれぼし ", unicode"古の "];
  string[] secondWords = [unicode"生まれて初めて ", unicode"人生かけたら ", unicode"インターネットで ", unicode"ブロックチェーンの ", unicode"がばガバナンスで ", unicode"フィルムカメラで "];
  string[] thirdWords = [unicode"メタバース", unicode"給付金", unicode"ナイスガイ", unicode"八重桜", unicode"人生だ", unicode"価値がある"];

  // MyEpicNFT.sol
  event RequestedUint256(bytes32 indexed requestId);
  event ReceivedUint256(bytes32 indexed requestId, uint256 response);
  event HaiQMinted(address sender, uint256 tokenId);

  // NFT トークンの名前とそのシンボルを渡します。
  constructor(address _airnodeRrp) RrpRequesterV0(_airnodeRrp) ERC721 ("QRNG", "QRNG") {
    console.log("This is my NFT contract.");
  }

  function setRequestParameters(
      address _airnode,
      bytes32 _endpointIdUint256,
      address _sponsorWallet
  ) external onlyOwner {
       airnode = _airnode;
       endpointIdUint256 = _endpointIdUint256;
       sponsorWallet = _sponsorWallet;
  }

  function _pickRandomFirstWord(uint256 randomNumber) public view returns (string memory) {
    // pickRandomFirstWord 関数のシードとなる rand を作成します。
    uint256 rand = uint256(keccak256(abi.encodePacked("FIRST_WORD", Strings.toString(randomNumber))));
    rand = rand % firstWords.length;
    return firstWords[rand];
  }

  // pickRandomSecondWord関数は、2番目に表示されるの単語を選びます。
  function _pickRandomSecondWord(uint256 randomNumber) public view returns (string memory) {
    // pickRandomSecondWord 関数のシードとなる rand を作成します。
    uint256 rand = uint256(keccak256(abi.encodePacked("SECOND_WORD", Strings.toString(randomNumber))));
    rand = rand % secondWords.length;
    return secondWords[rand];
  }

  // pickRandomThirdWord関数は、3番目に表示されるの単語を選びます。
  function _pickRandomThirdWord(uint256 randomNumber) public view returns (string memory) {
    // pickRandomThirdWord 関数のシードとなる rand を作成します。
    uint256 rand = uint256(keccak256(abi.encodePacked("THIRD_WORD", Strings.toString(randomNumber))));
    rand = rand % thirdWords.length;
    return thirdWords[rand];
  }

  function requestRandomCharacter() public returns (bytes32) {
      bytes32 requestId = airnodeRrp.makeFullRequest(
          airnode,
          endpointIdUint256,
          address(this),
          sponsorWallet,
          address(this),
          this.fulfillUint256.selector,
          ""
      );
      expectingRequestIdToBeFulfilled[requestId] = true;
      requestToRequester[requestId] = msg.sender;
      emit RequestedUint256(requestId);
      return requestId;
  }

  function fulfillUint256(bytes32 requestId, bytes calldata data)
    external
    onlyAirnodeRrp
  {
    require(
        expectingRequestIdToBeFulfilled[requestId],
        "Request ID not known"
    );
    expectingRequestIdToBeFulfilled[requestId] = false;
    uint256 randomNumber = abi.decode(data, (uint256));
    requestIdToRandomNumber[requestId] = randomNumber; // Store the number to be used later on
    emit ReceivedUint256(requestId, randomNumber);
  }

  // You can call this function after the fulfillment with a large gas limit

  function makeAnHaiQNFT(bytes32 requestId) external {

    uint256 randomNumber = requestIdToRandomNumber[requestId];
    require(randomNumber != 0, "No such request ID"); // It's safe to assume that the random number will never be 0
    delete requestIdToRandomNumber[requestId]; // Delete the number to prevent it from being used again

    uint256 newItemId = _tokenIds.current();

	  // 3つの単語を連携して格納する変数 combinedWord を定義します。
    string memory combinedWord = string(abi.encodePacked(_pickRandomFirstWord(randomNumber), _pickRandomSecondWord(randomNumber), _pickRandomThirdWord(randomNumber)));
    string memory title = string(abi.encodePacked("HaiQ#", Strings.toString(newItemId)));

    // 3つの単語を連結して、<text>タグと<svg>タグで閉じます。
    string memory finalSvg = string(abi.encodePacked(baseSvg, combinedWord, "</text></svg>"));

	  // NFTに出力されるテキストをターミナルに出力します。
	  console.log("\n----- SVG data -----");
    console.log(finalSvg);
    console.log("--------------------\n");

    // JSONファイルを所定の位置に取得し、base64としてエンコードします。
    string memory json = Base64.encode(
        bytes(
            string(
                abi.encodePacked(
                    '{"name": "',
                    title,
                    '", "description": "A highly acclaimed collection of HaiQ.", "image": "data:image/svg+xml;base64,',
                    //  data:image/svg+xml;base64 を追加し、SVG を base64 でエンコードした結果を追加します。
                    Base64.encode(bytes(finalSvg)),
                    '"}'
                )
            )
        )
    );

    // データの先頭に data:application/json;base64 を追加します。
    string memory finalTokenUri = string(
        abi.encodePacked("data:application/json;base64,", json)
    );

	  console.log("\n----- Token URI ----");
    console.log(finalTokenUri);
    console.log("--------------------\n");

    //  NFT を送信者に Mint します。
    _safeMint(requestToRequester[requestId], newItemId);

    // tokenURIを更新します。
    _setTokenURI(newItemId, finalTokenUri);

 	  // NFTがいつ誰に作成されたかを確認します。
	  console.log("An NFT w/ ID %s has been minted to %s", newItemId, requestToRequester[requestId]);

    // 次の NFT が Mint されるときのカウンターをインクリメントする。
    _tokenIds.increment();

    // MyEpicNFT.sol
    emit HaiQMinted(requestToRequester[requestId], newItemId);
  }


  function getLastTokenId() public view returns (uint256) {
      uint256 lastTokenId = _tokenIds.current();
      return lastTokenId;
  }
}

