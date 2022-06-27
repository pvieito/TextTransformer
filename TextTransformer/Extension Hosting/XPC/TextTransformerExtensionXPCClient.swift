//
//  TextTransformerExtensionXPCClient.swift
//  TextTransformer
//
//  Created by Guilherme Rambo on 27/06/22.
//

import Foundation
import ExtensionFoundation
@_spi(TextTransformerXPC) import TextTransformerSDK

final class TextTransformerExtensionXPCClient: NSObject {
    
    let process: AppExtensionProcess
    
    public init(with process: AppExtensionProcess) {
        self.process = process
    }
    
    public func runOperation(with input: String) async throws -> String {
        var done = false
        
        let connection = try process.makeXPCConnection()
        connection.remoteObjectInterface = NSXPCInterface(with: TextTransformerXPCProtocol.self)
        
        connection.resume()
    
        return try await withCheckedThrowingContinuation { continuation in
            guard let service = connection.remoteObjectProxyWithErrorHandler({ error in
                if !done {
                    continuation.resume(throwing: error)
                }
            }) as? TextTransformerXPCProtocol else {
                continuation.resume(throwing: "Couldn't communicate with the extension")
                return
            }
            
            service.transform(input: input) { result in
                done = true
                
                if let result {
                    continuation.resume(returning: result)
                } else {
                    continuation.resume(throwing: "Extension returned nil response")
                }
            }
        }
    }
    
}
