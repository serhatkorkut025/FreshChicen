//
//  AddProduct.swift
//  FreshChiken
//
//  Created by D K on 07.04.2025.
//

import SwiftUI


import SwiftUI
import RealmSwift


struct AddProductView: View {
    
    enum AddMode: String, CaseIterable {
        case auto = "Auto"
        case manual = "Manual"
    }
    
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedMode: AddMode = .auto
    @State private var productName: String = ""
    @State private var notesString: String = ""
    @State private var selectedDate: Date = Date()
    
    @State private var selectedImage: UIImage?
    @State private var productInfo: ProductInfo?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showActionSheet = false
    @State private var showGalleryPicker = false
    @State private var showCameraPicker = false
    
    private let geminiService = GeminiService()
    
    private var realm: Realm? {
        try? Realm() 
    }
    
    var completion: () -> ()
    
    let backgroundColor = Color(red: 0.2, green: 0.2, blue: 0.35)
    let buttonOrange = Color.orange
    let buttonYellow = Color.orange.opacity(0.7)
    let softBlue = Color(red: 0.4, green: 0.4, blue: 0.6)
    let customOrange = Color.orange
    
    let displayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        return formatter
    }()
    
    let geminiDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
    
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image("back")
                    .resizable()
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image("backIcon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40)
                        }
                        
                        Text("Add product")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    HStack(spacing: 0) {
                        ForEach(AddMode.allCases, id: \.self) { mode in
                            Button {
                                selectedMode = mode
                                resetInputFields()
                                selectedImage = nil
                                productInfo = nil
                                errorMessage = nil
                            } label: {
                                Text(mode.rawValue)
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(selectedMode == mode ? buttonOrange : buttonYellow)
                                    .foregroundColor(.white)
                                    .shadow(color: selectedMode == mode ? .black.opacity(0.4) : .clear , radius: selectedMode == mode ? 5 : 0, y: 3)
                            }
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal)
                    .padding(.top)
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            
                            ZStack {
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(backgroundColor.opacity(0.8))
                                    .frame(height: 180)
                                    .shadow(radius: 10)
                                
                                if let image = selectedImage {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 180)
                                        .clipShape(RoundedRectangle(cornerRadius: 15))
                                } else {
                                    Image(systemName: "camera")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 60, height: 60)
                                        .foregroundColor(.white.opacity(0.9))
                                }
                                
                                if isLoading {
                                    ProgressView()
                                        .scaleEffect(1.5)
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        .background(Color.black.opacity(0.3))
                                        .clipShape(RoundedRectangle(cornerRadius: 15))
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top)
                            .onTapGesture {
                                hideKeyboard()
                                showActionSheet = true
                            }
                            
                            if let errorMsg = errorMessage {
                                Text("Ошибка: \(errorMsg)")
                                    .foregroundColor(.red)
                                    .padding(.horizontal)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                            
                            
                            if selectedMode == .manual || (selectedMode == .auto && productInfo != nil && !isLoading) {
                                VStack(alignment: .leading, spacing: 15) {
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text("Name")
                                            .foregroundColor(.white.opacity(0.8))
                                            .padding(.leading, 5)
                                        TextField("Type here...", text: $productName)
                                            .textFieldStyle(PlainTextFieldStyle())
                                            .padding(12)
                                            .background(softBlue.opacity(0.7))
                                            .foregroundColor(.white)
                                            .cornerRadius(10)
                                            .disabled(selectedMode == .auto && isLoading)
                                    }
                                    
                                    
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text("Expiration Date")
                                            .foregroundColor(.white.opacity(0.8))
                                            .padding(.leading, 5)
                                        
                                        ZStack {
                                            HStack {
                                                Text(selectedDate, formatter: displayDateFormatter)
                                                    .padding(.leading)
                                                Spacer()
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(softBlue.opacity(0.7))
                                            .foregroundColor(.white)
                                            .cornerRadius(10)
                                            
                                            
                                            DatePicker(
                                                "",
                                                selection: $selectedDate,
                                                displayedComponents: [.date]
                                            )
                                            .frame(width: size().width - 40, alignment: .leading)
                                            .datePickerStyle(.compact)
                                            .labelsHidden()
                                            .accentColor(customOrange)
                                            .opacity(0.015)
                                            .disabled(selectedMode == .auto && isLoading)
                                            .preferredColorScheme(.dark)
                                        }
                                    }
                                    
                                    
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text("Notes")
                                            .foregroundColor(.white.opacity(0.8))
                                            .padding(.leading, 5)
                                        TextField("Type here...", text: $notesString)
                                            .textFieldStyle(PlainTextFieldStyle())
                                            .padding(12)
                                            .background(softBlue.opacity(0.7))
                                            .foregroundColor(.white)
                                            .cornerRadius(10)
                                            .disabled(selectedMode == .auto && isLoading)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.bottom, 100)
                    }
                    
                    Spacer()
                    
                    RoundedButton(width: 200, height: 50, text: "Save") {
                        print("Save Tapped")
                        print("Mode: \(selectedMode.rawValue)")
                        print("Name: \(productName)")
                        print("Date: \(displayDateFormatter.string(from: selectedDate))")
                        print("Notes: \(notesString)")
                        print("Image selected: \(selectedImage != nil)")
                        saveProduct()
                        completion()
                        dismiss()
                    }
                    .padding(.bottom, 30)
                    .disabled(productName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                    .opacity((productName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading) ? 0.6 : 1.0)
                    
                }
            }
            .actionSheet(isPresented: $showActionSheet) {
                ActionSheet(
                    title: Text("Select source"),
                    message: Text("Where can I get a product image?"),
                    buttons: [
                        .default(Text("Camera")) {
                            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                                showCameraPicker = true
                            } else {
                                errorMessage = "Camera is not available."
                            }
                        },
                        .default(Text("Gallery")) {
                            showGalleryPicker = true
                        },
                        .cancel(Text("Cancel"))
                    ]
                )
            }
            .sheet(isPresented: $showGalleryPicker) {
                ImagePicker(selectedImage: $selectedImage)
                    .ignoresSafeArea()
            }
            .fullScreenCover(isPresented: $showCameraPicker) {
                
                CameraPicker(selectedImage: $selectedImage)
                    .ignoresSafeArea()
            }
            .onChange(of: selectedImage) { newImage in
                if selectedMode == .auto, let image = newImage {
                    productInfo = nil
                    errorMessage = nil
                    analyze(image: image)
                } else if selectedMode == .manual {
                    productInfo = nil
                    errorMessage = nil
                }
            }
            
        }
    }
    
    
    private func saveProduct() {
        guard let realm = realm else {
            errorMessage = "Error: Unable to access the database."
            return
        }
        
        let trimmedName = productName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            errorMessage = "Error: Product name cannot be empty."
            return
        }
        
        var imageData: Data? = nil
        if let img = selectedImage {
            imageData = img.jpegData(compressionQuality: 0.7)
        }
        
        let newProduct = StoredProduct(
            name: trimmedName,
            expirationDate: selectedDate,
            imageData: imageData
        )
        let productIdToSchedule = newProduct.id
        
        do {
            let productNameToSchedule = newProduct.name
            let expirationDateToSchedule = newProduct.expirationDate
            
            try realm.write {
                realm.add(newProduct)
                print("Product \(newProduct.name) saved successfully with ID: \(newProduct.id)")
            }
            
            NotificationManager.shared.scheduleNotification(
                productID: productIdToSchedule,
                productName: productNameToSchedule,
                expirationDate: expirationDateToSchedule
            )
            
            completion()
            dismiss()
            
        } catch {
            print("Error saving product to Realm: \(error.localizedDescription)")
            errorMessage = "Error: \(error.localizedDescription)"
        }
    }

        

    private func analyze(image: UIImage) {
        print("Starting analysis...")
        isLoading = true
        errorMessage = nil
        productInfo = nil

        Task {
            let result = await geminiService.analyzeImage(image)

            await MainActor.run {
                isLoading = false
                switch result {
                case .success(let info):
                    print("Analysis successful: \(info)")
                    productInfo = info
                    productName = info.productName

                    if let dateStr = info.expirationDate,
                       let parsedDate = geminiDateFormatter.date(from: dateStr) {
                        selectedDate = parsedDate
                        print("Date parsed successfully: \(parsedDate)")
                    } else {
                        selectedDate = Date()
                        print("Failed to parse date or date was nil. Defaulting to today.")
                        if info.expirationDate != nil {
                           errorMessage = "Error: \(info.expirationDate!)"
                        }
                    }
                     errorMessage = nil

                case .failure(let error):
                    print("Analysis failed: \(error)")
                    errorMessage = error.localizedDescription
                    productInfo = nil
                }
            }
        }
    }

    private func resetInputFields() {
        productName = ""
        selectedDate = Date()
        notesString = ""
    }

    private func hideKeyboard() {
           UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
       }

}


struct AddProductView_Previews: PreviewProvider {
    static var previews: some View {
        AddProductView(completion: { print("Preview Completion") })
             .preferredColorScheme(.dark) 
    }
}
