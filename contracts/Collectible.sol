// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

library Base64 {
    string internal constant TABLE_ENCODE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    bytes internal constant TABLE_DECODE =
        hex"0000000000000000000000000000000000000000000000000000000000000000"
        hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
        hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
        hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(18, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)
                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(12, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)
                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(6, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                // read 4 characters
                dataPtr := add(dataPtr, 4)
                let input := mload(dataPtr)

                // write 3 bytes
                let output := add(
                    add(
                        shl(
                            18,
                            and(
                                mload(add(tablePtr, and(shr(24, input), 0xFF))),
                                0xFF
                            )
                        ),
                        shl(
                            12,
                            and(
                                mload(add(tablePtr, and(shr(16, input), 0xFF))),
                                0xFF
                            )
                        )
                    ),
                    add(
                        shl(
                            6,
                            and(
                                mload(add(tablePtr, and(shr(8, input), 0xFF))),
                                0xFF
                            )
                        ),
                        and(mload(add(tablePtr, and(input, 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

contract SwordNft is ERC721, ERC721Enumerable, Ownable {
    mapping(string => bool) private takenNames;
    mapping(uint256 => Attr) public attributes;

    struct Attr {
        string name;
        string personality;
        uint8 magic;
        uint8 attack;
        uint8 defence;
    }

    constructor() ERC721("Logo", "LOGO") {}

    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721) {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function mint(
        // address to,
        uint256 tokenId,
        string memory _name,
        string memory _personality,
        uint8 _magic,
        uint8 _attack,
        uint8 _defence
    ) public onlyOwner {
        // set to sender for now to save time
        _safeMint(msg.sender, tokenId);
        attributes[tokenId] = Attr(
            _name,
            _personality,
            _magic,
            _attack,
            _defence
        );
    }

    function getSvg(uint256 tokenId) private view returns (string memory) {
        string memory svg;
        // svg = "<svg width='350px' height='350px' viewBox='0 0 24 24' fill='none' xmlns='http://www.w3.org/2000/svg'> <path d='M11.55 18.46C11.3516 18.4577 11.1617 18.3789 11.02 18.24L5.32001 12.53C5.19492 12.3935 5.12553 12.2151 5.12553 12.03C5.12553 11.8449 5.19492 11.6665 5.32001 11.53L13.71 3C13.8505 2.85931 14.0412 2.78017 14.24 2.78H19.99C20.1863 2.78 20.3745 2.85796 20.5133 2.99674C20.652 3.13552 20.73 3.32374 20.73 3.52L20.8 9.2C20.8003 9.40188 20.7213 9.5958 20.58 9.74L12.07 18.25C11.9282 18.3812 11.7432 18.4559 11.55 18.46ZM6.90001 12L11.55 16.64L19.3 8.89L19.25 4.27H14.56L6.90001 12Z' fill='red'/> <path d='M14.35 21.25C14.2512 21.2522 14.153 21.2338 14.0618 21.1959C13.9705 21.158 13.8882 21.1015 13.82 21.03L2.52 9.73999C2.38752 9.59782 2.3154 9.40977 2.31883 9.21547C2.32226 9.02117 2.40097 8.83578 2.53838 8.69837C2.67579 8.56096 2.86118 8.48224 3.05548 8.47882C3.24978 8.47539 3.43783 8.54751 3.58 8.67999L14.88 20C15.0205 20.1406 15.0993 20.3312 15.0993 20.53C15.0993 20.7287 15.0205 20.9194 14.88 21.06C14.7353 21.1907 14.5448 21.259 14.35 21.25Z' fill='red'/> <path d='M6.5 21.19C6.31632 21.1867 6.13951 21.1195 6 21L2.55 17.55C2.47884 17.4774 2.42276 17.3914 2.385 17.297C2.34724 17.2026 2.32855 17.1017 2.33 17C2.33 16.59 2.33 16.58 6.45 12.58C6.59063 12.4395 6.78125 12.3607 6.98 12.3607C7.17876 12.3607 7.36938 12.4395 7.51 12.58C7.65046 12.7206 7.72934 12.9112 7.72934 13.11C7.72934 13.3087 7.65046 13.4994 7.51 13.64C6.22001 14.91 4.82 16.29 4.12 17L6.5 19.38L9.86 16C9.92895 15.9292 10.0114 15.873 10.1024 15.8346C10.1934 15.7962 10.2912 15.7764 10.39 15.7764C10.4888 15.7764 10.5866 15.7962 10.6776 15.8346C10.7686 15.873 10.8511 15.9292 10.92 16C11.0605 16.1406 11.1393 16.3312 11.1393 16.53C11.1393 16.7287 11.0605 16.9194 10.92 17.06L7 21C6.8614 21.121 6.68402 21.1884 6.5 21.19Z' fill='red'/> </svg>";
        //     "<text id='shape5' kritaUseRichText='true' transform='translate(207.0165625, 265.88)' fill='#00796d' stroke='#000000' stroke-opacity='0' stroke-width='0' stroke-linecap='square' stroke-linejoin='bevel' font-family='Open Sans SemiBold' font-size='144' font-size-adjust='0.375679' font-stretch='normal' kerning='0' letter-spacing='0' word-spacing='0'>"
        //     "<tspan x='0'>KO</tspan></text>"
        svg = "<svg xmlns='http://www.w3.org/2000/svg' "
        "xmlns:xlink='http://www.w3.org/1999/xlink' "
        "xmlns:krita='http://krita.org/namespaces/svg/krita' "
        "xmlns:sodipodi='http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd' "
        "width='612pt' "
        "height='612pt' "
        "viewBox='0 0 612 612'>"
        "<defs/>"
        "<rect id='shape0' transform='translate(93.3600000000001, 371.28)' fill='none' stroke='#212121' stroke-width='14.4' stroke-linecap='square' stroke-linejoin='bevel' width='178.56' height='124.8' rx='16.8000077993148' ry='16.8000077993148'/><rect id='shape0' transform='matrix(0.99999997569937 0 0 0.99999997569937 330.96000216956 371.280001516359)' fill='none' stroke='#212121' stroke-width='14.4' stroke-linecap='square' stroke-linejoin='bevel' width='178.56' height='124.8' rx='17.2799982503546' ry='17.2799982503546'/><path id='shape1' transform='translate(276.24, 396.715956588317)' fill='none' stroke='#212121' stroke-width='14.4' stroke-linecap='square' stroke-linejoin='miter' stroke-miterlimit='2' d='M0 5.76404C25.2056 -5.2826 34.8583 2.33406 48 5.76404'/><path id='shape2' transform='translate(74.64, 97.0737938827687)' fill='none' stroke='#212121' stroke-width='14.4' stroke-linecap='square' stroke-linejoin='miter' stroke-miterlimit='2' d='M0 213.006C8.18679 -68.0716 449.743 -73.9175 452.64 213.006'/><path id='shape3' transform='translate(81.3599946392715, 287.28)' fill='none' stroke='#212121' stroke-width='14.4' stroke-linecap='square' stroke-linejoin='miter' stroke-miterlimit='2' d='M0 23.8186C169.241 -10.3126 279.665 -5.77561 443.52 24.7976'/><path id='shape4' transform='translate(122.64, 101.999992262785)' fill='none' stroke='#212121' stroke-width='14.4' stroke-linecap='round' stroke-linejoin='miter' stroke-miterlimit='1.92' d='M149.28 0C84.226 30.1847 16.5563 89.7331 0 194.88'/><path id='shape01' transform='matrix(-0.999999968061144 0 0 0.999999968061144 485.279997616084 101.999992262784)' fill='none' stroke='#212121' stroke-width='14.4' stroke-linecap='square' stroke-linejoin='miter' stroke-miterlimit='2' d='M141.84 0C80.0283 30.4077 15.7311 90.3962 0 196.32'/><text id='shape5' krita:useRichText='true' transform='translate(207.0165625, 265.88)' fill='#212121' stroke='#000000' stroke-opacity='0' stroke-width='0' stroke-linecap='square' stroke-linejoin='bevel' font-family='Open Sans SemiBold' font-size='125' font-size-adjust='0.375679' font-stretch='normal' kerning='0' letter-spacing='0' word-spacing='0'><tspan x='0'>K O</tspan></text><path id='shape6' transform='translate(41.04, 311.28)' fill='none' stroke='#212121' stroke-width='14.4' stroke-linecap='round' stroke-linejoin='miter' stroke-miterlimit='1.92' d='M5.728 42.733C-7.33935 37.0353 1.95131 22.7909 33.6 0'/><path id='shape7' transform='translate(281.04, 88.6473749961536)' fill='none' stroke='#212121' stroke-width='14.4' stroke-linecap='square' stroke-linejoin='miter' stroke-miterlimit='2' d='M0 6.63263C4.00136 -0.81481 41.3136 -3.50521 48 6.63263'/><path id='shape8' transform='translate(50.6400000000001, 330.48)' fill='none' stroke='#212121' stroke-width='14.4' stroke-linecap='round' stroke-linejoin='miter' stroke-miterlimit='1.92' d='M0 24C169.42 -10.4698 337.212 -5.43121 504 24'/><path id='shape02' transform='matrix(-0.999999978175711 0 0 0.999999978175711 561.840000406623 311.033500659559)' fill='none' stroke='#212121' stroke-width='14.4' stroke-linecap='round' stroke-linejoin='miter' stroke-miterlimit='1.91999995708466' d='M5.728 42.733C-7.33935 37.0353 1.95131 22.7909 33.6 0'/>"
        "</svg>";
        return svg;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "',
                        attributes[tokenId].name,
                        '",',
                        '"image_data": "',
                        getSvg(tokenId),
                        '",',
                        '"attributes": [{"trait_type": "Magic", "value": ',
                        uint2str(attributes[tokenId].magic),
                        "},",
                        '{"trait_type": "Attack", "value": ',
                        uint2str(attributes[tokenId].attack),
                        "},",
                        '{"trait_type": "Defence", "value": ',
                        uint2str(attributes[tokenId].defence),
                        "},",
                        '{"trait_type": "Personality", "value": "',
                        attributes[tokenId].personality,
                        '"}',
                        "]}"
                    )
                )
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }
}
