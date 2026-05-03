-- ===============================
-- PART 1: CREATE DATABASE
-- ===============================
CREATE DATABASE BankingSystem;
USE BankingSystem;

-- ===============================
-- PART 2: TABLES
-- ===============================

-- Customers Table
CREATE TABLE Customers (
    CustomerID INT AUTO_INCREMENT PRIMARY KEY,
    FullName VARCHAR(100),
    Email VARCHAR(100) UNIQUE,
    PhoneNumber VARCHAR(20),
    Address TEXT
);

-- Accounts Table
CREATE TABLE Accounts (
    AccountID INT AUTO_INCREMENT PRIMARY KEY,
    CustomerID INT,
    AccountType ENUM('Savings','Checking','Business'),
    Balance DECIMAL(12,2),
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
    ON DELETE CASCADE
);

-- Transactions Table
CREATE TABLE Transactions (
    TransactionID INT AUTO_INCREMENT PRIMARY KEY,
    AccountID INT,
    TransactionType ENUM('Deposit','Withdrawal','Transfer'),
    Amount DECIMAL(12,2),
    TransactionDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (AccountID) REFERENCES Accounts(AccountID)
);

-- Loans Table
CREATE TABLE Loans (
    LoanID INT AUTO_INCREMENT PRIMARY KEY,
    CustomerID INT,
    LoanAmount DECIMAL(12,2),
    InterestRate DECIMAL(5,2),
    LoanTerm INT,
    Status ENUM('Active','Paid','Defaulted'),
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
);

-- Payments Table
CREATE TABLE Payments (
    PaymentID INT AUTO_INCREMENT PRIMARY KEY,
    LoanID INT,
    AmountPaid DECIMAL(12,2),
    PaymentDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (LoanID) REFERENCES Loans(LoanID)
);

-- ===============================
-- PART 3: GENERATE 100,000 RECORDS
-- ===============================

-- Sequence Table
CREATE TABLE seq_100k (n INT PRIMARY KEY);

INSERT INTO seq_100k
SELECT a.N + b.N*10 + c.N*100 + d.N*1000 + e.N*10000 + 1
FROM
(SELECT 0 N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a,
(SELECT 0 N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b,
(SELECT 0 N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) c,
(SELECT 0 N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) d,
(SELECT 0 N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) e
WHERE (a.N + b.N*10 + c.N*100 + d.N*1000 + e.N*10000) < 100000;

-- Insert Customers
INSERT INTO Customers (FullName, Email, PhoneNumber, Address)
SELECT
CONCAT('Customer_', n),
CONCAT('customer', n, '@bank.com'),
CONCAT('+639', FLOOR(RAND()*1000000000)),
CONCAT('Street_', FLOOR(RAND()*10000), ', City_', FLOOR(RAND()*100))
FROM seq_100k;

-- Accounts
INSERT INTO Accounts (CustomerID, AccountType, Balance)
SELECT
CustomerID,
IF(RAND()>0.5,'Savings','Checking'),
ROUND(RAND()*100000,2)
FROM Customers;

-- Transactions
INSERT INTO Transactions (AccountID, TransactionType, Amount)
SELECT
AccountID,
IF(RAND()>0.5,'Deposit','Withdrawal'),
ROUND(RAND()*5000,2)
FROM Accounts;

-- Loans
INSERT INTO Loans (CustomerID, LoanAmount, InterestRate, LoanTerm, Status)
SELECT
CustomerID,
ROUND(RAND()*100000,2),
ROUND(RAND()*10,2),
FLOOR(RAND()*60)+12,
IF(RAND()>0.5,'Active','Paid')
FROM Customers;

-- Payments
INSERT INTO Payments (LoanID, AmountPaid)
SELECT
LoanID,
ROUND(RAND()*5000,2)
FROM Loans;

-- ===============================
-- PART 4: TRANSACTION EXAMPLE
-- ===============================
START TRANSACTION;

UPDATE Accounts SET Balance = Balance - 1000 WHERE AccountID = 1;
UPDATE Accounts SET Balance = Balance + 1000 WHERE AccountID = 2;

INSERT INTO Transactions(AccountID,TransactionType,Amount)
VALUES
(1,'Transfer',1000),
(2,'Transfer',1000);

COMMIT;

-- ===============================
-- PART 5: USER ROLES
-- ===============================

CREATE USER 'bank_clerk'@'localhost' IDENTIFIED BY 'securepassword';
GRANT SELECT, UPDATE ON BankingSystem.Accounts TO 'bank_clerk'@'localhost';

CREATE USER 'auditor'@'localhost' IDENTIFIED BY 'readonlypass';
GRANT SELECT ON BankingSystem.* TO 'auditor'@'localhost';

-- ===============================
-- PART 6: SQL INJECTION SAFE QUERY
-- ===============================

PREPARE stmt FROM 'SELECT * FROM Accounts WHERE AccountID = ?';
SET @id = 5;
EXECUTE stmt USING @id;
DEALLOCATE PREPARE stmt;

-- ===============================
-- PART 7: BULK TRANSACTION
-- ===============================
START TRANSACTION;

UPDATE Accounts SET Balance = Balance - 100 WHERE AccountID BETWEEN 1 AND 2000;
UPDATE Accounts SET Balance = Balance + 100 WHERE AccountID BETWEEN 2001 AND 4000;

SAVEPOINT transfer_batch;

SELECT * FROM Accounts WHERE AccountID BETWEEN 1 AND 5;

ROLLBACK TO transfer_batch;
COMMIT;

-- ===============================
-- PART 8: ISOLATION LEVEL
-- ===============================
SET SESSION TRANSACTION ISOLATION LEVEL SERIALIZABLE;

START TRANSACTION;

UPDATE Accounts SET Balance = Balance - 500 WHERE AccountID = 3;
UPDATE Accounts SET Balance = Balance + 500 WHERE AccountID = 4;

COMMIT;

SELECT @@transaction_isolation;