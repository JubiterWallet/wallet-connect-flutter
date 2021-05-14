import Flutter
import UIKit
import PromiseKit

public class SwiftWalletConnectFlutterPlugin: NSObject,FlutterStreamHandler,FlutterPlugin {
    
    
    
    var interactor: WCInteractor?
    let clientMeta = WCPeerMeta(name: "MYKEY", url: "https://mykey.org",description:"MYKEY Lab" ,icons: ["https://cdn.mykey.tech/mykey-website/static/img/favicon-32.ico"])
 
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
        guard interactor != nil else {
            self.resultMsg(result: result, error: WalletConnectPluginError.none , data: nil, message: "")
            return
        }
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
                self.connectTo(result:result,session: session)
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
                var rowJson = String(data: data, encoding:String.Encoding.utf8)!
                let dict : NSDictionary = getDictionaryFromJSONString(jsonString: rowJson)
                dict.setValue(dict["peerMeta"], forKey: "meta")
                rowJson = getJSONStringFromDictionary(dictionary: dict)
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
                var rowJson = String(data: data, encoding:String.Encoding.utf8)!
                switch event {
//                rowJson    String    "{\"value\":\"0x9184e72a000\",\"to\":\"0x7a250d5630b4cf539739df2c5dacb4c659f2488d\",\"gas\":\"0x60b9d\",\"data\":\"0x7ff36ab500000000000000000000000000000000000000000000000003504cd5942e0cc200000000000000000000000000000000000000000000000000000000000000800000000000000000000000002c70f383699004f9e7eff8d595b354f5785dc10b000000000000000000000000000000000000000000000000000000006008f9e70000000000000000000000000000000000000000000000000000000000000004000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc2000000000000000000000000c00e94cb662c3520282e6f5717214004a7f26888000000000000000000000000dac17f958d2ee523a2206206994597c13d831ec7000000000000000000000000744d70fdbe2ba4cf95131626614a1763df805b9e\",\"from\":\"0x2c70f383699004f9e7eff8d595b354f5785dc10b\"}"
                case .ethSendTransaction:
                    let dict : NSDictionary = getDictionaryFromJSONString(jsonString: rowJson)
                    dict.setValue(dict["gas"], forKey: "gasLimit")
                    rowJson = getJSONStringFromDictionary(dictionary: dict)
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


func getDictionaryFromJSONString(jsonString:String) ->NSDictionary{
 
    let jsonData:Data = jsonString.data(using: .utf8)!
 
    let dict = try? JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers)
    if dict != nil {
        return dict as! NSDictionary
    }
    return NSDictionary()
     
 
}

func getJSONStringFromDictionary(dictionary:NSDictionary) -> String {
      if (!JSONSerialization.isValidJSONObject(dictionary)) {
          print("无法解析出JSONString")
          return ""
      }
    let data : NSData! = try? JSONSerialization.data(withJSONObject: dictionary, options: []) as NSData?
      let JSONString = NSString(data:data as Data,encoding: String.Encoding.utf8.rawValue)
      return JSONString! as String

  }
