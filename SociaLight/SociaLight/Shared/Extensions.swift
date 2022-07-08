//
//  Extensions.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 25.04.22.
//

import UIKit

extension UIViewController {
    
    func handleError(error: String?) {
        showWarningAlert(warningText: error ?? Constants.unspecifiedErrorText)
    }

    func showWarningAlert(warningText: String) {
        let alert = UIAlertController(
            title: "Warning",
            message: warningText,
            preferredStyle: .alert
        )
        alert.addAction(
            UIAlertAction(
                title: "Ok",
                style: .default,
                handler: nil
            )
        )
        present(alert, animated: true, completion: nil)
    }
    
    func checkIfPasswordsMatches(pass1: String, pass2: String) -> Bool {
        if (pass1 == pass2) {
            return true
        } else {
            showWarningAlert(warningText: "Passwords doesn’t match!")
            return false
        }
    }
    
    func checkPasswordLength(password: String) -> Bool {
        if password.count < 6 {
            showWarningAlert(warningText: "Password should be at least 6 characters long!")
            return false
        }
        return true
    }
    
    func formatDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM dd yyyy"
        return formatter.string(from: date)
    }
    
    struct Constants {
        // Keys
        static let userIdKey: String = "userId"
        
        // Warning textst
        static let fieldsAreNotFilledWarningText: String = "Please fill all the fields!"
        static let samePasswordsWarningText: String = "Can't use same password!"
        static let noChangesdWarningText: String = "Nothing to change!"
        static let membersCountNotChosenWarningText: String = "Please choose members count!"
        static let maximalGroupMembersNumberReachedWarningText: String = "Can't add new Member to the Group. Maximal number of members is reached!"
        
        // Error Texts
        static let unspecifiedErrorText: String = "Unspecified Error"
        static let getUserInfoErrorText: String = "Can't get user Info"
        static let getUserGroupsErrorText: String = "Can't get user Groups"
        static let getUserFriendsErrorText: String = "Can't get user Friends"
        static let searchGroupsErrorText: String = "Can't serch new Groups"
        static let uploadUserImageErrorText: String = "Can't upload user Image"
        static let changePasswordErrorText: String = "Can't change Password"
        static let saveChangesErrorText: String = "Can't save Changes"
        static let createGroupErrorText: String = "Can't create Group"
        
        // Picker Data
        static let pickerData: [Int] = [2, 3, 4, 5, 10, 20, 25, 50]
        
        // Table&Collection View Parameters
        static let itemCountInLine: CGFloat = 3
        static let spacing: CGFloat = 10.0
        static let lineSpacing: CGFloat = 20.0
        static let topBottomSpacing: CGFloat = 20.0
        static let additionalSpacing: CGFloat = 20.0
        static let tableRowHeight = 80.0
        static let tableViewOffset = 32.0
        static let itemCount: CGFloat = 4
        
        // Get image variables
        static let getImageURLPrefix: String = "http://localhost:9000/getImage?imageKey="
        static let userImagePrefix: String = "userImage"
        static let groupImagePrefix: String = "groupImage"
    }
    
}

extension UIColor {
    
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(netHex:Int) {
        self.init(red:(netHex >> 16) & 0xff, green:(netHex >> 8) & 0xff, blue:netHex & 0xff)
    }
    
    struct FlatColor {
        
        struct Green {
            static let Fern = UIColor(netHex: 0x6ABB72)
            static let MountainMeadow = UIColor(netHex: 0x3ABB9D)
            static let ChateauGreen = UIColor(netHex: 0x4DA664)
            static let PersianGreen = UIColor(netHex: 0x2CA786)
        }
        
        struct Blue {
            static let PictonBlue = UIColor(netHex: 0x5CADCF)
            static let Mariner = UIColor(netHex: 0x3585C5)
            static let CuriousBlue = UIColor(netHex: 0x4590B6)
            static let Denim = UIColor(netHex: 0x2F6CAD)
            static let Chambray = UIColor(netHex: 0x485675)
            static let BlueWhale = UIColor(netHex: 0x29334D)
        }
        
        struct Violet {
            static let Wisteria = UIColor(netHex: 0x9069B5)
            static let BlueGem = UIColor(netHex: 0x533D7F)
        }
        
        struct Yellow {
            static let Energy = UIColor(netHex: 0xF2D46F)
            static let Turbo = UIColor(netHex: 0xF7C23E)
        }
        
        struct Orange {
            static let NeonCarrot = UIColor(netHex: 0xF79E3D)
            static let Sun = UIColor(netHex: 0xEE7841)
        }
        
        struct Red {
            static let TerraCotta = UIColor(netHex: 0xE66B5B)
            static let Valencia = UIColor(netHex: 0xCC4846)
            static let Cinnabar = UIColor(netHex: 0xDC5047)
            static let WellRead = UIColor(netHex: 0xB33234)
        }
        
        struct Gray {
            static let AlmondFrost = UIColor(netHex: 0xA28F85)
            static let WhiteSmoke = UIColor(netHex: 0xEFEFEF)
            static let Iron = UIColor(netHex: 0xD1D5D8)
            static let IronGray = UIColor(netHex: 0x75706B)
        }
    }
}

enum ServiceError: Error {
    case noData
    case invalidParameters
}

extension Collection where Indices.Iterator.Element == Index {
   public subscript(safe index: Index) -> Iterator.Element? {
     return (startIndex <= index && index < endIndex) ? self[index] : nil
   }
}

extension CGFloat {
    static func random() -> CGFloat {
        return CGFloat(arc4random()) / CGFloat(UInt32.max)
    }
}

extension UIColor {
    static func random() -> UIColor {
        return UIColor(
           red:   .random(),
           green: .random(),
           blue:  .random(),
           alpha: 1.0
        )
    }
}

extension UIColor {
    convenience init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt64()
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}

extension UIImage {
    func toPngString() -> String? {
        let data = self.pngData()
        return data?.base64EncodedString(options: .endLineWithLineFeed)
    }
  
    func toJpegString(compressionQuality cq: CGFloat) -> String? {
        let data = self.jpegData(compressionQuality: cq)
        return data?.base64EncodedString(options: .endLineWithLineFeed)
    }
}

extension NSMutableData {
    func appendString(string: String) {
        let data = string.data(using: String.Encoding.utf8, allowLossyConversion: true)
        append(data!)
    }
}
