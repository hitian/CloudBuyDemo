//
//  Api.swift
//  YunBuy
//
//  Created by Jia Tian on 3/3/18.
//  Copyright © 2018 Jia Tian. All rights reserved.
//

import Foundation
import IDZSwiftCommonCrypto

class Api {
    static let _instance = Api()
    static func instance() -> Api {
        return _instance
    }
    //let baseURL = "http://127.0.0.1:3000"
    let baseURL = "http://ym.shop.ymwlw.com/v1"
    let defaultSession: URLSession
    var dataTask: URLSessionDataTask? = nil
    var sessionConfiguration = URLSessionConfiguration.default
    var tokenString = ""
    
    init() {
        sessionConfiguration.httpAdditionalHeaders = [
            "User-Agent": "CloudTrade/1.1 (iPhone; iOS 11.2.6; Scale/3.00)",
            "Content-Type": "application/json; charset=utf-8"
        ]
        defaultSession = URLSession(configuration: sessionConfiguration)
    }
    
    func token(completion: @escaping (String?)-> Void) {
        if let token = Account().getToken() {
            tokenString = token
            completion(nil)
        } else {
            doTokenAuth(completion: completion)
        }
    }
    
    func doTokenAuth(completion: @escaping (String?)-> Void) {
        let phone = Account().readUsername()!
        let password = Account().readPassword()!
        let passwordMD5 = hexString(fromArray: (Digest(algorithm: .md5).update(string: password)?.final())!)
        let json: [String:Any] = ["phone": phone, "password": passwordMD5]
        let jsonData = try! JSONSerialization.data(withJSONObject: json, options: .sortedKeys)
        doRequest(url: "/token", data: jsonData, completion: { (isOk, response) in
            if !isOk {
                completion("Token request failed")
                return
            }
            let token = response as! String
            Account().setToken(token: token)
            self.tokenString = token
            completion(nil)
        })
    }
    
    var retryTimes: Int = 1
    func balance(completion: @escaping (Bool, String) -> Void) {
        token { (error) in
            if let error = error {
                return completion(false, error)
            }
            self.doRequest(url: "/balance", data: nil, completion: { (isOk, response) in
                print("balance response", response)
                if let _response = response as? [String: Any], let code = _response["code"] as? Int {
                    if code == 0, let responseData = _response["data"] as? [String: String], let amount = responseData["amount"] {
                        completion(true, amount)
                        return
                    } else if code == 401 {
                        if self.retryTimes > 0 {
                            self.doTokenAuth(completion: { (error) in
                                self.balance(completion: completion)
                            })
                        } else {
                            completion(false, "login retry failed.")
                        }
                        self.retryTimes -= 1
                    }
                }
                completion(false, "wrong response: \(response)")
            })
        }
    }
    
    func doOrder(info: OrderInfo, completion: @escaping (Bool, String, String) -> Void) {
        let url = "/scan/order"
        let data = try! JSONEncoder().encode(info)
        //let jsonString = String(data: data, encoding: .utf8)!
        doRequest(url: url, data: data) { (isOk, response) in
            print("order response: \(response)")
            if let _response = response as? [String: Any], let code = _response["code"] as? Int {
                if code == 0, let responseData = _response["data"] as? [String: String], let amount = responseData["amount"], let orderId = responseData["orderId"] {
                    completion(true, orderId, amount)
                    return
                }
                completion(false, "\(_response["message"] ?? "")", "")
                return
            }
            completion(false, "request error.", "")
        }
        
    }
    func doPay(orderId: String, completion: @escaping (Bool, String) -> Void) {
        let url = "/balance/pay"
        let payPassword = Account().readPayPassword()
        let payPasswordMD5 = hexString(fromArray: (Digest(algorithm: .md5).update(string: payPassword!)?.final())!)
        let payInfo = PayInfo(orderId: orderId, password: payPasswordMD5)
        let data = try! JSONEncoder().encode(payInfo)
        doRequest(url: url, data: data) { (isSuccess, response) in
            print("pay response: \(response)")
            if let _response = response as? [String: Any], let code = _response["code"] as? Int {
                if code == 0, let responseData = _response["data"] as? [String: String], let status = responseData["status"], let orderId = responseData["orderId"] {
                    completion(true, orderId + "|" + status)
                    return
                }
                completion(false, "\(_response["message"] ?? "")")
                return
            }
            completion(false, "request error.")
        }
    }
    
    private func doRequest(url: String, data: Data?, completion: @escaping (Bool, Any)-> Void ) {
        dataTask?.cancel()
        if let requestURL = URLComponents(string: baseURL + url) {
            var request = URLRequest(url: requestURL.url!)
            request.httpMethod = "POST"
            if tokenString != "" {
                request.setValue(tokenString, forHTTPHeaderField: "Token")
            }
            print("REQUEST %s ", url)
            if let data = data {
                request.httpBody = data
                print("REQUEST DATA: %s", String.init(data: data, encoding: .utf8) ?? "-")
            }
            
            dataTask = defaultSession.dataTask(with: request, completionHandler: { (data, response, error) in
                if url == "/token" {
                    //token request has no response data. need read header.
                    if let uResponse = response as? HTTPURLResponse {
                        if let token = uResponse.allHeaderFields["Token"] as? String {
                            print("received token [%s]", token)
                            completion(true, token)
                            return
                        }
                    }
                    completion(false, "can not found auth header in response.")
                    return
                }
                var responseData = ""
                var json: Any = []
                if let data = data {
                    responseData = String(data: data, encoding: .utf8) ?? ""
                    do {
                        json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
                    } catch {
                        completion(false, "response json decode failed.")
                        return
                    }
                }
                print("RESPONSE %s with data [%s]", url, responseData)
                completion(true, json)
            })
            dataTask?.resume()
        }
    }
}

struct OrderInfo: Encodable {
    var machNo: String
    var payType: String
    var orderNo: String
    var subject: String
    var goodsPrice: String
    var goodsNo: String
    var merchantNo: String
}

struct PayInfo: Encodable {
    var orderId: String
    var password: String
}
