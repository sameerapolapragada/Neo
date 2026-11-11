import XCTest
@testable import Neo

final class AuthCallbackTests: XCTestCase {
    func testCallbackMatchesTheAppScheme() {
        let callback = URL(string: "com.neo.petcompanion://auth/callback?code=abc")!
        XCTAssertTrue(AuthCallback.matches(callback))
        XCTAssertFalse(AuthCallback.matches(URL(string: "http://localhost:3000")!))
        XCTAssertEqual(AuthCallback.url.scheme, "com.neo.petcompanion")
    }

    func testRecoveryTypeIsRecognizedWithoutLoggingTheToken() {
        let query = URL(string: "com.neo.petcompanion://auth/callback?code=secret-code&type=recovery")!
        let fragment = URL(string: "com.neo.petcompanion://auth/callback#access_token=secret&type=recovery")!
        let signup = URL(string: "com.neo.petcompanion://auth/callback?code=secret-code&type=signup")!
        XCTAssertTrue(AuthCallback.isRecovery(query))
        XCTAssertTrue(AuthCallback.isRecovery(fragment))
        XCTAssertFalse(AuthCallback.isRecovery(signup))
    }

    func testPasswordChoiceRequiresAMatchAndAMinimumLength() {
        XCTAssertNotNil(AuthFormValidation.passwordChoiceError("short", confirmation: "short"))
        XCTAssertNotNil(AuthFormValidation.passwordChoiceError("longenough", confirmation: "different"))
        XCTAssertNil(AuthFormValidation.passwordChoiceError("longenough", confirmation: "longenough"))
    }

    func testRecoveryErrorsStayNeutralAndDoNotEchoTheAddress() throws {
        struct Stub: Error, CustomStringConvertible {
            var description: String
        }
        let address = "private@example.com"
        let rateLimited = Stub(description: "over_email_send_rate_limit for \(address)")
        let missing = Stub(description: "user not found \(address)")
        XCTAssertEqual(AuthErrorMessage.recoveryMessage(for: rateLimited), AuthErrorMessage.rateLimit)
        XCTAssertEqual(AuthErrorMessage.recoveryMessage(for: missing), AuthErrorMessage.neutralRecovery)
        XCTAssertFalse(AuthErrorMessage.rateLimit.contains(address))
        XCTAssertFalse(AuthErrorMessage.neutralRecovery.contains(address))
        XCTAssertFalse(AuthErrorMessage.expiredLink.contains("secret"))
    }
}
