//
//  ShapeShiftTransferOperatorTests.swift
//  BalanceOpenTests
//
//  Created by Red Davis on 22/08/2017.
//  Copyright © 2017 Balanced Software, Inc. All rights reserved.
//

import XCTest
@testable import BalanceOpen


internal final class ShapeShiftTransferOperatorTests: XCTestCase
{
    // Private
    private let btcAccount = BTCAccount()
    private let ethAccount = ETHAccount()
    private var transferRequest: TransferRequest!
    private var transferOperator: ShapeShiftTransferOperator!
    
    private var mockSession: MockSession!
    private var apiClient: ShapeShiftAPIClient!
    
    // MARK: Setup
    
    override func setUp()
    {
        super.setUp()
        
        self.transferRequest = try! TransferRequest(source: self.btcAccount, recipient: self.ethAccount, amount: 1.0)
        self.mockSession = MockSession()
        self.apiClient = ShapeShiftAPIClient(session: self.mockSession)
        self.transferOperator = ShapeShiftTransferOperator(request: self.transferRequest, shapeShiftClient: self.apiClient)
    }
    
    override func tearDown()
    {
        super.tearDown()
    }
    
    // MARK: Quote
    
    internal func testQuotes()
    {
        // Mock API requests
        let coinPairData = self.loadMockData(filename: "GetCoins.json")
        let coinPairResponse = MockSession.Response(urlPattern: "/getcoins", data: coinPairData, statusCode: 200, headers: nil)
        self.mockSession.mockResponses.append(coinPairResponse)
        
        let marketInfoData = self.loadMockData(filename: "MarketInfoBTC-ETH.json")
        let marketInfoResponse = MockSession.Response(urlPattern: "/marketinfo", data: marketInfoData, statusCode: 200, headers: nil)
        self.mockSession.mockResponses.append(marketInfoResponse)
        
        // Test
        let expectation = self.expectation(description: "fetch quote")
        
        self.transferOperator.fetchQuote { [unowned self] (quote, error) in
            // Response tests
            XCTAssertNotNil(quote)
            XCTAssertNil(error)
            
            // Request tests
            XCTAssertEqual(self.mockSession.numberOfRequests(matching: "/getcoins"), 1)
            XCTAssertEqual(self.mockSession.numberOfRequests(matching: "/marketinfo"), 1)
            
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 10.0, handler: nil)
    }
    
    // MARK: Transfer
    
    internal func testPerformingTransfer()
    {
        // Mock API requests
        let coinPairData = self.loadMockData(filename: "GetCoins.json")
        let coinPairResponse = MockSession.Response(urlPattern: "/getcoins", data: coinPairData, statusCode: 200, headers: nil)
        self.mockSession.mockResponses.append(coinPairResponse)
        
        let marketInfoData = self.loadMockData(filename: "MarketInfoBTC-ETH.json")
        let marketInfoResponse = MockSession.Response(urlPattern: "/marketinfo", data: marketInfoData, statusCode: 200, headers: nil)
        self.mockSession.mockResponses.append(marketInfoResponse)
        
        let createTransactionData = self.loadMockData(filename: "Shift.json")
        let createTransactionResponse = MockSession.Response(urlPattern: "/shift", data: createTransactionData, statusCode: 201, headers: nil)
        self.mockSession.mockResponses.append(createTransactionResponse)
        
        // Test
        let expectation = self.expectation(description: "fetch quote")
        
        self.transferOperator.performTransfer { (success, transactionID, error) in
            XCTAssert(success)
            XCTAssertNil(error)
            
            // Request tests
            XCTAssertEqual(self.mockSession.numberOfRequests(matching: "/getcoins"), 1)
            XCTAssertEqual(self.mockSession.numberOfRequests(matching: "/marketinfo"), 1)
            XCTAssertEqual(self.mockSession.numberOfRequests(matching: "/shift"), 1)
            
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 10.0, handler: nil)
    }
}


fileprivate final class BTCAccount: Transferable
{
    fileprivate var currencyType = Currency(rawValue: "BTC")!
    
    fileprivate var directTransferOperator: TransferOperator.Type? { return nil }
    fileprivate var exchangeTransferOperator: TransferOperator.Type? { return ShapeShiftTransferOperator.self }
    
    var canRequestCryptoAddress: Bool { return true }
    var canMakeWithdrawal: Bool { return true }
    
    func fetchAddress(_ completionHandler: @escaping (_ address: String?, _ error: Error?) -> Void)
    {
        completionHandler("12345", nil)
    }
    
    func make(withdrawal: Withdrawal, completionHandler: @escaping (_ success: Bool, _ error: Error?) -> Void) throws
    {
        completionHandler(true, nil)
    }
}


fileprivate final class ETHAccount: Transferable
{
    fileprivate var currencyType = Currency(rawValue: "ETH")!
    
    fileprivate var directTransferOperator: TransferOperator.Type? { return nil }
    fileprivate var exchangeTransferOperator: TransferOperator.Type? { return ShapeShiftTransferOperator.self }
    
    var canRequestCryptoAddress: Bool { return true }
    var canMakeWithdrawal: Bool { return true }
    
    func fetchAddress(_ completionHandler: @escaping (_ address: String?, _ error: Error?) -> Void)
    {
        completionHandler("12345", nil)
    }
    
    func make(withdrawal: Withdrawal, completionHandler: @escaping (_ success: Bool, _ error: Error?) -> Void) throws
    {
        completionHandler(true, nil)
    }
}
