import UIKit
import UIKitCompatKit

class AuthenticationViewController: UIViewController {

    // MARK: - UI Elements
    let tokenToggle = UISwitch()
    let tokenLabel = UILabel()
    let tokenField = UITextField()

    let emailField = UITextField()
    let passwordField = UITextField()
    let twoFactorField = UITextField()
    let statusLabel = UILabel()
    let loginButton = UIButton(type: .system)
    let submit2FAButton = UIButton(type: .system)

    let loginManager = LoginManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupUI()
        setupConstraints()
    }

    // MARK: - Setup UI
    func setupUI() {
        // Token toggle
        tokenLabel.text = "Use Token"
        tokenLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tokenLabel)

        tokenToggle.isOn = false
        tokenToggle.addTarget(self, action: #selector(toggleTokenMode), for: .valueChanged)
        tokenToggle.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tokenToggle)

        // Token field
        tokenField.placeholder = "Token"
        tokenField.borderStyle = .roundedRect
        tokenField.autocapitalizationType = .none
        tokenField.translatesAutoresizingMaskIntoConstraints = false
        tokenField.isHidden = true
        view.addSubview(tokenField)

        // Email
        emailField.placeholder = "Email"
        emailField.borderStyle = .roundedRect
        emailField.autocapitalizationType = .none
        emailField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emailField)

        // Password
        passwordField.placeholder = "Password"
        passwordField.borderStyle = .roundedRect
        passwordField.isSecureTextEntry = true
        passwordField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(passwordField)

        // 2FA
        twoFactorField.placeholder = "2FA Code"
        twoFactorField.borderStyle = .roundedRect
        twoFactorField.keyboardType = .numberPad
        twoFactorField.translatesAutoresizingMaskIntoConstraints = false
        twoFactorField.isHidden = true
        view.addSubview(twoFactorField)

        // Status
        statusLabel.textColor = .red
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)

        // Buttons
        loginButton.setTitle("Login", for: .normal)
        loginButton.addTarget(self, action: #selector(didTapLogin), for: .touchUpInside)
        loginButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loginButton)

        submit2FAButton.setTitle("Submit 2FA", for: .normal)
        submit2FAButton.isHidden = true
        submit2FAButton.addTarget(self, action: #selector(didTapSubmit2FA), for: .touchUpInside)
        submit2FAButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(submit2FAButton)
    }

    // MARK: - Setup Constraints
    func setupConstraints() {
        let widthMultiplier: CGFloat = 0.7

        // Token Label
        if #available(iOS 11.0, *) {
            let guide: UIKit.UILayoutGuide = view.safeAreaLayoutGuide
            view.addConstraints([
                .init(item: tokenLabel, attribute: .top, relatedBy: .equal, toItem: guide, attribute: .top, multiplier: 1, constant: 30),
                .init(item: tokenLabel, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1, constant: -40)
            ])
        } else {
            tokenLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: -40).isActive = true
            tokenLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 30).isActive = true
        }

        // Token Toggle
        tokenToggle.centerYAnchor.constraint(equalTo: tokenLabel.centerYAnchor).isActive = true
        tokenToggle.leftAnchor.constraint(equalTo: tokenLabel.rightAnchor, constant: 10).isActive = true

        // Token Field
        tokenField.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        tokenField.topAnchor.constraint(equalTo: tokenLabel.bottomAnchor, constant: 20).isActive = true
        tokenField.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: widthMultiplier).isActive = true
        tokenField.heightAnchor.constraint(equalToConstant: 40).isActive = true

        // Email
        emailField.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        emailField.topAnchor.constraint(equalTo: tokenLabel.bottomAnchor, constant: 20).isActive = true
        emailField.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: widthMultiplier).isActive = true
        emailField.heightAnchor.constraint(equalToConstant: 40).isActive = true

        // Password
        passwordField.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        passwordField.topAnchor.constraint(equalTo: emailField.bottomAnchor, constant: 20).isActive = true
        passwordField.widthAnchor.constraint(equalTo: emailField.widthAnchor).isActive = true
        passwordField.heightAnchor.constraint(equalToConstant: 40).isActive = true

        // Login Button
        loginButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        loginButton.topAnchor.constraint(equalTo: passwordField.bottomAnchor, constant: 20).isActive = true
        loginButton.widthAnchor.constraint(equalTo: emailField.widthAnchor).isActive = true
        loginButton.heightAnchor.constraint(equalToConstant: 40).isActive = true

        // 2FA Field
        twoFactorField.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        twoFactorField.topAnchor.constraint(equalTo: view.topAnchor, constant: 100).isActive = true
        twoFactorField.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: widthMultiplier).isActive = true
        twoFactorField.heightAnchor.constraint(equalToConstant: 40).isActive = true

        // Submit 2FA Button
        submit2FAButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        submit2FAButton.topAnchor.constraint(equalTo: twoFactorField.bottomAnchor, constant: 20).isActive = true
        submit2FAButton.widthAnchor.constraint(equalTo: twoFactorField.widthAnchor).isActive = true
        submit2FAButton.heightAnchor.constraint(equalToConstant: 40).isActive = true

        // Status Label
        statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        statusLabel.topAnchor.constraint(equalTo: submit2FAButton.bottomAnchor, constant: 20).isActive = true
        statusLabel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: widthMultiplier).isActive = true
    }

    // MARK: - Actions

    @objc func toggleTokenMode() {
        let useToken = tokenToggle.isOn
        tokenField.isHidden = !useToken
        emailField.isHidden = useToken
        passwordField.isHidden = useToken
    }

    @objc func didTapLogin() {
        if tokenToggle.isOn {
            // Directly set token
            let token1 = tokenField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if token1.isEmpty {
                statusLabel.text = "Enter a token."
                return
            }
            loginManager.token = token1
            proceedToMainApp()
            token = token1
            return
        }

        // Normal email/password login
        let email = emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let password = passwordField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if email.isEmpty || password.isEmpty {
            statusLabel.text = "Enter email and password."
            return
        }

        statusLabel.text = "Logging in..."
        loginManager.login(email: email, password: password) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }

                switch result {
                case .success:
                    self.proceedToMainApp()
                case .failure(let error):
                    switch error {
                    case .twoFactorRequired:
                        self.showTwoFactorUI()
                    default:
                        self.statusLabel.text = "Login failed: \(error.localizedDescription)"
                    }
                }
            }
        }
    }

    @objc func didTapSubmit2FA() {
        let code = twoFactorField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if code.isEmpty {
            statusLabel.text = "Enter 2FA code."
            return
        }

        statusLabel.text = "Verifying 2FA..."
        loginManager.loginTwoFactor(code: code) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }

                switch result {
                case .success:
                    self.proceedToMainApp()
                case .failure(let error):
                    self.statusLabel.text = "2FA failed: \(error.localizedDescription)"
                }
            }
        }
    }

    // MARK: - Helpers

    private func showTwoFactorUI() {
        // Hide login UI
        emailField.isHidden = true
        passwordField.isHidden = true
        loginButton.isHidden = true
        tokenToggle.isHidden = true
        tokenLabel.isHidden = true
        tokenField.isHidden = true

        // Show 2FA UI
        twoFactorField.isHidden = false
        submit2FAButton.isHidden = false

        statusLabel.text = "Two-factor authentication required."
    }

    private func proceedToMainApp() {
        statusLabel.text = "Login successful!"
        let startVC = ViewController()
        let navController = LoadingViewController()
        UIApplication.shared.keyWindow?.rootViewController = navController
    }
}
