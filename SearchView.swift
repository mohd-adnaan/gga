//
//  SearchView.swift
//  GloveGuide
//
//  Created by Mohammad Adnaan on 2025-10-26.
//

import SwiftUI
import MapKit

struct SearchView: View {
    @ObservedObject var coordinator: AppCoordinator
    @Binding var searchText: String
    @Binding var searchResults: [MKMapItem]
    @Binding var isSearching: Bool
    @Environment(\.presentationMode) var presentationMode
    
    @State private var searchCompleter = MKLocalSearchCompleter()
    @State private var searchCompletions: [MKLocalSearchCompletion] = []
    
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
                        SearchResultRow(item: item) {
                            selectDestination(item)
                        }
                    }
                } else if !searchCompletions.isEmpty {
                    // Search Completions
                    List(searchCompletions, id: \.self) { completion in
                        SearchCompletionRow(completion: completion) {
                            searchText = completion.title
                            performSearch()
                        }
                    }
                } else {
                    // Empty state
                    VStack {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("Start typing to search for destinations")
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
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
            setupSearchCompleter()
        }
        .onChange(of: searchText) { newValue in
            searchCompleter.queryFragment = newValue
            if newValue.isEmpty {
                searchResults = []
                searchCompletions = []
            }
        }
    }
    
    private func setupSearchCompleter() {
        searchCompleter.delegate = SearchCompleterDelegate { completions in
            self.searchCompletions = completions
        }
        
        // Set search region based on current location
        if let location = coordinator.navigationManager.currentLocation {
            searchCompleter.region = MKCoordinateRegion(
                center: location.coordinate,
                latitudinalMeters: 10000,
                longitudinalMeters: 10000
            )
        }
    }
    
    private func performSearch() {
        guard !searchText.isEmpty else { return }
        
        isSearching = true
        searchCompletions = []
        
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
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name ?? "Unknown Location")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    if let address = item.placemark.title {
                        Text(address)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
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
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(completion.title)
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    if !completion.subtitle.isEmpty {
                        Text(completion.subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

class SearchCompleterDelegate: NSObject, MKLocalSearchCompleterDelegate {
    let onUpdate: ([MKLocalSearchCompletion]) -> Void
    
    init(onUpdate: @escaping ([MKLocalSearchCompletion]) -> Void) {
        self.onUpdate = onUpdate
    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        onUpdate(completer.results)
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Search completer error: \(error)")
    }
}