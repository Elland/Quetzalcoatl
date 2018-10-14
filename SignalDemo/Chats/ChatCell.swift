//
//  Cells.swift
//  Demo
//
//  Created by Igor Ranieri on 17.04.18.
//

import UIKit

class ChatCell: UITableViewCell {
    var date: String = "" {
        didSet {
            self.dateLabel.text = date
        }
    }

    var title: String? {
        didSet {
            self.titleLabel.text = self.title
        }
    }

    var unreadCount: Int = 0 {
        didSet {
            if self.unreadCount == 0 {
                self.badgeLabel.text = nil
                self.badgeLabel.isHidden = true
            } else {
                self.badgeLabel.text = String(self.unreadCount)
                self.badgeLabel.isHidden = false
            }
        }
    }

    var avatarImage: UIImage? {
        didSet {
            self.avatarImageView.image = self.avatarImage
        }
    }

    private lazy var containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.clipsToBounds = true
        view.layer.cornerRadius = 16

        return view
    }()

    private lazy var badgeLabel: UILabel = {
        let view = InsetLabel()

        view.insets = UIEdgeInsets(top: 10, left: 8, bottom: 6, right: 8)
        view.font = .boldFont(size: 15)
        view.textColor = .white
        view.textAlignment = .center
        view.backgroundColor = .tint
        view.layer.cornerRadius = 12
        view.clipsToBounds = true

        view.setContentCompressionResistancePriority(.required, for: .vertical)
        view.setContentCompressionResistancePriority(.required, for: .horizontal)
        view.setContentHuggingPriority(.required, for: .vertical)
        view.setContentHuggingPriority(.required, for: .horizontal)

        return view
    }()

    private lazy var avatarImageView: UIImageView = {
        let view = UIImageView(image: nil)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.contentMode = .scaleAspectFit

        view.layer.masksToBounds = true
        view.layer.borderColor = UIColor.gray.cgColor
        view.layer.borderWidth = 1.0
        view.layer.cornerRadius = 22

        return view
    }()

    private lazy var dateLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 12)
        label.textAlignment = .right
        label.textColor = .lighterText

        label.setContentHuggingPriority(.required, for: .vertical)

        return label
    }()

    fileprivate lazy var titleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.adjustsFontSizeToFitWidth = true

        return label
    }()

    lazy var separatorView: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = .lightGray

        return view
    }()

    override func setSelected(_ selected: Bool, animated: Bool) { }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) { }

    func setup() {
        self.contentView.addSubview(self.containerView)
        self.contentView.addSubview(self.separatorView)

        self.containerView.addSubview(self.avatarImageView)
        self.containerView.addSubview(self.titleLabel)
        self.containerView.addSubview(self.dateLabel)
        self.containerView.addSubview(self.badgeLabel)

        self.containerView.edgesToSuperview()

        self.avatarImageView.set(width: 44)
        self.avatarImageView.set(height: 44)

        self.badgeLabel.width(min: 24, max: 120)
        self.badgeLabel.set(height: 24)

        self.separatorView.set(height: .lineHeight)

        self.avatarImageView.leftToSuperview(offset: 12)
        self.avatarImageView.topToSuperview(offset: 12)
        self.avatarImageView.bottomToTop(of: self.separatorView, offset: -12)

        self.titleLabel.rightToLeft(of: self.badgeLabel, offset: -12)
        self.titleLabel.leftToRight(of: self.avatarImageView, offset: 12)
        self.titleLabel.topToSuperview(offset: 12)
        self.titleLabel.bottomToTop(of: self.dateLabel)

        self.dateLabel.left(to: self.titleLabel)
        self.dateLabel.right(to: self.titleLabel)
        self.dateLabel.bottomToTop(of: self.separatorView, offset: -12)

        self.badgeLabel.rightToSuperview(offset: -12)
        self.badgeLabel.centerY(to: self.containerView)

        self.separatorView.leftToSuperview()
        self.separatorView.rightToSuperview()
        self.separatorView.bottomToSuperview()
    }

    init() {
        super.init(style: .default, reuseIdentifier: nil)

        self.setup()
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        self.setup()
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        self.avatarImage = nil
        self.title = nil
        self.date = ""
        self.unreadCount = 0
    }
}
