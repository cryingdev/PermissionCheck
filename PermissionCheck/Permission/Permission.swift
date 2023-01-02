//
//  Permission.swift
//  PermissionCheck
//
//  Created by UMCios on 2023/01/02.
//

import Foundation

//MARK: - PermissionAgent

/**
 [권한] 타입
 1. 시스템 권한이 추가되는 경우 아래 enum 값에 추가하고
 2. 시스템 권한요청 extension BaseViewModel에 해당 권한과 관련된 request를 추가한다.
 */
struct Permission {
    
    var type: PermissionType
    var requirement: Requirement
    
    init(_ type: PermissionType, _ requirement: Requirement) {
        self.type = type
        self.requirement = requirement
    }
    
    enum PermissionType {
        /// 사진 라이브러리
        case photo
        /// 카메라
        case camera
        /// 마이크
        case audio
        /// 위치
        case location
    }
    /**
     [권한] 권한 상태
     */
    enum Status {
        /// 허용된 상태
        case authorized
        /// 제한된 상태
        case limited
        /// 거부된 상태
        case denied
        /// 미정
        case notDetermined
    }
    /**
     필수인자 정의
     */
    enum Requirement {
        /// 필수
        case required
        /// 옵셔널
        case optional
    }
}
