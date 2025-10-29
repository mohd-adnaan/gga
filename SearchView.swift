//
//  SearchView.swift
//  GloveGuide
//
//  Created by Mohammad Adnaan on 2025-10-26.
//

import SwiftUI
import MapKit
import Combine

struct SearchView: View {
    @ObservedObject var coordinator: AppCoordinator
    @Binding var searchText: String
    @Binding var searchResults: [MKMapItem]
    @Binding var isSearching: Bool
    @Environment(\.presentationMode) var presentationMode
    
    @StateObject private var searchCompleter = SearchCompleterManager()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                SearchBar(text: $searchText, onSearchButtonClicked: performSearch)
                    .padding()
                
                if isSearching {
                    ProgressView("Searching...")
                        .padding()
                    Spacer()
                } else if !searchResults.isEmpty {
                    // Search Results
                    List(searchResults, id: \.self) { item in
                        SearchResultRow(
                            item: item,
                            userLocation: coordinator.navigationManager.currentLocation
                        ) {
                            selectDestination(item)
                        }
                    }
                } else if !searchCompleter.completions.isEmpty {
                    // Auto-complete suggestions (like Apple Maps)
                    List(searchCompleter.completions, id: \.self) { completion in
                        SearchCompletionRow(completion: completion) {
                            searchText = "\(completion.title) \(completion.subtitle)".trimmingCharacters(in: .whitespaces)
                            performSearch()
                        }
                    }
                } else if searchText.isEmpty {
                    // Recent searches / nearby suggestions
                    VStack(spacing: 20) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("Start typing to search for destinations")
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    Spacer()
                } else {
                    // No results
                    VStack(spacing: 20) {
                        Image(systemName: "location.slash")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No results found")
                            .foregroundColor(.gray)
                    }
                    .padding()
                    Spacer()
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .onAppear {
            setupSearch()
        }
        .onChange(of: searchText) { newValue in
            searchCompleter.updateQuery(newValue)
            if newValue.isEmpty {
                searchResults = []
            }
        }
    }
    
    private func setupSearch() {
        // Configure search completer with user's location
        if let location = coordinator.navigationManager.currentLocation {
            searchCompleter.setUserLocation(location)
        }
    }
    
    private func performSearch() {
        guard !searchText.isEmpty else { return }
        
        isSearching = true
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        
        if let location = coordinator.navigationManager.currentLocation {
            request.region = MKCoordinateRegion(
                center: location.coordinate,
                latitudinalMeters: 50000,
                longitudinalMeters: 50000
            )
        }
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            DispatchQueue.main.async {
                isSearching = false
                if let response = response {
                    searchResults = response.mapItems
                } else if let error = error {
                    coordinator.showError("Search failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func selectDestination(_ item: MKMapItem) {
        presentationMode.wrappedValue.dismiss()
        coordinator.startNavigation(to: item)
    }
}

struct SearchBar: UIViewRepresentable {
    @Binding var text: String
    var onSearchButtonClicked: () -> Void
    
    func makeUIView(context: Context) -> UISearchBar {
        let searchBar = UISearchBar()
        searchBar.delegate = context.coordinator
        searchBar.placeholder = "Search for places..."
        searchBar.searchBarStyle = .minimal
        return searchBar
    }
    
    func updateUIView(_ uiView: UISearchBar, context: Context) {
        uiView.text = text
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UISearchBarDelegate {
        let parent: SearchBar
        
        init(_ parent: SearchBar) {
            self.parent = parent
        }
        
        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            parent.text = searchText
        }
        
        func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
            searchBar.resignFirstResponder()
            parent.onSearchButtonClicked()
        }
    }
}

struct SearchResultRow: View {
    let item: MKMapItem
    let userLocation: CLLocation?
    let onTap: () -> Void
    
    private var distance: String {
        guard let userLocation = userLocation else { return "" }
        let itemLocation = CLLocation(
            latitude: item.placemark.coordinate.latitude,
            longitude: item.placemark.coordinate.longitude
        )
        let distance = userLocation.distance(from: itemLocation)
        let formatter = MKDistanceFormatter()
        formatter.unitStyle = .abbreviated
        return formatter.string(fromDistance: distance)
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                // Location pin icon
                Image(systemName: "mappin.circle.fill")
                    .font(.title2)
                    .foregroundColor(.red)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name ?? "Unknown Location")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    HStack {
                        if let address = item.placemark.title {
                            Text(address)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        
                        if !distance.isEmpty {
                            Spacer()
                            Text(distance)
                                .font(.caption)
                                .foregroundColor(.blue)
                                .fontWeight(.medium)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SearchCompletionRow: View {
    let completion: MKLocalSearchCompletion
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                // Search icon or location type icon
                Image(systemName: iconForCompletion(completion))
                    .font(.title2)
                    .foregroundColor(.gray)
                    .frame(width: 25)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(completion.title)
                        .font(.body)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    if !completion.subtitle.isEmpty {
                        Text(completion.subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Arrow to fill in search
                Image(systemName: "arrow.up.left")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func iconForCompletion(_ completion: MKLocalSearchCompletion) -> String {
        // Return appropriate icon based on completion type
        let title = completion.title.lowercased()
        
        if title.contains("restaurant") || title.contains("food") {
            return "fork.knife"
        } else if title.contains("gas") || title.contains("fuel") {
            return "fuelpump"
        } else if title.contains("hotel") || title.contains("motel") {
            return "bed.double"
        } else if title.contains("hospital") {
            return "cross"
        } else if title.contains("store") || title.contains("shop") {
            return "bag"
        } else {
            return "magnifyingglass"
        }
    }
}

// MARK: - Search Completer Manager
class SearchCompleterManager: NSObject, ObservableObject {
    @Published var completions: [MKLocalSearchCompletion] = []
    
    private let completer = MKLocalSearchCompleter()
    
    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = .address
    }
    
    func updateQuery(_ query: String) {
        completer.queryFragment = query
    }
    
    func setUserLocation(_ location: CLLocation) {
        let region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: 50000,
            longitudinalMeters: 50000
        )
        completer.region = region
    }
}

extension SearchCompleterManager: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        DispatchQueue.main.async {
            self.completions = completer.results
        }
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Search completer error: \(error)")
    }
}
