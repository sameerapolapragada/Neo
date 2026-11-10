import Foundation

struct ProfileEditingDependencies: Sendable {
    let pets: any PetRepository
    let uploader: any MediaUploading
    let media: any MediaURLResolving
    let moments: any MomentRepository
    let memories: any MemoryRepository
    var momentDeletion: (any MomentDeleting)? = nil
    var petDeletion: (any PetDeleting)? = nil
    var storageCleanup: (any StorageCleaning)? = nil
}
