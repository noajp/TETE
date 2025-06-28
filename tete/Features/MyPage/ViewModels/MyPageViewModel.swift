//======================================================================
// MARK: - MyPageViewModel
// Purpose: Manages the user's profile page state and operations
// Dependencies: UserRepository, AuthManager
//======================================================================
import SwiftUI
import Combine
import PhotosUI

/// ViewModel for the user's profile page
/// Handles profile data loading, updates, and post management
@MainActor
final class MyPageViewModel: BaseViewModelClass {
    // MARK: - Published Properties
    
    /// Current user's profile
    @Published var userProfile: UserProfile?
    
    /// Posts saved by the user
    @Published var savedPosts: [Post] = []
    
    /// Posts created by the user
    @Published var userPosts: [Post] = []
    
    /// Statistics
    @Published var postsCount: Int = 0
    @Published var followersCount: Int = 0
    @Published var followingCount: Int = 0
    
    // MARK: - Dependencies
    
    private let userRepository: UserRepositoryProtocol
    private let authManager: any AuthManagerProtocol
    
    // MARK: - Private Properties
    
    private var hasLoadedInitially = false
    private var currentUserId: String? {
        authManager.currentUser?.id
    }
    
    // MARK: - Initialization
    
    init(
        userRepository: UserRepositoryProtocol? = nil,
        authManager: (any AuthManagerProtocol)? = nil
    ) {
        self.userRepository = userRepository ?? UserRepository()
        self.authManager = authManager ?? (DependencyContainer.shared.resolve((any AuthManagerProtocol).self) ?? AuthManager.shared)
        super.init()
        
        Task {
            await loadUserDataIfNeeded()
        }
    }
    
    // MARK: - Public Methods
    
    /// Loads user data only if not already loaded
    func loadUserDataIfNeeded() async {
        guard !hasLoadedInitially else { return }
        await loadUserData()
    }
    
    /// Loads all user data including profile, posts, and statistics
    func loadUserData() async {
        guard let userId = currentUserId else {
            handleError(ViewModelError.unauthorized)
            return
        }
        
        showLoading()
        
        do {
            // Load profile
            userProfile = try await userRepository.fetchUserProfile(userId: userId)
            
            // Load posts
            userPosts = try await userRepository.fetchUserPosts(userId: userId)
            postsCount = userPosts.count
            print("🟢 MyPageViewModel: Loaded \(postsCount) posts for user \(userId)")
            
            // Load statistics
            followersCount = try await userRepository.fetchFollowersCount(userId: userId)
            followingCount = try await userRepository.fetchFollowingCount(userId: userId)
            
            hasLoadedInitially = true
            hideLoading()
            Logger.shared.info("User data loaded successfully")
            
        } catch {
            handleError(error)
        }
    }
    
    /// Updates user profile information
    func updateProfile(username: String, displayName: String, bio: String) async {
        guard var profile = userProfile else {
            handleError(ViewModelError.notFound("Profile"))
            return
        }
        
        showLoading()
        
        do {
            // Update local model
            profile.username = username
            profile.displayName = displayName
            profile.bio = bio
            
            // Update remote
            try await userRepository.updateUserProfile(profile)
            
            // Reload data to ensure consistency
            await loadUserData()
            
            Logger.shared.info("Profile updated successfully")
            
        } catch {
            handleError(error)
        }
    }
    
    /// Updates user profile photo
    func updateProfilePhoto(item: PhotosPickerItem?) async {
        guard let item = item,
              let userId = currentUserId else {
            return
        }
        
        showLoading()
        
        do {
            // Load image data
            guard let data = try await item.loadTransferable(type: Data.self) else {
                throw ViewModelError.fileSystem("Failed to load image data")
            }
            
            // Upload and update
            let newAvatarUrl = try await userRepository.updateProfilePhoto(
                userId: userId,
                imageData: data
            )
            
            // Update local profile
            userProfile?.avatarUrl = newAvatarUrl
            
            hideLoading()
            Logger.shared.info("Profile photo updated successfully")
            
        } catch {
            handleError(error)
        }
    }
    
    // MARK: - Navigation Methods
    func navigateToSavedPosts() {
        // TODO: 保存済み投稿画面への遷移
    }
    
    func navigateToFollowers() {
        // TODO: フォロワー一覧画面への遷移
    }
    
    func navigateToFollowing() {
        // TODO: フォロー中一覧画面への遷移
    }
    
    func navigateToHelp() {
        // TODO: ヘルプ画面への遷移
    }
    
    // MARK: - Refresh
    
    /// Refreshes all user data
    func refresh() async {
        await loadUserData()
    }
}
