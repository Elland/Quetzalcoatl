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
        }
    }

    var messageState: OutgoingSignalMessage.MessageState = .none

    var avatar: UIImage? {
        didSet {
            self.avatarImageView.image = self.avatar
        }
    }

    var messageBody: String {
        set {
            self.textView.text = newValue
        }
        get {
            return self.textView.text
        }
    }

    var messageImage: UIImage? {
        set {
            self.messageImageView.image = newValue
        }
        get {
            return self.messageImageView.image
        }
    }

    private lazy var messageImageView: UIImageView = {
        return UIImageView(withAutoLayout: false)
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

        let view = UILabel(withAutoLayout: false)
        view.alpha = 0
        view.attributedText = attributedString
        view.adjustsFontForContentSizeCategory = true
        view.numberOfLines = 1

        return view
    }()

    private lazy var textView: UITextView = {
        let view = UITextView(withAutoLayout: false)
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
        view.tintColor = .white

//        view.setContentHuggingPriority(UILayoutPriority(999), for: .vertical)
//        view.setContentHuggingPriority(UILayoutPriority(999), for: .horizontal)
//        view.setContentCompressionResistancePriority(.fittingSizeLevel, for: .horizontal)

        return view
    }()

    private lazy var bubbleView: UIView = {
        let view = UIView(withAutoLayout: false)
        view.layer.cornerRadius = 8
        view.clipsToBounds = true

        view.setContentHuggingPriority(.required, for: .vertical)
        view.setContentHuggingPriority(.required, for: .horizontal)

        return view
    }()

    private lazy var avatarImageView: UIImageView = {
        let view = UIImageView(withAutoLayout: false)
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.layer.cornerRadius = 22
        view.isUserInteractionEnabled = true
        view.layer.borderColor = UIColor.gray.cgColor
        view.layer.borderWidth = 1.0 / UIScreen.main.scale

        return view
    }()

    private lazy var errorView: MessagesErrorView = {
        let view = MessagesErrorView(withAutoLayout: false)
        view.addTarget(self, action: #selector(self.didTapErrorView), for: .touchUpInside)

        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.backgroundColor = nil
        self.selectionStyle = .none
        self.contentView.autoresizingMask = [.flexibleHeight]

        self.contentView.addSubview(self.bubbleView)
        self.contentView.addSubview(self.avatarImageView)
        self.contentView.addSubview(self.errorView)

        self.bubbleView.addSubview(self.messageImageView)
        self.bubbleView.addSubview(self.textView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func didTapErrorView() {
        self.delegate?.didTapErrorView(for: self)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let margin: CGFloat = 8

        self.avatarImageView.isHidden = self.isOutgoingMessage
        self.avatarImageView.bounds = CGRect(x: margin, y: 0, width: 44, height: 44)

        if self.messageState == .unsent {
            self.errorView.frame = CGRect(x: UIScreen.main.bounds.width - 30, y: 0, width: 30, height: 30)
        } else {
            self.errorView.frame = .zero
        }

        /* |-[avatar]-[bubbled-left]-[text]-[bubbled-right]-[error]-| */
        let origin = self.avatarImageView.bounds.width + (margin * 3)
        let width = (UIScreen.main.bounds.width - margin) - origin - self.errorView.bounds.width
        let maxSize = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingTextRect = self.textView.attributedText.boundingRect(with: maxSize, options: [.usesLineFragmentOrigin], context: nil).integral

        self.textView.frame = CGRect(origin: CGPoint(x: margin, y: margin), size: boundingTextRect.size)

        self.bubbleView.bounds = self.textView.frame.inset(by: UIEdgeInsets(top: -margin, left: -margin, bottom: -margin, right: -margin))

        let cellHeight = ceil(max(self.bubbleView.bounds.height, self.avatarImageView.bounds.height) + (margin * 2))
        let cellWidth = ceil(self.superview?.bounds.width ?? UIScreen.main.bounds.width)

        self.avatarImageView.frame.origin = CGPoint(x: margin, y: cellHeight - (self.avatarImageView.bounds.height + margin))

        let bubbleOrigin = self.isOutgoingMessage ? cellWidth - self.bubbleView.bounds.width - margin - self.errorView.bounds.width : origin
        self.bubbleView.frame.origin = CGPoint(x: bubbleOrigin, y: cellHeight - (self.bubbleView.bounds.height + margin))

        self.contentView.frame = CGRect(x: 0, y: 0, width: cellWidth, height: cellHeight)
        self.bounds = self.contentView.bounds
    }
}
