import Foundation
import TinyConstraints
import UIKit
import Quetzalcoatl

protocol MessagesTextCellDelegate: class {
    func didTapErrorView(for cell: MessagesTextCell)
}

class MessagesTextCell: UITableViewCell {
    weak var delegate: MessagesTextCellDelegate?

    var indexPath: IndexPath!

    var isOutgoingMessage: Bool = false {
        didSet {
            self.bubbleView.backgroundColor = self.isOutgoingMessage ? .outgoingBubble : .incomingBubble
            self.textView.textColor = self.isOutgoingMessage ? .defaultTextLight : .defaultTextDark
            self.textView.backgroundColor = self.bubbleView.backgroundColor
            self.avatarImageView.isHidden = self.isOutgoingMessage

            // Now mess up with some constraints to get the desired left/right align
            if self.isOutgoingMessage {
                self.bubbleViewLeft.priority = .defaultLow
                self.bubbleViewRight.priority = UILayoutPriority(999)
            } else {
                self.bubbleViewLeft.priority = UILayoutPriority(999)
                self.bubbleViewRight.priority = .defaultLow
            }
        }
    }

    var messageState: OutgoingSignalMessage.MessageState = .none {
        didSet {
            self.errorViewWidthConstraint.constant = self.messageState == .unsent ? 24.0 : 0.0
            self.errorView.alpha = self.messageState == .unsent ? 1.0 : 0.0
        }
    }

    var avatar: UIImage? {
        didSet {
            self.avatarImageView.image = self.avatar
        }
    }

    var messageBody: String = "" {
        didSet {
            self.textView.text = self.messageBody

            self.textViewHeight.isActive = self.messageBody.isEmpty
            self.textViewTopMargin.constant = self.messageBody.isEmpty ? 0 : 8
            self.textViewBottomMargin.constant = self.messageBody.isEmpty ? 0 : -8
        }
    }

    var messageImage: UIImage? {
        didSet {
            self.messageImageView.image = self.messageImage

            self.imageViewHeight.isActive = false
            self.imageViewAspectRatio.isActive = false

            if let image = self.messageImage {
                let aspectRatio: CGFloat = image.size.height / image.size.width
                self.imageViewAspectRatio = self.messageImageView.heightAnchor.constraint(equalTo: self.messageImageView.widthAnchor, multiplier: aspectRatio)
                self.imageViewAspectRatio.isActive = true

                self.imageViewHeight = self.messageImageView.heightAnchor.constraint(lessThanOrEqualTo: self.bubbleView.widthAnchor, multiplier: 1.0)
                self.imageViewHeight.isActive = true
                self.messageImageWidth.isActive = true
            } else {
                self.imageViewAspectRatio.isActive = false
                self.imageViewHeight = self.messageImageView.heightAnchor.constraint(equalToConstant: 0)
                self.imageViewHeight.isActive = true
                self.messageImageWidth.isActive = false
            }
        }
    }

    private lazy var errorViewWidthConstraint: NSLayoutConstraint = {
        return self.errorView.widthAnchor.constraint(equalToConstant: 24)
    }()

    private lazy var textViewBottomMargin: NSLayoutConstraint = {
        return self.textView.bottomAnchor.constraint(equalTo: self.bubbleView.bottomAnchor, constant: -8)
    }()

    private lazy var textViewTopMargin: NSLayoutConstraint = {
        return self.textView.topAnchor.constraint(equalTo: self.messageImageView.bottomAnchor, constant: 8)
    }()

    private lazy var imageViewAspectRatio: NSLayoutConstraint = {
        return self.messageImageView.heightAnchor.constraint(equalTo: self.messageImageView.widthAnchor, multiplier: 1.0)
    }()

    private lazy var messageImageWidth: NSLayoutConstraint = {
        return self.messageImageView.widthAnchor.constraint(equalTo: self.containerView.widthAnchor, multiplier: 0.75)
    }()

    private lazy var imageViewHeight: NSLayoutConstraint = {
        return self.messageImageView.heightAnchor.constraint(lessThanOrEqualTo: self.bubbleView.widthAnchor, multiplier: 1.0)
    }()

    private lazy var textViewHeight: NSLayoutConstraint = {
        return self.textView.heightAnchor.constraint(equalToConstant: 0)
    }()

    private lazy var bubbleViewLeft: NSLayoutConstraint = {
        let c = self.bubbleView.leftAnchor.constraint(equalTo: self.avatarImageView.rightAnchor, constant: 8)
        c.priority = UILayoutPriority(999)

        return c
    }()

    private lazy var bubbleViewRight: NSLayoutConstraint = {
        let c = self.bubbleView.rightAnchor.constraint(equalTo: self.containerView.rightAnchor, constant: -8)
        c.priority = UILayoutPriority(999)

        return c
    }()

    private lazy var messageImageView: UIImageView = {
        let view = UIImageView(withAutoLayout: true)

        return view
    }()

    private lazy var errorLabel: UILabel = {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .right

        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.red
        ]

