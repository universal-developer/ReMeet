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
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField("Search", text: $searchText)
                            .foregroundColor(.white)
                    }
                    .padding(10)
                    .background(Color(UIColor.systemGray6))
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
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text("+" + country.phoneCode)
                                        .foregroundColor(.gray)
                                }
                                .padding(.vertical, 4)
                            }
                            .listRowBackground(Color.black)
                        }
                    }
                    .listStyle(PlainListStyle())
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
        .preferredColorScheme(.dark)
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
}
