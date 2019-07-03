//
//  StellarErrors.swift
//  StellarKit
//
//  Created by Kin Foundation
//  Copyright © 2018 Kin Foundation. All rights reserved.
//

import Foundation

/**
 Error types associated to the execution of a `Transaction`.
 */
public enum TransactionError: Int32, Error {
    /** One of the operations failed (none were applied) */
    case txFAILED = -1

    /** ledger closeTime before minTime */
    case txTOO_EARLY = -2
    /** ledger closeTime after maxTime */
    case txTOO_LATE = -3
    /** no operation was specified */
    case txMISSING_OPERATION = -4
    /** sequence number does not match source account */
    case txBAD_SEQ = -5

    /** too few valid signatures / wrong network */
    case txBAD_AUTH = -6
    /** fee would bring account below reserve */
    case txINSUFFICIENT_BALANCE = -7
    /** source account not found */
    case txNO_ACCOUNT = -8
    /** fee is too small */
    case txINSUFFICIENT_FEE = -9
    /** unused signatures attached to transaction */
    case txBAD_AUTH_EXTRA = -10
    /** an unknown error occured */
    case txINTERNAL_ERROR = -11
}

/**
 Error types associated to the creation of an account on the blockchain network.
 */
public enum CreateAccountError: Int32, Error {
    /** invalid destination */
    case CREATE_ACCOUNT_MALFORMED = -1
    /** not enough funds in source account */
    case CREATE_ACCOUNT_UNDERFUNDED = -2
    /** would create an account below the min reserve */
    case CREATE_ACCOUNT_LOW_RESERVE = -3
    /** account already exists */
    case CREATE_ACCOUNT_ALREADY_EXIST = -4
}

/**
 Error types associated to the execution of a payment `Transaction`.
 */
public enum PaymentError: Int32, Error {
    /** bad input */
    case PAYMENT_MALFORMED = -1
    /** not enough funds in source account */
    case PAYMENT_UNDERFUNDED = -2
    /** no trust line on source account */
    case PAYMENT_SRC_NO_TRUST = -3
    /** source not authorized to transfer */
    case PAYMENT_SRC_NOT_AUTHORIZED = -4
    /** destination account does not exist */
    case PAYMENT_NO_DESTINATION = -5
    /** destination missing a trust line for asset */
    case PAYMENT_NO_TRUST = -6
    /** destination not authorized to hold asset */
    case PAYMENT_NOT_AUTHORIZED = -7
    /** destination would go above their limit */
    case PAYMENT_LINE_FULL = -8
    /** Missing issuer on asset */
    case PAYMENT_NO_ISSUER = -9
}

func errorFromResponse(resultXDR: String) -> Error? {
    if let resultXDRData = Data(base64Encoded: resultXDR) {
        let result: TransactionResult
        do {
            result = try XDRDecoder.decode(TransactionResult.self, data: resultXDRData)
        }
        catch {
            return error
        }

        switch result.result {
        case .txSUCCESS:
            break
        case .txERROR (let code):
            if let transactionError = TransactionError(rawValue: code) {
                return transactionError
            }

            return StellarError.unknownError(resultXDR)
        case .txFAILED (let opResults):
            guard let opResult = opResults.first else {
                return StellarError.unknownError(resultXDR)
            }

            switch opResult {
            case .opINNER(let tr):
                switch tr {
                case .PAYMENT (let paymentResult):
                    switch paymentResult {
                    case .failure (let code):
                        if let paymentError = PaymentError(rawValue: code) {
                            return paymentError
                        }

                        return StellarError.unknownError(resultXDR)

                    default:
                        break
                    }
                case .CREATE_ACCOUNT (let createAccountResult):
                    switch createAccountResult {
                    case .failure (let code):
                        if let createAccountError = CreateAccountError(rawValue: code) {
                            return createAccountError
                        }

                        return StellarError.unknownError(resultXDR)

                    default:
                        break
                    }

                default:
                    break
                }

            default:
                break
            }
        }
    } else {
        return StellarError.unknownError(resultXDR)
    }

    return nil
}