        let boldAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 12),
            .foregroundColor: UIColor.red
        ]

        let attributedString = NSMutableAttributedString(string: "Localized.messages_sent_error", attributes: attributes)
        attributedString.addAttributes(boldAttributes, range: NSRange(location: 0, length: 13))

        let view = UILabel(withAutoLayout: true)
        view.alpha = 0
        view.attributedText = attributedString
        view.adjustsFontForContentSizeCategory = true
        view.numberOfLines = 1

        return view
    }()

    private lazy var textView: UITextView = {
        let view = UITextView(withAutoLayout: true)
        view.font = .systemFont(ofSize: 15)
        view.adjustsFontForContentSizeCategory = true
        view.dataDetectorTypes = [.link]
        view.isUserInteractionEnabled = true
        view.isScrollEnabled = false
        view.isEditable = false
        view.contentMode = .topLeft
        view.textContainer.lineBreakMode = .byWordWrapping
        view.textContainerInset = .zero
        view.textContainer.lineFragmentPadding = 0
        view.textContainer.maximumNumberOfLines = 0

        view.linkTextAttributes = [NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single]

        view.setContentHuggingPriority(UILayoutPriority(999), for: .vertical)
        view.setContentHuggingPriority(UILayoutPriority(999), for: .horizontal)

        return view
    }()

    private lazy var bubbleView: UIView = {
        let view = UIView(withAutoLayout: true)
        view.layer.cornerRadius = 8
        view.clipsToBounds = true

        view.setContentHuggingPriority(.required, for: .vertical)
        view.setContentHuggingPriority(.required, for: .horizontal)

        return view
    }()

    private lazy var containerView: UIView = {
        let view = UIView(withAutoLayout: true)

        return view
    }()

    private lazy var avatarImageView: UIImageView = {
        let view = UIImageView(withAutoLayout: true)
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.layer.cornerRadius = 22
        view.isUserInteractionEnabled = true
        view.layer.borderColor = UIColor.gray.cgColor
        view.layer.borderWidth = 1.0 / UIScreen.main.scale

        return view
    }()

    private lazy var errorView: MessagesErrorView = {
        let view = MessagesErrorView(withAutoLayout: true)
        view.addTarget(self, action: #selector(self.didTapErrorView), for: .touchUpInside)

        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.backgroundColor = nil
        self.selectionStyle = .none
        self.contentView.autoresizingMask = [.flexibleHeight]

        self.contentView.addSubview(self.containerView)
        self.containerView.addSubview(self.bubbleView)
        self.containerView.addSubview(self.avatarImageView)
        self.containerView.addSubview(self.errorView)

        self.bubbleView.addSubview(self.messageImageView)
        self.bubbleView.addSubview(self.textView)

        let imageHeight = self.avatarImageView.heightAnchor.constraint(equalToConstant: 44)
        imageHeight.priority = UILayoutPriority(999)
        imageHeight.isActive = true
        self.avatarImageView.set(width: 44)

        self.containerView.leftToSuperview()
        self.containerView.topToSuperview()
        self.containerView.bottomToSuperview()
        self.containerView.rightToSuperview()

        self.avatarImageView.topAnchor.constraint(greaterThanOrEqualTo: self.containerView.topAnchor, constant: 8).isActive = true
        self.avatarImageView.bottomAnchor.constraint(equalTo: self.containerView.bottomAnchor, constant: -8).isActive = true
        self.avatarImageView.leftAnchor.constraint(equalTo: self.containerView.leftAnchor, constant: 8).isActive = true

        self.errorView.set(height: 24)
        self.errorViewWidthConstraint.isActive = true
        self.errorView.rightAnchor.constraint(equalTo: self.containerView.rightAnchor, constant: -8).isActive = true
        self.errorView.bottomAnchor.constraint(equalTo: self.containerView.bottomAnchor, constant: -12).isActive = true

        self.bubbleViewLeft.isActive = true
        self.bubbleViewRight.isActive = true
        self.bubbleView.topAnchor.constraint(greaterThanOrEqualTo: self.containerView.topAnchor, constant: 8).isActive = true
        self.bubbleView.bottomAnchor.constraint(equalTo: self.containerView.bottomAnchor, constant: -8).isActive = true

        self.messageImageView.topAnchor.constraint(equalTo: self.bubbleView.topAnchor, constant: 0).isActive = true
        self.messageImageWidth.isActive = true

        var constraints = NSLayoutConstraint.constraints(withVisualFormat: "|[image]|", options: [], metrics: [:], views: ["image" : self.messageImageView])
        constraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "|-[text]-|", options: [], metrics: [:], views: ["text": self.textView]))
        constraints.append(contentsOf: [self.textViewHeight, self.imageViewAspectRatio, self.imageViewHeight, self.textViewBottomMargin, self.textViewTopMargin])

        NSLayoutConstraint.activate(constraints)

        self.textViewHeight.constant = 0
        self.textView.textContainerInset = .zero
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func didTapErrorView() {
        self.delegate?.didTapErrorView(for: self)
    }
}

final class MessagesErrorView: UIControl {
    private lazy var imageView: UIImageView = {
        let view = UIImageView(withAutoLayout: true)
        view.image = UIImage(named: "error")!
        view.contentMode = .scaleAspectFit

        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.addSubview(self.imageView)

        self.imageView.set(height: 24)
        self.imageView.set(width: 24)
        self.imageView.centerXAnchor.constraint(equalTo: self.centerXAnchor, constant: 0).isActive = true
        self.imageView.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: 0).isActive = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
