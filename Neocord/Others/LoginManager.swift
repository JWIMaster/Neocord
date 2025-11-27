import Foundation
import UIKit
import FoundationCompatKit
import SwiftcordLegacy



public class LoginManager {

    public enum LoginError: Error {
        case invalidURL
        case transportError(Error)
        case emptyResponse
        case invalidJSON
        case twoFactorRequired(ticket: String)
        case missingTwoFactorTicket
        case missingFingerprint
        case serverMessage(String)
        case parameterError(message: String)
        case captchaRequired(service: String, siteKey: String)
        case unknown
    }

    private let apiRoot = "https://discordapp.com/api/v9"
    private let session: URLSessionCompat
    private var twoFactorTicket: String?
    private var fingerprint: String?

    public init(session: URLSessionCompat = .shared) {
        self.session = session
    }

    public var token: String? {
        get { UserDefaults.standard.string(forKey: "discordToken") }
        set {
            if let value = newValue {
                UserDefaults.standard.set(value, forKey: "discordToken")
            } else {
                UserDefaults.standard.removeObject(forKey: "discordToken")
            }
        }
    }

    private func fetchFingerprint(completion: @escaping (Result<Void, LoginError>) -> Void) {
        guard let url = URL(string: "\(apiRoot)/auth/fingerprint") else {
            completion(.failure(.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(discordSuperPropertiesBase64, forHTTPHeaderField: "X-Super-Properties")
        request.setValue("Discord-iOS-Client (Swiftcord, 1.0)", forHTTPHeaderField: "User-Agent") // Funni

        session.dataTask(with: request) { [weak self] data, _, error in
            guard let self = self else { return }

            if let error = error {
                completion(.failure(.transportError(error)))
                return
            }

            guard let data = data else {
                completion(.failure(.emptyResponse))
                return
            }

            // Parse fingerprint
            if let fpString = try? JSONSerialization.jsonObject(with: data) as? String {
                self.fingerprint = fpString
                completion(.success(()))
                return
            }

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let fp = json["fingerprint"] as? String {
                self.fingerprint = fp
                print(self.fingerprint)
                completion(.success(()))
                return
            }

            completion(.failure(.invalidJSON))
        }.resume()
    }

    public func login(email: String, password: String, completion: @escaping (Result<Void, LoginError>) -> Void) {
        fetchFingerprint { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let err):
                completion(.failure(err))
            case .success:
                guard let fp = self.fingerprint else {
                    completion(.failure(.missingFingerprint))
                    return
                }

                guard let url = URL(string: "\(self.apiRoot)/auth/login") else {
                    completion(.failure(.invalidURL))
                    return
                }

                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue(discordSuperPropertiesBase64, forHTTPHeaderField: "X-Super-Properties")
                request.setValue(fp, forHTTPHeaderField: "X-Fingerprint")
                request.setValue("Discord-iOS-Client (Swiftcord, 1.0)", forHTTPHeaderField: "User-Agent") // Funni
                request.setValue("*/*", forHTTPHeaderField: "Accept") // ADDED

                let body: [String: Any?] = [
                    "login": email,
                    "password": password,
                    "gift_code_sku_id": nil,
                    "login_source": nil,
                    "undelete": false
                ]

                do {
                    request.httpBody = try JSONSerialization.data(withJSONObject: Self.cleanJSON(body))
                } catch {
                    completion(.failure(.invalidJSON))
                    return
                }

                self.session.dataTask(with: request) { data, response, error in
                    if let e = error { completion(.failure(.transportError(e))); return }
                    guard let http = response as? HTTPURLResponse else { completion(.failure(.unknown)); return }
                    guard let data = data, !data.isEmpty else { completion(.failure(.emptyResponse)); return }
                    
                    if let jsonResponse = try? JSONSerialization.jsonObject(with: data) {
                        print("DEBUG: Raw API Response on Error:", jsonResponse)
                    } else if let stringResponse = String(data: data, encoding: .utf8) {
                        print("DEBUG: Raw API String Response on Error:", stringResponse)
                    }

                    if (200...299).contains(http.statusCode), let token = Self.parseToken(from: data) {
                        self.token = token
                        completion(.success(()))
                        return
                    }

                    if let parsed = Self.parseErrorPayload(from: data) {
                        switch parsed {
                        case .twoFactor(let ticket):
                            self.twoFactorTicket = ticket
                            completion(.failure(.twoFactorRequired(ticket: ticket)))
                        case .captcha(let svc, let key):
                            completion(.failure(.captchaRequired(service: svc, siteKey: key)))
                        case .message(let msg):
                            completion(.failure(.serverMessage(msg)))
                        case .parameter(let msg):
                            completion(.failure(.parameterError(message: msg)))
                        }
                        return
                    }

                    completion(.failure(.unknown))
                }.resume()
            }
        }
    }


    public func loginTwoFactor(code: String, completion: @escaping (Result<Void, LoginError>) -> Void) {
        // Ensure ticket and fingerprint exist
        guard let ticket = twoFactorTicket else { completion(.failure(.missingTwoFactorTicket)); return }
        guard let fp = fingerprint else { completion(.failure(.missingFingerprint)); return }

        guard let url = URL(string: "\(apiRoot)/auth/mfa/totp") else {
            completion(.failure(.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(discordSuperPropertiesBase64, forHTTPHeaderField: "X-Super-Properties")
        request.setValue(fp, forHTTPHeaderField: "X-Fingerprint")
        request.setValue("Discord-iOS-Client (Swiftcord, 1.0)", forHTTPHeaderField: "User-Agent") // Funni
        request.setValue("*/*", forHTTPHeaderField: "Accept") // ADDED


        // Use NSNull() for null fields (Discord expects actual nulls, not missing keys)
        let body: [String: Any] = [
            "ticket": ticket,
            "code": code,
            "gift_code_sku_id": NSNull(),
            "login_source": NSNull()
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(.failure(.invalidJSON))
            return
        }

        // Debugging output
        if let bodyData = request.httpBody, let bodyStr = String(data: bodyData, encoding: .utf8) {
            print("2FA POST body:", bodyStr)
            print("Headers:", request.allHTTPHeaderFields ?? [:])
            print("Ticket:", ticket)
            print("Fingerprint:", fp)
            print("2FA code:", code)
        }

        session.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            if let error = error {
                completion(.failure(.transportError(error)))
                return
            }

            guard let http = response as? HTTPURLResponse else {
                completion(.failure(.unknown))
                return
            }

            guard let data = data, !data.isEmpty else {
                completion(.failure(.emptyResponse))
                return
            }

            // Success
            if (200...299).contains(http.statusCode), let token = Self.parseToken(from: data) {
                self.token = token
                completion(.success(()))
                return
            }

            // Parse error payloads
            if let parsed = Self.parseErrorPayload(from: data) {
                switch parsed {
                case .twoFactor(let newTicket):
                    // Discord sometimes returns a new ticket if the old one expired
                    self.twoFactorTicket = newTicket
                    completion(.failure(.twoFactorRequired(ticket: newTicket)))
                case .captcha(let svc, let key):
                    completion(.failure(.captchaRequired(service: svc, siteKey: key)))
                case .message(let msg):
                    completion(.failure(.serverMessage(msg)))
                case .parameter(let msg):
                    completion(.failure(.parameterError(message: msg)))
                }
                return
            }

            completion(.failure(.unknown))
        }.resume()
    }

    private static func cleanJSON(_ dict: [String: Any?]) -> [String: Any] {
        var cleaned: [String: Any] = [:]
        dict.forEach { k, v in cleaned[k] = v ?? NSNull() }
        return cleaned
    }

    private static func parseToken(from data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let token = json["token"] as? String else { return nil }
        return token
    }

    private enum ParsedError {
        case twoFactor(ticket: String)
        case captcha(service: String, siteKey: String)
        case message(String)
        case parameter(String)
    }

    private static func parseErrorPayload(from data: Data) -> ParsedError? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        if let ticket = json["ticket"] as? String { return .twoFactor(ticket: ticket) }
        if let svc = json["captcha_service"] as? String, let key = json["captcha_sitekey"] as? String {
            return .captcha(service: svc, siteKey: key)
        }
        if let msg = json["message"] as? String { return .message(msg) }
        if let key = json.keys.first, let arr = json[key] as? [String], let first = arr.first { return .parameter(first) }
        return nil
    }
}
