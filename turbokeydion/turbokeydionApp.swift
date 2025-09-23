//
//  turbokeydionApp.swift
//  turbokeydion
//
//  Created by Viktor Rudnev on 22/09/2025.
//

import SwiftUI
import CoreMIDI
import Combine


struct ParamField: View {
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    
    @State private var lastDragValue: CGFloat = 0
    
    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .frame(width: 80, alignment: .leading)
            TextField("", value: $value, formatter: NumberFormatter())
                .frame(width: 50)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onChange(of: value) { newValue in
                    if newValue < range.lowerBound { value = range.lowerBound }
                    if newValue > range.upperBound { value = range.upperBound }
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { gesture in
                            let delta = gesture.translation.height - lastDragValue
                            if abs(delta) > 2 { // small threshold so we don't trigger on click
                                value = min(max(value - Int(delta), range.lowerBound), range.upperBound)
                                lastDragValue = gesture.translation.height
                            }
                        }
                        .onEnded { _ in lastDragValue = 0 }
                )
        }
    }
}


// -----------------------------
// MARK: - MIDI Manager
// -----------------------------
final class MidiManager: ObservableObject {
    private var client = MIDIClientRef()
    private var source = MIDIEndpointRef()
    @Published var isReady = false
    @Published var lastSent: String = ""
    
    init() {
        createVirtualSource()
    }
    
    deinit {
        if source != 0 { MIDIPortDispose(source) } // just in case
        MIDIClientDispose(client)
    }
    
    private func createVirtualSource() {
        let name = "SwiftAccordion Virtual Source" as CFString
        MIDIClientCreateWithBlock("SwiftAccordionClient" as CFString, &client) { _ in }
        let status = MIDISourceCreate(client, name, &source)
        if status == noErr {
            isReady = true
            lastSent = "Virtual source created: \(name)"
        } else {
            isReady = false
            lastSent = "Failed to create virtual source (error: \(status))"
        }
    }
    
    // Use MIDIReceived to send from the virtual source so other apps see it
    func sendNoteOn(channel: UInt8, note: UInt8, velocity: UInt8) {
        sendMidi(status: 0x90 | (channel & 0x0F), data1: note, data2: velocity)
        lastSent = "Note ON ch:\(channel+1) note:\(note) vel:\(velocity)"
    }
    func sendNoteOff(channel: UInt8, note: UInt8, velocity: UInt8 = 0) {
        sendMidi(status: 0x80 | (channel & 0x0F), data1: note, data2: velocity)
        lastSent = "Note OFF ch:\(channel+1) note:\(note)"
    }
    
    private func sendMidi(status: UInt8, data1: UInt8, data2: UInt8) {
        guard source != 0 else { return }
        // Prepare one packet
        var packet = MIDIPacket()
        packet.timeStamp = 0
        packet.length = 3
        packet.data.0 = status
        packet.data.1 = data1
        packet.data.2 = data2
        // Put into packet list
        var packetList = MIDIPacketList(numPackets: 1, packet: packet)
        // Send via MIDIReceived, which delivers from this virtual source
        withUnsafePointer(to: &packetList) { ptr in
            MIDIReceived(source, ptr)
        }
    }
}

// -----------------------------
// MARK: - Key capture NSView for SwiftUI
// -----------------------------
final class KeyCaptureNSView: NSView {
    var onKeyDown: ((NSEvent) -> Void)?
    var onKeyUp: ((NSEvent) -> Void)?

    override var acceptsFirstResponder: Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        DispatchQueue.main.async {
            self.window?.makeFirstResponder(self) // 👈 ensures we capture keys automatically
        }
    }

    override func keyDown(with event: NSEvent) {
        onKeyDown?(event)
    }

    override func keyUp(with event: NSEvent) {
        onKeyUp?(event)
    }
}

// SwiftUI wrapper
struct KeyCaptureRepresentable: NSViewRepresentable {
    var onKeyDown: (NSEvent) -> Void
    var onKeyUp: (NSEvent) -> Void
    
    func makeNSView(context: Context) -> KeyCaptureNSView {
        let v = KeyCaptureNSView(frame: .zero)
        v.onKeyDown = onKeyDown
        v.onKeyUp = onKeyUp
        return v
    }
    func updateNSView(_ nsView: KeyCaptureNSView, context: Context) { }
}

// -----------------------------
// MARK: - ContentView / UI
// -----------------------------
struct ContentView: View {
    @StateObject private var midi = MidiManager()
    @State private var noteOffset: Int = 48 // base MIDI note
    @State private var channel: Int = 0 // 0..15 displayed as 1..16
    @State private var velocity: Int = 30
    @State private var active = Set<Int>()
    @State private var showHelp = true
    
