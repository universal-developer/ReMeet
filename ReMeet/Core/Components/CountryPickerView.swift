//
//  CountryPickerView.swift
//  ReMeet
//
//  Created by Artush on 11/03/2025.
//

import SwiftUI

struct CountryPickerView: View {
    @Binding var selectedCountry: Country
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @State private var searchText = ""

    var body: some View {
        NavigationView {
            ZStack {

                VStack {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(searchIconColor)

                        TextField("Search", text: $searchText)
                            .foregroundColor(textColor)
                    }
                    .padding(10)
                    .background(searchBarBackground)
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .padding(.top, 10)

                    // Country list
                    List {
                        ForEach(filteredCountries) { country in
                            Button(action: {
                                selectedCountry = country
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                HStack {
                                    Text(CountryManager.shared.countryFlag(country.code))
                                    Text(country.name)
                                        .foregroundColor(textColor)

                                    Spacer()

                                    Text("+" + country.phoneCode)
                                        .foregroundColor(.gray)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                    .background(backgroundColor)
                }
            }
            .navigationBarTitle("", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(.blue)
            )
        }
    }

    private var filteredCountries: [Country] {
        if searchText.isEmpty {
            return CountryManager.shared.allCountries
        } else {
            return CountryManager.shared.allCountries.filter { country in
                country.name.lowercased().contains(searchText.lowercased()) ||
                country.phoneCode.contains(searchText)
            }
        }
    }

    // MARK: - Adaptive Colors
    private var backgroundColor: Color {
        colorScheme == .dark ? Color.black : Color.white
    }

    private var textColor: Color {
        colorScheme == .dark ? Color.white : Color.black
    }

    private var searchBarBackground: Color {
        colorScheme == .dark ? Color.white.opacity(0.1) : Color(UIColor.systemGray6)
    }

    private var searchIconColor: Color {
        colorScheme == .dark ? .gray.opacity(0.7) : .gray
    }
}
