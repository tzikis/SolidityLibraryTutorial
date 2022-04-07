// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./Ownable.sol";


contract Library2 is Ownable{

    event AddedBook(uint bookId, string name, uint8 numOfCopies);
    event NewBorrowing(uint bookId, address borrower);
    event NewReturn(uint bookId, address borrower);

    uint8 private constant UNBORROWED = 0;
    uint8 private constant PAST_BORROWED = 1;
    uint8 private constant BORROWED = 2;

    struct LibraryBookRecord {
        string name;
        uint8 numOfCopies;
        uint8 numOfBorrowedCopies;
    }

    uint[] private booksIndexList;

	mapping(uint => LibraryBookRecord) private books;
    mapping(uint => mapping(address => uint8)) private borrowers;
    mapping(uint => address[]) private anytimeBorrowers;

    //List all books. We create an array of actual book info records for each index.
    //This way there's a 1-to-1 link between id and book on the frontend
    function listBooks() view public returns(LibraryBookRecord[] memory, uint[] memory){

        uint lengthOfbooksIndexList = booksIndexList.length;
        LibraryBookRecord[] memory booksArray = new LibraryBookRecord[](booksIndexList.length);

        for(uint i=0; i < lengthOfbooksIndexList ; i++){
            uint bookId = booksIndexList[i];
            LibraryBookRecord memory book = books[bookId];
            booksArray[i] = book;
        }
        return (booksArray, booksIndexList);
    }

    function addBook(string memory _name, uint8 _numOfCopies) public onlyOwner{
        require(_numOfCopies > 0, "Number of copies should be more than 0");

        uint bookId = uint(keccak256(abi.encodePacked(_name)));

        if(bookExistsHelper(bookId)){
            books[bookId].numOfCopies = books[bookId].numOfCopies + _numOfCopies;
        }
        else{
            books[bookId] = LibraryBookRecord(_name, _numOfCopies, 0);
            booksIndexList.push(bookId);
        }
        
        emit AddedBook(bookId, _name, _numOfCopies);

    }

    //Borrowing book only if the book has enough remaining copies unborrowed and the requester isn't borrowing renting the book
    function borrowBook(uint _bookId) public bookAvailable(_bookId) isNotCurrentBorrower(_bookId, msg.sender) {

        if(!hasBeenBorrowerHelper(_bookId, msg.sender)){
            anytimeBorrowers[_bookId].push(msg.sender);
        }
            

        borrowers[_bookId][msg.sender] = BORROWED;
        books[_bookId].numOfBorrowedCopies++;

        emit NewBorrowing(_bookId, msg.sender);
    }

    //Return the book by removing the borrower from the list of current borrowers (only if the requester is currently borrowing it)
    function returnBook(uint _bookId) public bookExists(_bookId) isCurrentBorrower(_bookId, msg.sender){
       borrowers[_bookId][msg.sender] = PAST_BORROWED;
       books[_bookId].numOfBorrowedCopies--;
 
        emit NewReturn(_bookId, msg.sender);
   }

    function listAllPastBorrowersOfBook(uint _bookId) public view bookExists(_bookId) returns(address[] memory){
        return(anytimeBorrowers[_bookId]);   
    }

    modifier bookExists(uint _bookId){
        require(bookExistsHelper(_bookId), "Book ID doesn't exist");
        _;
    }

    modifier bookAvailable(uint _bookId){
        require(bookAvailableHelper(_bookId), "No available copies of the book");
         _;
   }

    modifier isCurrentBorrower(uint _bookId, address _person) {
        require(isCurrentBorrowerHelper(_bookId, _person), "User has not currently borrowed this book");
        _;
    }

    modifier isNotCurrentBorrower(uint _bookId, address _person) {
        require(!isCurrentBorrowerHelper(_bookId, _person), "User has already currently borrowed this book");
        _;
    }

    // Helper function to check if a book exists
    function bookExistsHelper(uint _bookId) private view returns(bool){
        return (books[_bookId].numOfCopies != 0);
    }

    // Helper function to check if a book is available
    function bookAvailableHelper(uint _bookId) private view bookExists(_bookId) returns(bool){
        return (books[_bookId].numOfCopies > books[_bookId].numOfBorrowedCopies);
    }

    //Helper function making sure a book exists and checking if a specific person is currently borrowing it
    function isCurrentBorrowerHelper(uint _bookId, address _person) private view bookExists(_bookId) returns(bool) {
        uint borrowingStatus = borrowers[_bookId][_person];
        return (borrowingStatus == BORROWED? true: false);
    }

    //Helper function making sure a book exists and checking if a specific person has ever borrowed. Used to add people in the list of borrowers
    function hasBeenBorrowerHelper(uint _bookId, address _person) private view bookExists(_bookId) returns(bool) {
        uint borrowingStatus = borrowers[_bookId][_person];
        return ((borrowingStatus == BORROWED || borrowingStatus == PAST_BORROWED)? true: false);
    }

}
