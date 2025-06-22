//
//  ContentView.swift
//  Tech Case Bluetooth
//

import SwiftUI
import CoreBluetooth
import AVFoundation
import AVKit
import MediaPlayer  // For Bluetooth audio output

// ViewModel voor Bluetooth-functionaliteit
class BluetoothViewModel: NSObject, ObservableObject {
    private var centralManager: CBCentralManager?  // Beheer van de Bluetooth-verbinding
    private var peripherals: [CBPeripheral] = []  // Lijst van gedetecteerde Bluetooth-apparaten
    private var selectedPeripheral: CBPeripheral?  // Het geselecteerde apparaat om verbinding mee te maken
    private var audioPlayer: AVAudioPlayer?  // Audio speler voor het afspelen van geluid
    private var timer: Timer?  // Timer om audio automatisch af te spelen

    @Published var peripheralNames: [String] = []  // Lijst van namen van gevonden apparaten
    @Published var isConnected: Bool = false  // Status of we verbonden zijn met een apparaat
    @Published var connectedDeviceName: String = ""  // Naam van het verbonden apparaat

    override init() {
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: .main)  // Initialiseer de Bluetooth central manager
        prepareAudio()  // Laad de audio voor gebruik
    }
    
    // Start het scannen naar beschikbare Bluetooth apparaten
    func startScanning() {
        self.peripheralNames.removeAll()  // Leeg de lijst van apparaten
        self.peripherals.removeAll()  // Leeg de lijst van gedetecteerde apparaten
        self.centralManager?.scanForPeripherals(withServices: nil)  // Start scannen
    }
    
    // Verbind met een geselecteerd apparaat op basis van de index
    func connect(to index: Int) {
        let peripheral = peripherals[index]
        self.selectedPeripheral = peripheral  // Sla het geselecteerde apparaat op
        self.centralManager?.stopScan()  // Stop met scannen als we een apparaat hebben gevonden
        self.centralManager?.connect(peripheral, options: nil)  // Maak verbinding met het apparaat
    }
    
    // Speel audio af naar het verbonden apparaat
    func sendAudioToDevice() {
        audioPlayer?.play()  // Speel het geluid af
        print("🎵 Audio is being sent to Bluetooth device (if connected)")  // Debugging boodschap
    }
    
    // Start het automatisch verzenden van audio om de 30 seconden
    func startAutoSend() {
        timer?.invalidate()  // Stop de vorige timer (indien actief)
        timer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            self.sendAudioToDevice()  // Verstuur audio elke 30 seconden
        }
    }

    // Laad de audio die we willen afspelen
    private func prepareAudio() {
        guard let url = Bundle.main.url(forResource: "test_audio", withExtension: "mp3") else {
            print("⚠ Audio file not found")  // Als het audiobestand niet gevonden kan worden
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)  // Maak een audio speler van het bestand
            audioPlayer?.prepareToPlay()  // Bereid de speler voor
        } catch {
            print("⚠ Error loading audio: \(error.localizedDescription)")  // Foutmelding als audio niet kan worden geladen
        }
    }
}

// MARK: - Bluetooth Delegates
// Hier worden de delegate methoden van de CBCentralManager toegevoegd die reageren op veranderingen in de Bluetooth status
extension BluetoothViewModel: CBCentralManagerDelegate {
    // Callback wanneer de Bluetooth status verandert (bijvoorbeeld als Bluetooth wordt ingeschakeld)
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {  // Als Bluetooth aanstaat
            startScanning()  // Begin met het scannen van apparaten
        }
    }

    // Callback wanneer een nieuw apparaat wordt ontdekt
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        if !peripherals.contains(peripheral) {  // Voeg het apparaat toe als het nog niet in de lijst staat
            self.peripherals.append(peripheral)
            self.peripheralNames.append(peripheral.name ?? "Unknown Device")  // Voeg de naam van het apparaat toe
        }
    }

    // Callback wanneer de verbinding met een apparaat succesvol is
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("✅ Connected to: \(peripheral.name ?? "Unknown Device")")  // Debugging boodschap
        self.isConnected = true  // Stel de status in op verbonden
        self.connectedDeviceName = peripheral.name ?? "Unknown Device"  // Bewaar de naam van het verbonden apparaat
        startAutoSend()  // Start de automatische audioverzending
    }

    // Callback wanneer de verbinding met een apparaat faalt
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("❌ Failed to connect to \(peripheral.name ?? "Unknown Device")")  // Foutmelding als verbinding niet lukt
    }
}

// MARK: - UI for Bluetooth Audio
// Deze struct zorgt voor de interface waarmee de gebruiker de audio naar Bluetooth apparaten kan sturen
struct BluetoothAudioView: UIViewRepresentable {
    // Creëer de AVRoutePickerView die de gebruiker laat kiezen welk apparaat ze willen gebruiken
    func makeUIView(context: Context) -> AVRoutePickerView {
        let routePickerView = AVRoutePickerView()
        routePickerView.tintColor = .blue  // 🔹 Kleur van het Bluetooth-pictogram
        return routePickerView
    }
    
    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {}
}

// MARK: - Main Content View
// De hoofdstructuur van de app, waar de lijst van Bluetooth-apparaten en hun status wordt weergegeven
struct ContentView: View {
    @ObservedObject private var bluetoothViewModel = BluetoothViewModel()  // ViewModel voor Bluetooth functionaliteit

    var body: some View {
        NavigationView {
            VStack {
                List {
                    // Maak een lijst van Bluetooth-apparaten die gescand zijn
                    ForEach(bluetoothViewModel.peripheralNames.indices, id: \.self) { index in
                        Button(action: {
                            bluetoothViewModel.connect(to: index)  // Verbind met het geselecteerde apparaat
                        }) {
                            Text(bluetoothViewModel.peripheralNames[index])
                                .font(.title) // Maakt de tekst groter
                                .foregroundColor(Color.red) 

                        }
                    }
                }
                .navigationTitle("Bluetooth Devices")  // Zet de titel van de navigatiebalk
                
                if bluetoothViewModel.isConnected {  // Als er een verbinding is
                    VStack(spacing: 10) {
                        // Toon de naam van het verbonden apparaat
                        Text("✅ Connected to: \(bluetoothViewModel.connectedDeviceName)")
                            .font(.headline)
                            .foregroundColor(.green)
                        BluetoothAudioView()  // 🔊 Toon de audio output keuze
                    }
                    .padding()
                }
            }
        }
    }
}

#Preview {
    ContentView()  // Toon de hoofdweergave in de preview
}


