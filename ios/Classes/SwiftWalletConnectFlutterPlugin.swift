import Flutter
import UIKit
import PromiseKit
import TrustWalletCore

public class SwiftWalletConnectFlutterPlugin: NSObject,FlutterStreamHandler,FlutterPlugin {
    
    
    
    var interactor: WCInteractor?
    let clientMeta = WCPeerMeta(name: "WalletConnect SDK", url: "https://github.com/TrustWallet/wallet-connect-swift")
 
    var eventSink: FlutterEventSink?
     
    static var eventChannel :FlutterEventChannel?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "wallet_connect_flutter", binaryMessenger: registrar.messenger())
        eventChannel  = FlutterEventChannel(name: "wallet_connect_flutter/event",binaryMessenger: registrar.messenger())
        
        let instance = SwiftWalletConnectFlutterPlugin()
        
        eventChannel?.setStreamHandler(instance)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events;
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil;
        return nil
    }
    
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "connect":
            let args: NSDictionary = call.arguments as! NSDictionary
            let uri : String = args["uri"] as! String
            connect(result: result,string:   uri  )
        case "approveSession":
            let args: NSDictionary = call.arguments as! NSDictionary
            let accounts : [String] = args["addresses"] as!  [String]
            let chainID :Int = args["chainID"] as!  Int
            approveSession(result: result,accounts:   accounts,chainId:  chainID)
        case "rejectSession":
            
            rejectSession(result: result)
        case "killSession":
            
            killSession(result: result)
        case "approveCallRequest":
            let args: NSDictionary = call.arguments as! NSDictionary
            let id : Int = args["id"] as!  Int
            let resultStr : String = args["result"] as!  String
            
            approveCallRequest(result: result,id:id,resultStr:resultStr)
        case "rejectCallRequest":
            let args: NSDictionary = call.arguments as! NSDictionary
            let id : Int = args["id"] as!  Int
            let message : String = args["message"] as!  String
            rejectCallRequest(result: result,id:id,meg:message)
            
        default:
            return
        }
        
    }
    
    func rejectCallRequest(result: @escaping  FlutterResult,id:Int,meg:String) {
        interactor?.rejectRequest(id:  Int64(id), message: meg).done {
            self.resultMsg(result: result, error: WalletConnectPluginError.none , data: nil, message: "")
        }.cauterize()
    }
    
    func approveCallRequest(result: @escaping  FlutterResult,id:Int,resultStr:String) {
        interactor?.approveRequest(id:  Int64(id), result: resultStr).done {
            self.resultMsg(result: result, error: WalletConnectPluginError.none , data: nil, message: "")
        }.cauterize()
    }
    
    
    func killSession(result: @escaping  FlutterResult) {
        interactor?.killSession().done {
            self.resultMsg(result: result, error: WalletConnectPluginError.none , data: nil, message: "")
        }.cauterize()
    }
    
    
    
    func rejectSession(result: @escaping  FlutterResult) {
        interactor?.rejectSession().done {
            self.resultMsg(result: result, error: WalletConnectPluginError.none , data: nil, message: "")
        }.cauterize()
    }
    
    
    func approveSession(result: @escaping  FlutterResult,accounts: [String], chainId: Int) {
        interactor?.approveSession(accounts: accounts, chainId: chainId).done {
            self.resultMsg(result: result, error: WalletConnectPluginError.none , data: nil, message: "")
            
        }.catch { [weak self] error in
            self?.resultMsg(result: result, error: WalletConnectPluginError.approveError , data: nil, message: error.localizedDescription)
            
        }
    }
    
    func connect(result: @escaping  FlutterResult,string: String)    {
        guard  let session = WCSession.from(string: string) else {
            resultMsg(result: result, error: WalletConnectPluginError.uriError , data: nil, message: "")
            return
        }
        if let i = interactor, i.state == .connected {
            i.killSession().done {
                self.resultMsg(result: result, error: WalletConnectPluginError.allreadyConnected , data: nil, message: "")
                return
            }.cauterize()
        } else {
            connectTo(result:result,session: session)
        }
    }
    
    func connectTo(result:@escaping  FlutterResult,session: WCSession) {
        print("==> session", session)
        let interactor = WCInteractor(session: session, meta: clientMeta, uuid: UIDevice.current.identifierForVendor ?? UUID())
        
        configure(interactor: interactor)
        
        interactor.connect().done { [weak self] connected in
            self?.resultMsg(result: result, error: WalletConnectPluginError.none , data: nil, message: "")
        }.catch { [weak self] error in
            self?.resultMsg(result: result, error: WalletConnectPluginError.connectedError , data: nil, message: error.localizedDescription)
        }
        
        self.interactor = interactor
    }
    
    func configure(interactor: WCInteractor) {
        
        interactor.onError = { [weak self] error in
            self?.eventSink!([
                "eventName":"onError",
                "params":error.localizedDescription,
            ])
         }
        
        
        interactor.onSessionRequest = { [weak self] (id, peerParam) in
            do {
                let json = JSONEncoder()
                let data = try json.encode(peerParam);
              let rowJson = String(data: data, encoding:String.Encoding.utf8)!

                self?.eventSink!([
                    "eventName":"onSessionRequest",
                    "params": [ "id":id,"data": rowJson] ,
                ])
                
            } catch  {
                
            }
            
        }
        
        interactor.onDisconnect = { [weak self] (error) in
        
            self?.eventSink!([
                "eventName":"onSessionDissconnect",
                "params": error?.localizedDescription ,
            ])
         }
        
        interactor.eth.onSign = { [weak self] (id, payload) in
            do {
                switch payload {
                case .sign(_, let raw ):
                    let json = JSONEncoder()
                    let data = try json.encode(raw);
                  let rowJson = String(data: data, encoding:String.Encoding.utf8)!
                    self?.eventSink!([
                        "eventName":"onCallRequestEthSign",
                        "params": ["id":id,"rawJson":rowJson]  ,
                    ])
                     
                case .personalSign(_, let raw):
                    let json = JSONEncoder()
                    let data = try json.encode(raw);
                  let rowJson = String(data: data, encoding:String.Encoding.utf8)!
                    self?.eventSink!([
                        "eventName":"onCallRequestPersonalSign",
                        "params": ["id":id,"rawJson":rowJson]  ,
                    ])
                     
                case .signTypeData(_, _, let raw):
                    let json = JSONEncoder()
                    let data = try json.encode(raw);
                  let rowJson = String(data: data, encoding:String.Encoding.utf8)!
                    self?.eventSink!([
                        "eventName":"onCallRequestEthSignTypedData",
                        "params": ["id":id,"rawJson":rowJson] ,
                    ])
                     
               
                }
        
            } catch  {
                
            }
        }
        
        interactor.eth.onTransaction = { [weak self] (id, event, transaction) in
            do {
                let data = try! JSONEncoder().encode(transaction)
                let rowJson = String(data: data, encoding:String.Encoding.utf8)!
                switch event {
                case .ethSendTransaction:
                    self?.eventSink!([
                        "eventName":"onCallRequestEthSendTransaction",
                        "params": ["id":id,"rawJson":rowJson]  ,
                    ])
                     
                case .ethSignTransaction:
                    self?.eventSink!([
                        "eventName":"onCallRequestEthSignTransaction",
                        "params": ["id":id,"rawJson":rowJson]  ,
                    ])
                     
                default:
                break
                     
               
                }
            }
            
        }
         
    }
    
    
    
 
    func resultMsg( result:  FlutterResult,error:WalletConnectPluginError,data : [String: Any]?,message : String)  {
        
        result([
            "error": error.rawValue,
            "msg": message,
            "data": data ?? [:],
        ])
    }
    
    
}

enum WalletConnectPluginError : Int {
    case none
    case allreadyConnected
    case uriError
    case connectedError
    case approveError
    case rejectError
}
