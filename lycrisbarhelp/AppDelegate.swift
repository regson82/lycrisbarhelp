//
//  AppDelegate.swift
//  lycrisbarhelp
//
//  Created by Reg R. on 17/7/25.
//
// AppDelegate.swift
// Manages the separate, always-on-top floating lyrics window.

import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var floatingWindow: NSWindow?
    var appState: AppState? {
        didSet {
            if oldValue == nil && appState != nil {
                DispatchQueue.main.async {
                    self.toggleFloatingWindow()
                }
            }
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NotificationCenter.default.addObserver(self, selector: #selector(toggleFloatingWindow), name: .toggleFloatingWindow, object: nil)
    }

    @objc func toggleFloatingWindow() {
        guard let appState = appState else { return }

        if appState.showFloatingWindow {
            if floatingWindow == nil {
                createFloatingWindow()
            }
        } else {
            closeFloatingWindow()
        }
    }

    func createFloatingWindow() {
        guard floatingWindow == nil, let appState = appState else { return }

        let floatingView = FloatingLyricsView().environmentObject(appState)
        let hostingController = NSHostingController(rootView: floatingView)

        let window = NSWindow(
            contentViewController: hostingController
        )
        
        window.center()
        window.styleMask = [.borderless]
        window.level = .floating
        window.isOpaque = false
        window.backgroundColor = .clear
        window.isMovableByWindowBackground = true
        window.hasShadow = false
        
        hostingController.view.setFrameSize(NSSize(width: 800, height: 100))
        
        window.makeKeyAndOrderFront(nil)
        
        self.floatingWindow = window
    }

    func closeFloatingWindow() {
        floatingWindow?.close()
        floatingWindow = nil
    }
}

// The new FloatingLyricsView with a true "Liquid Glass" text style.
struct FloatingLyricsView: View {
    @EnvironmentObject var appState: AppState
    
    var transition: AnyTransition {
        switch appState.animationType {
        case .fade:
            return .opacity.animation(.easeInOut(duration: 0.4))
        case .scale:
            return .scale(scale: 0.8).combined(with: .opacity).animation(.spring(response: 0.4, dampingFraction: 0.6))
        case .slide:
            return .asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .top)).combined(with: .opacity)
        }
    }
    
    private func lyricTextView(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 36, weight: .bold, design: .rounded))
            .foregroundColor(.white) // Base color is always white for the glass effect.
    }
    
    var body: some View {
        Group {
            if appState.lyrics.indices.contains(appState.currentLyricLine) {
                let lyricLine = appState.lyrics[appState.currentLyricLine]
                
                // ZStack to layer effects for the glass style, inspired by the example image.
                ZStack {
                    // Layer 1: The main text fill, which is semi-transparent.
                    lyricTextView(lyricLine)
                        .opacity(0.6)

                    // Layer 2: The top-left highlight, giving the "glass edge" effect.
                    lyricTextView(lyricLine)
                        .blendMode(.overlay)
                        .blur(radius: 0.5)
                        .offset(x: -1, y: -1)
                        .opacity(appState.glassHighlightIntensity) // Controlled by the slider.
                    
                    // Layer 3: A subtle dark shadow for the bottom-right edge.
                    lyricTextView(lyricLine)
                        .foregroundColor(.black)
                        .blendMode(.multiply)
                        .blur(radius: 0.5)
                        .offset(x: 1, y: 1)
                        .opacity(0.4)
                }
                .shadow(color: .black.opacity(0.5), radius: 5, x: 0, y: 5) // Outer shadow for readability.
                .id(lyricLine)
                .transition(transition)
            } else {
                Text("")
            }
        }
        .frame(width: 800, height: 100, alignment: .center)
    }
}
