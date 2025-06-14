//======================================================================
// MARK: - Restaurant.swift（SNS版）
// Path: foodai/Core/DataModels/Restaurant.swift
//======================================================================
import Foundation

struct Restaurant: Identifiable, Codable {
    let id: String
    let name: String
    let area: String?
    let address: String?
    let latitude: Double?
    let longitude: Double?
    let googlePlaceId: String?
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id, name, area, address, latitude, longitude
        case googlePlaceId = "google_place_id"
        case createdAt = "created_at"
    }
}

