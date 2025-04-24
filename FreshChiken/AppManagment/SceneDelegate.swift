

import UIKit
import SwiftUI
import WebKit

final class PrivacyPolicyViewController: UIViewController, WKNavigationDelegate, WKUIDelegate {
    
    // MARK: - Properties
    
    private var webView: WKWebView!
    private let urlString: String
    
    // MARK: - Initialization
    
    init(url: String) {
        self.urlString = url
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupWebView()
        loadURL()
        setupSecureWindow()
        Orientation.orientation = .all
    }
    
    // MARK: - Setup Methods
    
    private func setupView() {
        view.backgroundColor = .black
        addBackgroundViews()
    }
    
    private func addBackgroundViews() {
        let topBackgroundView = UIView()
        topBackgroundView.backgroundColor = UIColor(named: "bgFill")
        topBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(topBackgroundView)
        
        let bottomBackgroundView = UIView()
        bottomBackgroundView.backgroundColor = UIColor(named: "bgFill")
        bottomBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomBackgroundView)
        
        NSLayoutConstraint.activate([
            topBackgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topBackgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topBackgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            topBackgroundView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            
            bottomBackgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBackgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomBackgroundView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            bottomBackgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupWebView() {
        webView = createWebView(frame: view.bounds)
        view.addSubview(webView)
        setupWebViewConstraints()
    }
    
    private func createWebView(frame: CGRect) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.applicationNameForUserAgent = "MyApp/1.0"
        
        let webView = WKWebView(frame: frame, configuration: configuration)
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Mobile/15E148 Safari/604.1"
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.scrollView.showsHorizontalScrollIndicator = false
        webView.allowsLinkPreview = false
        webView.scrollView.bounces = false
        webView.scrollView.minimumZoomScale = 1.0
        webView.scrollView.maximumZoomScale = 1.0
        webView.allowsBackForwardNavigationGestures = true
        webView.translatesAutoresizingMaskIntoConstraints = false
        return webView
    }
    
    private func setupWebViewConstraints() {
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    private func loadURL() {
        guard let url = URL(string: urlString) else { return }
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    private func setupSecureWindow() {
        DispatchQueue.main.async {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first else { return }
            
            let secureField = UITextField()
            secureField.isSecureTextEntry = true
            window.addSubview(secureField)
            window.layer.superlayer?.addSublayer(secureField.layer)
            secureField.layer.sublayers?.last?.addSublayer(window.layer)
        }
    }
    
    // MARK: - WKNavigationDelegate
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard navigationAction.targetFrame == nil || !navigationAction.targetFrame!.isMainFrame else { return nil }
        
        let containerView = createContainerView()
        let targetWebView = createWebView(frame: containerView.safeAreaLayoutGuide.layoutFrame)
        targetWebView.load(navigationAction.request)
        containerView.addSubview(targetWebView)
        addCloseButton(to: containerView)
        
        UIView.animate(withDuration: 0.2) {
            containerView.alpha = 1.0
        }
        
        return targetWebView
    }
    
    private func createContainerView() -> UIView {
        let containerView = UIView(frame: view.frame)
        containerView.backgroundColor = .black
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.topAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        return containerView
    }
    
    private func addCloseButton(to containerView: UIView) {
        let closeButton = UIButton(type: .system)
        closeButton.tintColor = .white
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(closeButton)
        
        NSLayoutConstraint.activate([
            closeButton.trailingAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.trailingAnchor, constant: -15),
            closeButton.centerYAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.topAnchor, constant: 22)
        ])
    }
    
    @objc private func closeButtonTapped(_ sender: UIButton) {
        if let containerView = sender.superview {
            UIView.animate(withDuration: 0.2) {
                containerView.alpha = 0.0
            } completion: { _ in
                containerView.removeFromSuperview()
            }
        }
    }
    
    func webViewDidClose(_ webView: WKWebView) {
        if let containerView = webView.superview {
            UIView.animate(withDuration: 0.2) {
                containerView.alpha = 0.0
            } completion: { _ in
                containerView.removeFromSuperview()
            }
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }
        
        if !["http", "https"].contains(url.scheme) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            decisionHandler(.cancel)
            return
        }
        
        decisionHandler(.allow)
    }
}

// MARK: - Orientation Handling

private extension String {
    var deviceOrientation: UIInterfaceOrientationMask {
        switch self {
        case "UIInterfaceOrientationPortrait":
            return .portrait
        case "UIInterfaceOrientationLandscapeLeft":
            return .landscapeLeft
        case "UIInterfaceOrientationLandscapeRight":
            return .landscapeRight
        case "UIInterfaceOrientationPortraitUpsideDown":
            return .portraitUpsideDown
        default:
            return .all
        }
    }
}

final class Orientation {
    static var orientation: UIInterfaceOrientationMask = preferredOrientation
    
    private static var preferredOrientation: UIInterfaceOrientationMask {
        guard let maskStringsArray = Bundle.main.object(forInfoDictionaryKey: "UISupportedInterfaceOrientations") as? [String] else {
            return .all
        }
        return UIInterfaceOrientationMask(maskStringsArray.compactMap { $0.deviceOrientation })
    }
}

struct PrivacyPolicyWrapper: UIViewControllerRepresentable {
    
    var privacyURL: String
    
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = PrivacyPolicyViewController(url: privacyURL)
        viewController.view.backgroundColor = .black
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        
    }
}

