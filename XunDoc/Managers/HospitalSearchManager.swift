//
//  HospitalSearchManager.swift
//  XunDoc
//
//  医院搜索管理器 - 基于定位搜索附近医院
//

import Foundation
import CoreLocation
import MapKit

class HospitalSearchManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = HospitalSearchManager()
    
    @Published var nearbyHospitals: [Hospital] = []
    @Published var isSearching = false
    @Published var errorMessage: String?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    private let locationManager = CLLocationManager()
    private var currentLocation: CLLocation?
    
    struct Hospital: Identifiable {
        let id = UUID()
        let name: String
        let address: String
        let distance: Double // 距离（米）
        let coordinate: CLLocationCoordinate2D
        let phoneNumber: String?
        
        var distanceText: String {
            if distance < 1000 {
                return String(format: "%.0f米", distance)
            } else {
                return String(format: "%.1f公里", distance / 1000)
            }
        }
    }
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = locationManager.authorizationStatus
    }
    
    // MARK: - 请求定位权限
    
    func requestLocationPermission() {
        print("📍 请求定位权限...")
        locationManager.requestWhenInUseAuthorization()
    }
    
    // MARK: - 搜索附近医院
    
    func searchNearbyHospitals(radius: Double = 5000) {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            errorMessage = "请在设置中允许访问您的位置信息"
            print("❌ 未授权定位权限")
            return
        }
        
        isSearching = true
        errorMessage = nil
        
        print("🔍 开始搜索附近医院...")
        
        // 获取当前位置
        locationManager.requestLocation()
    }
    
    // MARK: - 使用MapKit搜索
    
    private func searchHospitalsUsingMapKit(at location: CLLocation, radius: Double) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "医院"
        
        // 设置搜索区域
        let region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: radius * 2,
            longitudinalMeters: radius * 2
        )
        request.region = region
        
        let search = MKLocalSearch(request: request)
        search.start { [weak self] response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isSearching = false
                
                if let error = error {
                    self.errorMessage = "搜索失败: \(error.localizedDescription)"
                    print("❌ 搜索医院失败: \(error.localizedDescription)")
                    return
                }
                
                guard let response = response else {
                    self.errorMessage = "未找到附近的医院"
                    print("⚠️ 未找到附近的医院")
                    return
                }
                
                // 转换为Hospital对象
                var hospitals: [Hospital] = []
                
                for item in response.mapItems {
                    let itemLocation = CLLocation(
                        latitude: item.placemark.coordinate.latitude,
                        longitude: item.placemark.coordinate.longitude
                    )
                    let distance = location.distance(from: itemLocation)
                    
                    // 只包含在指定半径内的医院
                    if distance <= radius {
                        let hospital = Hospital(
                            name: item.name ?? "未知医院",
                            address: self.formatAddress(item.placemark),
                            distance: distance,
                            coordinate: item.placemark.coordinate,
                            phoneNumber: item.phoneNumber
                        )
                        hospitals.append(hospital)
                    }
                }
                
                // 按距离排序
                hospitals.sort { $0.distance < $1.distance }
                
                self.nearbyHospitals = hospitals
                
                print("✅ 找到 \(hospitals.count) 家附近的医院")
                for (index, hospital) in hospitals.prefix(5).enumerated() {
                    print("  \(index + 1). \(hospital.name) - \(hospital.distanceText)")
                }
            }
        }
    }
    
    // MARK: - 格式化地址
    
    private func formatAddress(_ placemark: MKPlacemark) -> String {
        var components: [String] = []
        
        if let thoroughfare = placemark.thoroughfare {
            components.append(thoroughfare)
        }
        if let subThoroughfare = placemark.subThoroughfare {
            components.append(subThoroughfare)
        }
        if let locality = placemark.locality {
            components.append(locality)
        }
        if let subLocality = placemark.subLocality {
            components.append(subLocality)
        }
        
        return components.joined(separator: " ")
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        currentLocation = location
        print("📍 获取到当前位置: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        
        // 搜索附近医院
        searchHospitalsUsingMapKit(at: location, radius: 5000)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.isSearching = false
            self.errorMessage = "定位失败，请检查定位服务是否开启"
            print("❌ 定位失败: \(error.localizedDescription)")
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
            print("📍 定位权限状态变更: \(self.authorizationStatus.rawValue)")
        }
    }
}

