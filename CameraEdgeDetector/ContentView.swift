import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject private var cameraManager = CameraManager()
    
    var body: some View {
        ZStack {
            if let image = cameraManager.currentFrame {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Initializing LED Detector...")
                        .font(.title)
                    Text("Point camera at LEDs to detect cathode orientation")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
        }
        .frame(minWidth: 1024, minHeight: 768)
        .onAppear {
            cameraManager.checkPermissions()
        }
    }
}
