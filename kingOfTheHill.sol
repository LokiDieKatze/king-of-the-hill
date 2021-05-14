/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol";

contract KingOfTheHill {
    
    /// import de Address dans notre smart contract
    using Address for address payable;
    
    /// state variables
    address private _contractOwner;
    address private _potOwner;
    uint256 private _latestBlock;
    uint256 private _potContent;
    uint256 private _finalPotValue;
    
    /// constructor qui assigne l'addresse de la personne qui déploie au contractOwner ainsi que le msg.value au seed de départ.
    constructor () payable {
        _contractOwner = msg.sender;
        _potContent = msg.value;
        _potOwner = _contractOwner;
    }
    
    /// event pour inscrire le nouveau potOwner à chaque fois
    event BecamePotOwner(address indexed sender, uint256 amount, uint _latestBlock);
    
    ///event pour inscrire le king qui remporte les gains finaux
    event BecameKing(address indexed winner, uint totalAmount, uint _latestBlock);
    
    /// modifier vérifier que msg.sender envoie suffisemment d'ether
    modifier enoughStake {
        require(msg.value >= (address(this).balance - msg.value) *2, "KingOfTheHill: You must send more ether to play!");
        _;
    }
    
    ///modifier pour vérifier que le joueur n'est pas déjà le potOwner
    modifier differentPlayer {
        require(msg.sender != _potOwner, "You are already the owner of the pot!");
        _;
    }
    
    ///modifier pour vérifier que 10 blocs se sont écoulés et que potOwner devient king et qu'on peut effectuer les transactions
    modifier over10Blocks {
        require(_latestBlock != 0, "The king has not been crowned yet!");
        require(block.number - 10 >= _latestBlock, "The king has not been crowned yet!");
        _;
    }
    
    /// fonctions
    
    /// permet de miser 2* le pot, si sender envoie plus d'ether que necessaire, on lui rembourse le trop-reçu
    function doubleStake () public payable enoughStake differentPlayer {
        
        ///dans le cas ou l'on est en dessous des 10 blocs
        if(block.number - 10 < _latestBlock) {
            _potOwner = msg.sender;
            _latestBlock = block.number;
            emit BecamePotOwner(msg.sender, address(this).balance, _latestBlock);
            if(msg.value > (address(this).balance - msg.value)*2) {
            payable(msg.sender).sendValue(msg.value - (address(this).balance - msg.value)*2);
        }
        _potContent = address(this).balance;
        }
        
        /// dans le cas ou on enchéri alors qu'on a atteint les 10 blocs
        if(block.number - 10 >= _latestBlock) {
            getGains();
            _potOwner = msg.sender;
            _latestBlock = block.number;
            emit BecamePotOwner(msg.sender, address(this).balance, _latestBlock);
            payable(msg.sender).sendValue(msg.value - (_potContent*2));
    }
    }
    
    /// permet d'activer les transactions suite au couronnement du gagnant
    function getGains () public over10Blocks {
            /**on prend une nouvelle variable à laquelle on attribue le contenu du smart contrat pour être sur de faire les bon calcul par la suite
            et pas calculer chaque montant à partir de ce qu'il reste dans le pot (après avoir déjà effectuer un ou plusieurs transferts)
            sinon on perd des ethers*/
        emit BecameKing(_potOwner, address(this).balance, _latestBlock);
        _finalPotValue = address(this).balance;
        payable(_potOwner).sendValue((_finalPotValue*80)/100);
        payable(_contractOwner).sendValue((_finalPotValue*10)/100);
        _potContent = (_finalPotValue*10)/100;
        _finalPotValue = 0;
    }
    
    ///Fonctions accessoires, notamment pour débuguer, mais potentiellement utiles
    function showPotContent() public view returns (uint256) {
        return _potContent;
    }
    function showContractContent () public view returns (uint256) {
        return address(this).balance;
    }
    function showLatestBlock() public view returns (uint256) {
        return _latestBlock;
    }
    function showCurrentBlock() public view returns (uint256) {
        return block.number;
    }
    function showPotOwner() public view returns (address) {
        return _potOwner;
    }
}