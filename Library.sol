// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./Ownable.sol";


contract Library is Ownable{
    uint8 private constant isBorrowing = 1;
    uint8 private constant isReturn = 0;

    struct LibraryBookRecord {
        uint bookId;
        string name;
        uint numOfCopies;
        address[] currentBorrowers;
        address[] anytimeBorrowers;
    }

    LibraryBookRecord[] booksList;

    //List all books. This will also show the current borrowers, which we might not want to show
    // Since this was not specified, I'm doing this the easiest way
    function listBooks() view public returns(LibraryBookRecord[] memory){
        return booksList;
    }

    function addBook(string memory _name, uint _numOfCopies) public onlyOwner{
        require(_numOfCopies > 0, "Number of copies should be more than 0");

        address[] memory newCurrentBorrowers;
        address[] memory newAnytimeBorrowers;

        booksList.push(LibraryBookRecord(booksList.length, _name, _numOfCopies, newCurrentBorrowers, newAnytimeBorrowers));

    }

    //Borrowing book only if the book has enough remaining copies unborrowed and the requester isn't borrowing renting the book
    function borrowBook(uint _bookId) public bookAvailable(_bookId) isNotCurrentBorrower(_bookId, msg.sender){
        booksList[_bookId].currentBorrowers.push(msg.sender);

        if(!hasBeenBorrowerHelper(_bookId, msg.sender))
            booksList[_bookId].anytimeBorrowers.push(msg.sender);

    }

    //Return the book by removing the borrower from the list of current borrowers (only if the requester is currently borrowing it)
    function returnBook(uint _bookId) public isCurrentBorrower(_bookId, msg.sender){
        uint borrowerIndex;
        uint arrayLength = booksList[_bookId].currentBorrowers.length;
        // Find which slot(index) of the array our borrower address/record is at
        for(uint i=0; i < arrayLength; i++){
            if(booksList[_bookId].currentBorrowers[i] == msg.sender)
            {
                borrowerIndex = i;
                break;
            }
        }

        //To remove it, we copy the last record in its place and then remove the last record. If it's already the last record, just remove
        if(borrowerIndex != arrayLength-1)
            booksList[_bookId].currentBorrowers[borrowerIndex] = booksList[_bookId].currentBorrowers[arrayLength - 1];
        
        booksList[_bookId].currentBorrowers.pop();

    }

    modifier bookAvailable(uint _bookId){
        require(bookAvailableHelper(_bookId), "No available copies of the book");
         _;
   }

    modifier bookExists(uint _bookId){
        require(_bookId < booksList.length , "Book ID doesn't exist");
        _;
    }

    modifier isCurrentBorrower(uint _bookId, address _person) {
        require(isCurrentBorrowerHelper(_bookId, _person), "User has already borrowed this book");
        _;
    }

    modifier isNotCurrentBorrower(uint _bookId, address _person) {
        require(!isCurrentBorrowerHelper(_bookId, _person), "User has already borrowed this book");
        _;
    }

    //Helpfer function making sure a book exists and checking if a specific person is currently borrowing it
    function isCurrentBorrowerHelper(uint _bookId, address _person) private view bookExists(_bookId) returns(bool) {
        bool flag = false;

        for(uint i=0; i < booksList[_bookId].currentBorrowers.length; i++){
            if(booksList[_bookId].currentBorrowers[i] == _person)
            {
                flag = true;
                break;
            }
        }

        return flag;

    }

    //Helper function making sure a book exists and checking if a specific person has ever borrowed. Used to add people in the list of borrowers
    function hasBeenBorrowerHelper(uint _bookId, address _person) private view bookExists(_bookId) returns(bool) {
        bool flag = false;

        for(uint i=0; i < booksList[_bookId].anytimeBorrowers.length; i++){
            if(booksList[_bookId].anytimeBorrowers[i] == _person)
            {
                flag = true;
                break;
            }
        }

        return flag;

    }

    //Helper function to check if a book exists
    function bookAvailableHelper(uint _bookId) private view bookExists(_bookId) returns(bool){
        return (booksList[_bookId].numOfCopies > booksList[_bookId].currentBorrowers.length);
    }
}
