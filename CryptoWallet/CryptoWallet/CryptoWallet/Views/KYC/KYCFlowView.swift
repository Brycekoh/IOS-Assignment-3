//
//  KYCFlowView.swift
//  CryptoWallet
//
//  Coordinator for the four-step ID verification flow:
//  1. Country + document type selection
//  2. Front + back document upload (or selfie if passport)
//  3. Selfie photo
//  4. "You're verified" success screen
//
//  Step state lives here so the child views remain dumb. Each child
//  calls a closure to advance, and the coordinator decides what
//  comes next.
//

import SwiftUI

struct KYCFlowView: View {
    
    enum Step {
        case selectDocument
        case uploadDocument
        case selfie
        case verified
    }
    
    @State private var step: Step = .selectDocument
    @State private var profile = KYCProfile()
    
    var body: some View {
        ZStack {
            Theme.backgroundPrimary.ignoresSafeArea()
            
            switch step {
            case .selectDocument:
                KYCDocumentSelectionView(profile: $profile) {
                    step = .uploadDocument
                }
            case .uploadDocument:
                KYCDocumentUploadView(profile: $profile) {
                    step = .selfie
                } onBack: {
                    step = .selectDocument
                }
            case .selfie:
                KYCSelfieView(profile: $profile) {
                    step = .verified
                } onBack: {
                    step = .uploadDocument
                }
            case .verified:
                KYCVerifiedView()
            }
        }
    }
}
