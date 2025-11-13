import Foundation
import UIKit
import FoundationCompatKit


//MARK: MOST OF THIS CHATGPT COOKED UP FROM DISCORDLITE, WHILE I DO UNDERSTAND IT, IT'S VERY DELICATE. Please note, the base 64 user agent must be the same as mine if you want 2fa support.
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
        request.setValue(self.superPropertiesBase64(), forHTTPHeaderField: "X-Super-Properties")
        request.setValue("Discord-iOS-Client (Swiftcord, 1.0)", forHTTPHeaderField: "User-Agent")

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
                request.setValue(self.superPropertiesBase64(), forHTTPHeaderField: "X-Super-Properties")
                request.setValue(fp, forHTTPHeaderField: "X-Fingerprint")
                request.setValue("Discord-iOS-Client (Swiftcord, 1.0)", forHTTPHeaderField: "User-Agent") // ADDED
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
                        print(try! JSONSerialization.jsonObject(with: data))
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
        request.setValue(superPropertiesBase64(), forHTTPHeaderField: "X-Super-Properties")
        request.setValue(fp, forHTTPHeaderField: "X-Fingerprint")
        request.setValue("Discord-iOS-Client (Swiftcord, 1.0)", forHTTPHeaderField: "User-Agent") // ADDED
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
                print(try! JSONSerialization.jsonObject(with: data))
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



    private func superPropertiesBase64() -> String {
        // Replicate the Objective-C's superPropertiesDict structure as closely as possible
        let props: [String: Any?] = [
            "os": "iOS", // Obj-C uses "Mac OS X", but your Swift is for iOS. Keep "iOS" if truly an iOS app. If you're building a Mac app, change to "Mac OS X". This is a key decision.
            "browser": "Discord Client", // Match Obj-C's 'browser' field value
            "release_channel": "stable",
            "client_version": "0.0.326", // Match Obj-C's client_version
            "os_version": "15.5", // Keep your iOS version for now, or use a more specific kernel version if you can obtain it consistently for iOS. For a Mac app, you'd need the equivalent of [DLUtil kernelVersion].
            "os_arch": "arm64", // Obj-C uses "x64", but your iOS device is arm64. Keep "arm64".
            "app_arch": "arm64", // ADDED: Match Obj-C's 'app_arch', change from x64 to arm64 for iOS
            "system_locale": "en-US",
            "browser_user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) discord/0.0.326 Chrome/128.0.6613.186 Electron/32.2.2 Safari/537.36", // ADDED: Exact string from Obj-C's userAgentString
            "browser_version": "32.2.2", // ADDED: Match Obj-C's 'browser_version'
            "os_sdk_version": "23", // ADDED: Match Obj-C's 'os_sdk_version'
            "client_build_number": 209354, // Match Obj-C's client_build_number
            "native_build_number": NSNull(), // ADDED: Match Obj-C's NSNull
            "client_event_source": NSNull() // ADDED: Match Obj-C's NSNull
        ]
        let data = try! JSONSerialization.data(withJSONObject: Self.cleanJSON(props)) // Use cleanJSON to handle NSNull
        return base64Encode(data: data)
    }
    
    private func base64Encode(data: Data) -> String {
        let base64Chars = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/")
        var result = ""
        let bytes = [UInt8](data)
        var i = 0

        while i < bytes.count {
            let byte0 = bytes[i]
            let byte1 = i + 1 < bytes.count ? bytes[i + 1] : 0
            let byte2 = i + 2 < bytes.count ? bytes[i + 2] : 0

            let index0 = byte0 >> 2
            let index1 = ((byte0 & 0x03) << 4) | (byte1 >> 4)
            let index2 = ((byte1 & 0x0F) << 2) | (byte2 >> 6)
            let index3 = byte2 & 0x3F

            result.append(base64Chars[Int(index0)])
            result.append(base64Chars[Int(index1)])

            if i + 1 < bytes.count {
                result.append(base64Chars[Int(index2)])
            } else {
                result.append("=")
            }

            if i + 2 < bytes.count {
                result.append(base64Chars[Int(index3)])
            } else {
                result.append("=")
            }

            i += 3
        }

        return result
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
