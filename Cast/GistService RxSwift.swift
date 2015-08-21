import Cocoa
import SwiftyJSON
import RxSwift
import RxCocoa

enum ConnectionError: ErrorType {
    case InvalidData(String), NoResponse(String)
}

/**
GistService: is a wrapper around the gist.github.com service API.

An instance of GistService allows you login via OAuth with your GitHub account or remain anonymous.

You may create new gists as anonymous but you may modify a gist only if you're logged into the service.

- TODO: Add OAuth2 towards GitHub as a protocol conformance
- TODO: Store gistID in NSUserDefaults
*/
public final class GistService {
    
    //MARK:- Properties
    static let defaultURL = NSURL(string: "https://api.github.com/gists")!
    private let gistAPIURL: NSURL
    private var gistID: String?
    private var userLoggedIn: Bool
    
    
    //MARK:- Initialisation
    public init(baseURL: NSURL = defaultURL) {
        self.gistAPIURL = baseURL
        self.userLoggedIn = false
    }
    
    /**
    Used for Unit Tests purposes only, this API doesn't support any other service
    except `gist.github.com`
    */
    public convenience init?(baseURLString: String) {
        if let baseURL = NSURL(string: baseURLString) {
            self.init(baseURL: baseURL)
        } else {
            print(__FUNCTION__)
            print("URL not conforming to RFCs 1808, 1738, and 2732 formats")
            return nil
        }
    }
    
    
    //MARK:- Public API
    /**
    setGist: creates or updates a gist on the *gist.github.com* service
    based on the value of `gistID`.
    
    - returns: an `Observable` object containing the URL link of the created gist - for more information checkout
    [RxSwift](https://github.com/ReactiveX/RxSwift)
    
    ![RxLogo](http://reactivex.io/assets/Rx_Logo_BW_S.png)
    */
    public func setGist(content content: String, updateGist: Bool = true,
        isPublic: Bool = false, fileName: String = "Casted.swift") // defaults
        -> Observable<NSURL> {
            
            let githubHTTPBody = [
                "description": "Generated with Cast (cast.lfaoro.com)",
                "public": isPublic,
                "files": [fileName: ["content": content]],
            ]
            
            var request: NSMutableURLRequest
            if let gistID = self.gistID where (updateGist && userLoggedIn) {
                let updateURL = self.gistAPIURL.URLByAppendingPathComponent(gistID)
                request = NSMutableURLRequest(URL: updateURL)
                request.HTTPMethod = "PATCH"
            } else {
                request = NSMutableURLRequest(URL: self.gistAPIURL)
                request.HTTPMethod = "POST"
                request.HTTPBody = try! JSON(githubHTTPBody).rawData()
            }
            
            return create { observer in
                let session = NSURLSession.sharedSession()
                let task = session.dataTaskWithRequest(request) { (data, response, error) in
                    if let data = data {
                        let jsonData = JSON(data: data)
                        if let gistURL = jsonData["html_url"].URL, gistID = jsonData["id"].string {
                            self.gistID = gistID
                            
                            just(gistURL)
                            sendNext(observer, gistURL)
                            sendCompleted(observer)
                        } else {
                            sendError(observer, ConnectionError.InvalidData("Unable to read data received from \(self.gistAPIURL)"))
                        }
                    } else {
                        sendError(observer, ConnectionError.NoResponse(error!.localizedDescription))
                    }
                }
                
                task.resume()
                
                return NopDisposable.instance
            }
    }
}