import Foundation
import Observation

#if !FAL_ENABLE_MLX || targetEnvironment(simulator)
/// Shares the original view-facing API without linking or initializing MLX.
/// An unavailable backend returns no result; it never fabricates an analysis.
@Observable
@MainActor
final class MLXAdditiveIdentifier {
    var isLoading = false
    var isModelLoaded = false
    var errorMessage: String?
    var modelInfo: String
    var stat = ""
    var currentStage = ""

    init() {
        #if targetEnvironment(simulator)
        modelInfo = "On-device AI requires supported physical hardware."
        #else
        modelInfo = "On-device AI is not configured in this build."
        #endif
        errorMessage = modelInfo
    }

    func identifyAdditives(_ ingredientText: String) async -> [String]? {
        errorMessage = modelInfo
        return nil
    }

    func generateAdditiveExplanations(
        knowledge: [AdditiveKnowledgeManager.AdditiveKnowledge],
        foodInfo: String,
        originalIngredients: String,
        streamingUpdate: @escaping @MainActor @Sendable (String) -> Void
    ) async -> String? {
        errorMessage = modelInfo
        return nil
    }

    func cancelGeneration() {}
}
#endif