    // MARK: - C-griff mapping
    let cGriffRows: [[Character]] = [
        ["1","2","3","4","5","6","7","8","9","0","-","="],
        ["q","w","e","r","t","y","u","i","o","p","[","]"],
        ["a","s","d","f","g","h","j","k","l",";","'","\\"],
        ["z","x","c","v","b","n","m",",",".","/"]
    ]
    let rowOffsets: [Int] = [0, 2, 4, 6];
//    let cGriffNotes: [[Int]] = [
//        [-6, -3, 0, 3, 6 ],
//        [-4, -1, 2, 5, 8 ],
//        [-2,  1, 4, 7, 10],
//        [ 0,  3, 6, 9, ]
//    ]
//    let offset = -6;

    // Build map dynamically
    var activeKeyMap: [Character: Int] {
        var map = [Character: Int]()
        for (rowIndex, row) in cGriffRows.enumerated() {
            for (colIndex, key) in row.enumerated() {
                let noteIndex = colIndex * 3 + rowOffsets[rowIndex]
                map[key] = noteIndex
            }
        }
        return map
    }
    
    // When user presses key by char or clicks UI:
    func noteOn(index: Int) {
        guard !active.contains(index) else { return }
        active.insert(index)
        let noteNumber = UInt8(clamping: index + noteOffset)
        midi.sendNoteOn(channel: UInt8(channel), note: noteNumber, velocity: UInt8(velocity))
    }
    func noteOff(index: Int) {
        guard active.contains(index) else { return }
        active.remove(index)
        let noteNumber = UInt8(clamping: index + noteOffset)
        midi.sendNoteOff(channel: UInt8(channel), note: noteNumber)
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Chromatic Button Accordion — QWERTY → Virtual MIDI").font(.headline)
                    HStack {
                        Text("Virtual source:").bold()
                        Text(midi.isReady ? "SwiftAccordion Virtual Source" : "not ready")
                        Spacer()
                        Text("Last:").bold()
                        Text(midi.lastSent).lineLimit(1).truncationMode(.middle)
                    }
                }
            }.padding(.bottom, 6)
            
            // Controls
            HStack {
                Stepper("Base note (MIDI): \(noteOffset)", value: $noteOffset, in: 0...100)
                    .frame(width: 260)
                Stepper("Channel: \(channel + 1)", value: $channel, in: 0...15)
                Stepper("Velocity: \(velocity)", value: $velocity, in: 1...127)
                Button("All Off") {
                    // send note off to all active
                    for i in active { noteOff(index: i) }
                }
            }
            
            Divider()
            
            // Buttons grid (compact rows)
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(0..<cGriffRows.count, id: \.self) { rowIndex in
                        HStack(spacing: 6) {
                            ForEach(0..<cGriffRows[rowIndex].count, id: \.self) { colIndex in
                                let char = cGriffRows[rowIndex][colIndex]
                                let noteIndex = colIndex * 3 + rowOffsets[rowIndex]
                                let isOn = active.contains(noteIndex)
                                
                                Button(action: {
                                    if isOn { noteOff(index: noteIndex) }
                                    else { noteOn(index: noteIndex) }
                                }) {
                                    VStack {
                                        Text(String(char))
                                            .font(.headline)
                                        Text("\(noteOffset + noteIndex)")
                                            .font(.caption2)
                                    }
                                    .padding(6)
                                    .frame(width: 40)
                                    .background(isOn ? Color.accentColor.opacity(0.9) : Color(NSColor.controlBackgroundColor))
                                    .cornerRadius(8)
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.15)))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.leading, CGFloat(rowIndex) * 12) // shift rows visually like real C-griff
                    }
                }
                .padding(.vertical, 6)
            }
            .frame(minHeight: 240)
            
            Divider()
            
            HStack {
                Text("Tip: click a button or type keys. Click the black area to ensure focus.")
                Spacer()
                Button("Show/Hide Help") { showHelp.toggle() }
            }
            
            if showHelp {
                VStack(alignment: .leading) {
                    Text("Mapping (first 33 keys) — QWERTY characters:").font(.subheadline).bold()
                }
                .padding(.top, 6)
            }
            
            // invisible key capture area
            KeyCaptureRepresentable(onKeyDown: { event in
                handleKeyDown(event: event)
            }, onKeyUp: { event in
                handleKeyUp(event: event)
            })
            .frame(width: 0, height: 0)

        }
        .padding()
        .frame(minWidth: 800, minHeight: 520)
    }
    
    // MARK: - Keyboard handling (NSEvent)
    private func handleKeyDown(event: NSEvent) {
        guard let chars = event.charactersIgnoringModifiers, !chars.isEmpty else { return }
        // process each character in the event just in case (e.g., international keyboards)
        for c in chars.lowercased() {
            if let idx = activeKeyMap[c] {
                noteOn(index: idx)
            }
        }
    }
    private func handleKeyUp(event: NSEvent) {
        guard let chars = event.charactersIgnoringModifiers, !chars.isEmpty else { return }
        for c in chars.lowercased() {
            if let idx = activeKeyMap[c] {
                noteOff(index: idx)
            }
        }
    }
}

// -----------------------------
// MARK: - App Entry
// -----------------------------
@main
struct SwiftAccordionApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(HiddenTitleBarWindowStyle())
    }
}
