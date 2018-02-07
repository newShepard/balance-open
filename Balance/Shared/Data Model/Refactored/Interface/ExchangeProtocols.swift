//
//  ExchangeApi2.swift
//  Balance
//
//  Created by Benjamin Baron on 1/22/18.
//  Copyright © 2018 Balanced Software, Inc. All rights reserved.
//

import Foundation

public typealias ExchangeOperationCompletionHandler = (_ success: Bool, _ error: Error?, _ data: Any?) -> Void

public enum TransactionType: String, Codable {
    case unknown
    case deposit
    case withdrawal
    case trade
    case margin
    case fee
    case match
    case rebate
    case vault
    case send
    case request
    case transfer
    case buy
    case sell
    case fiat_deposit
    case fiat_withdrawal
    case exchange_deposit
    case exchange_withdrawal
    case vault_withdrawal
}

public protocol ExchangeApi2 {
    func fetchData(for action: APIAction, completion: @escaping ExchangeOperationCompletionHandler) -> Operation?
}

extension ExchangeApi2 {
    func processBaseErrors(response: URLResponse?, error: Error?) -> Error? {
        if let error = error as NSError?, error.code == -1009, error.code == -1001 {
            return ExchangeBaseError.internetConnection
        }
        
        guard let response = response as? HTTPURLResponse else {
            return ExchangeBaseError.other(message: "response malformed")
        }

        switch response.statusCode {
        case 400...499:
            return ExchangeBaseError.invalidCredentials(statusCode: response.statusCode)
        case 500...599:
            return ExchangeBaseError.invalidServer(statusCode: response.statusCode)
        default:
            return nil
        }
    }
    
    func createDict(from data: Data?) -> [AnyHashable: Any]? {
        guard let data = data,
            let rawData = try? JSONSerialization.jsonObject(with: data) else {
                return nil
        }
        
        return rawData as? [AnyHashable: Any]
    }
}

protocol OperationResult {
    var resultBlock: ExchangeOperationCompletionHandler { get }
    var handler: RequestHandler { get }
}

extension OperationResult {
    func handleResponse(for action: APIAction?, data: Data?, response: URLResponse?, error: Error?) -> Any {
        return handler.handleResponseData(for: action, data: data, error: error, ulrResponse: response)
    }
}