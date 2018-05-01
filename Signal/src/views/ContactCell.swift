//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

import UIKit
import Contacts
import SignalServiceKit

class ContactCell: UITableViewCell {

    public static let kSeparatorHInset: CGFloat = CGFloat(kAvatarDiameter) + 16 + 8

    static let kAvatarSpacing: CGFloat = 6
    static let kAvatarDiameter: UInt = 40

    let contactImageView: AvatarImageView
    let textStackView: UIStackView
    let titleLabel: UILabel
    var subtitleLabel: UILabel

    var contact: Contact?

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        self.contactImageView = AvatarImageView()
        self.textStackView = UIStackView()
        self.titleLabel = UILabel()
        self.titleLabel.font = UIFont.ows_dynamicTypeBody
        self.subtitleLabel = UILabel()
        self.subtitleLabel.font = UIFont.ows_dynamicTypeSubheadline

        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = UITableViewCellSelectionStyle.none

        textStackView.axis = .vertical
        textStackView.addArrangedSubview(titleLabel)

        contactImageView.autoSetDimensions(to: CGSize(width: CGFloat(ContactCell.kAvatarDiameter), height: CGFloat(ContactCell.kAvatarDiameter)))

        let contentColumns: UIStackView = UIStackView(arrangedSubviews: [contactImageView, textStackView])
        contentColumns.axis = .horizontal
        contentColumns.spacing = ContactCell.kAvatarSpacing
        contentColumns.alignment = .center

        self.contentView.addSubview(contentColumns)
        contentColumns.autoPinEdgesToSuperviewMargins()

        NotificationCenter.default.addObserver(self, selector: #selector(self.didChangePreferredContentSize), name: NSNotification.Name.UIContentSizeCategoryDidChange, object: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        accessoryType = .none
        self.subtitleLabel.removeFromSuperview()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        accessoryType = selected ? .checkmark : .none
    }

    func didChangePreferredContentSize() {
        self.titleLabel.font = UIFont.ows_dynamicTypeBody
        self.subtitleLabel.font = UIFont.ows_dynamicTypeSubheadline
    }

    func configure(contact: Contact, subtitleType: SubtitleCellValue, contactsManager: OWSContactsManager) {
        self.contact = contact

        titleLabel.attributedText = contact.cnContact?.formattedFullName(font: titleLabel.font)
        updateSubtitle(subtitleType: subtitleType, contact: contact)

        if let contactImage = contact.image {
            contactImageView.image = contactImage
        } else {
            let contactIdForDeterminingBackgroundColor: String
            if let signalId = contact.parsedPhoneNumbers.first?.toE164() {
                contactIdForDeterminingBackgroundColor = signalId
            } else {
                contactIdForDeterminingBackgroundColor = contact.fullName
            }

            let avatarBuilder = OWSContactAvatarBuilder(nonSignalName: contact.fullName,
                                                        colorSeed: contactIdForDeterminingBackgroundColor,
                                                        diameter: ContactCell.kAvatarDiameter,
                                                        contactsManager: contactsManager)

            contactImageView.image = avatarBuilder.buildDefaultImage()
        }
    }

    func updateSubtitle(subtitleType: SubtitleCellValue, contact: Contact) {
        switch subtitleType {
        case .none:
            assert(self.subtitleLabel.superview == nil)
            break
        case .phoneNumber:
            self.textStackView.addArrangedSubview(self.subtitleLabel)

            if let firstPhoneNumber = contact.userTextPhoneNumbers.first {
                self.subtitleLabel.text = firstPhoneNumber
            } else {
                self.subtitleLabel.text = NSLocalizedString("CONTACT_PICKER_NO_PHONE_NUMBERS_AVAILABLE", comment: "table cell subtitle when contact card has no known phone number")
            }
        case .email:
            self.textStackView.addArrangedSubview(self.subtitleLabel)

            if let firstEmail = contact.emails.first {
                self.subtitleLabel.text = firstEmail
            } else {
                self.subtitleLabel.text = NSLocalizedString("CONTACT_PICKER_NO_EMAILS_AVAILABLE", comment: "table cell subtitle when contact card has no email")
            }
        }
    }
}

fileprivate extension CNContact {
    /**
     * Bold the sorting portion of the name. e.g. if we sort by family name, bold the family name.
     */
    func formattedFullName(font: UIFont) -> NSAttributedString? {
        let keyToHighlight = ContactSortOrder == .familyName ? CNContactFamilyNameKey : CNContactGivenNameKey

        let boldDescriptor = font.fontDescriptor.withSymbolicTraits(.traitBold)
        let boldAttributes = [
            NSFontAttributeName: UIFont(descriptor: boldDescriptor!, size: 0)
        ]

        if let attributedName = CNContactFormatter.attributedString(from: self, style: .fullName, defaultAttributes: nil) {
            let highlightedName = attributedName.mutableCopy() as! NSMutableAttributedString
            highlightedName.enumerateAttributes(in: NSMakeRange(0, highlightedName.length), options: [], using: { (attrs, range, _) in
                if let property = attrs[CNContactPropertyAttribute] as? String, property == keyToHighlight {
                    highlightedName.addAttributes(boldAttributes, range: range)
                }
            })
            return highlightedName
        }

        if let emailAddress = (self.emailAddresses.first?.value as String?) {
            return NSAttributedString(string: emailAddress, attributes: boldAttributes)
        }

        return nil
    }
}
