//
//  Created by Leonardo on 18/07/2015.
//  Copyright © 2015 Leonardo Faoro. All rights reserved.
//


import Cocoa
import RxSwift

final class MenuSendersAction: NSObject {


	let shortenClient = ShortenClient()


	func shareClipboardContentsAction(sender: NSMenuItem) {

		let _ = PasteboardClient.getPasteboardItems()
			.debug("getPasteboardItems")
			.subscribe(next: { value in

				switch value {

				case .Text(let item):
					app.gistClient.setGist(content: item, isPublic: app.prefs.gistIsPublic!)
						.debug("setGist")
						.retry(3)
						.flatMap { self.shortenClient.shorten(URL: $0) }
						.subscribe { event in
							switch event {

							case .Next(let URL):
								if let URL = URL {
									PasteboardClient.putInPasteboard(items: [URL])
									app.userNotification.pushNotification(openURL: URL)
								} else {
									app.userNotification.pushNotification(error: "Unable to Shorten URL")
								}

							case .Completed:
								app.statusBarItem.menu = createMenu(self)

							case .Error(let error):
								app.userNotification.pushNotification(error: String(error))
							}
					}

				case .File(let file):
					print(file.path!)

				default: break

				}
			})
	}

	func updateGistAction(sender: NSMenuItem) {
		let _ = PasteboardClient.getPasteboardItems()
			.debug("getPasteboardItems")
			.subscribe(next: { value in

				switch value {

				case .Text(let item):
					app.gistClient.setGist(content: item,
						updateGist: true,
						isPublic: app.prefs.gistIsPublic!)
						.debug("setGist")
						.retry(3)
						.flatMap { self.shortenClient.shorten(URL: $0) }
						.subscribe { event in
							switch event {

							case .Next(let URL):
								if let URL = URL {
									PasteboardClient.putInPasteboard(items: [URL])
									app.userNotification.pushNotification(openURL: URL)
								} else {
									app.userNotification.pushNotification(error: "Unable to Shorten URL")
								}

							case .Completed:
								app.statusBarItem.menu = createMenu(self)

							case .Error(let error):
								app.userNotification.pushNotification(error: String(error))
							}
					}

				case .File(let file):
					print(file.path!)

				default: break

				}
			})
	}

	func shortenURLAction(sender: NSMenuItem) {

		let _ = PasteboardClient.getPasteboardItems()
			.debug("getPasteboardItems")
			.subscribe(next: { value in
				switch value {
				case .Text(let item):
					guard let url = NSURL(string: item) else { fallthrough }
					self.shortenClient.shorten(URL: url)
						.subscribe { event in
							switch event {
							case .Next(let shortenedURL):
								guard let URL = shortenedURL else { fallthrough }
								PasteboardClient.putInPasteboard(items: [URL])
								app.userNotification.pushNotification(openURL: URL,
									title: "Shortened with \(app.prefs.shortenService!)")

							case .Completed:
								print("completed")

							case .Error(let error):
								print("\(error)")
							}
					}

				default:
					app.userNotification.pushNotification(error: "Not a valid URL")
				}
			})
	}

	func loginToGithub(sender: NSMenuItem) {
		app.oauth.authorize()
	}

	func logoutFromGithub(sender: NSMenuItem) {

		if let error = OAuthClient.revoke() {
			app.userNotification.pushNotification(error: error.localizedDescription)
		} else {
			app.statusBarItem.menu = createMenu(app.menuSendersAction)
			app.userNotification.pushNotification(error: "GitHub Authentication",
				description: "API key revoked internally")
		}
	}

	func recentUploadsAction(sender: NSMenuItem) {
		if let url = sender.representedObject as? NSURL {
			NSWorkspace.sharedWorkspace().openURL(url)
		} else {
			fatalError("No link in recent uploads")
		}
	}

	func clearItemsAction(sender: NSMenuItem) {
		if app.prefs.recentActions!.count > 0 {
			app.prefs.recentActions!.removeAll()
			Swift.print(app.prefs.recentActions!)
			app.statusBarItem.menu = createMenu(app.menuSendersAction)
		}
	}

	func startAtLoginAction(sender: NSMenuItem) {
		if sender.state == 0 {
			sender.state = 1
		} else {
			sender.state = 0
		}
	}

	func optionsAction(sender: NSMenuItem) {
		NSApp.activateIgnoringOtherApps(true)
		app.optionsWindowController.showWindow(nil)
	}
}
