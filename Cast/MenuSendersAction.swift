//
//  Created by Leonardo on 18/07/2015.
//  Copyright © 2015 Leonardo Faoro. All rights reserved.
//
import Cocoa

final class MenuSendersAction: NSObject {
    //---------------------------------------------------------------------------
    func shareClipboardContentsAction(sender: NSMenuItem) {
        let pasteboard = PasteboardController()
        var content: String?
        do {
            let data = try pasteboard.extractData()
            switch data {
            case .Text(let stringData):
                print(stringData)
                content = stringData
            default: app.userNotification.pushNotification(error: "The pasteboard is Empty or Unreadable")
            }
        } catch CastErrors.EmptyPasteboardError {
            app.userNotification.pushNotification(error: "The pasteboard is Empty or Unreadable")
        } catch {
            app.userNotification.pushNotification(error: "\(error)")
        }
        
        app.gistService.setGist(content: content!)
            .on(next: {
                app.userNotification.pushNotification(openURL: $0.URL)
            })
            .on(error: print)
            .start()
    }
    //---------------------------------------------------------------------------
    func recentUploadsAction(sender: NSMenuItem) {
        let url = NSURL(string: sender.representedObject as! String)
        if let url = url {
            NSWorkspace.sharedWorkspace().openURL(url)
        } else {
            fatalError("No link in recent uploads")
        }
    }
    //---------------------------------------------------------------------------
    func clearItemsAction(sender: NSMenuItem) {
        if recentUploads.count > 0 {
            recentUploads.removeAll()
            Swift.print(recentUploads)
            app.updateMenu()
        }
    }
    //---------------------------------------------------------------------------
    func startAtLoginAction(sender: NSMenuItem) {
        if sender.state == 0 {
            sender.state = 1
        } else {
            sender.state = 0
        }
    }
    //---------------------------------------------------------------------------
    func openOptionsWindow(sender: NSMenuItem) { //TODO: Implement
        app.options.displayOptionsWindow()
    }
}
 