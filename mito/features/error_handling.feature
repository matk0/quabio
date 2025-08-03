Feature: Error Handling and Edge Cases
  As a user of Miťo
  I want the application to handle errors gracefully
  So that I have a reliable experience even when things go wrong

  Background:
    Given the application is running

  @api_failure
  Scenario: Anonymous user - FastAPI backend completely down
    Given the FastAPI backend is completely unavailable
    And I am on the homepage as an anonymous user
    When I send a message "Test backend down"
    Then I should see my message in the chat
    And I should see a helpful error message in Slovak
    And the error message should mention that the service is temporarily unavailable
    And the error message should suggest registering to save the question
    And the application should remain functional for future attempts

  @api_failure
  Scenario: Authenticated user - FastAPI backend completely down
    Given the FastAPI backend is completely unavailable
    And I am signed in as a regular user
    When I send a message "Test backend down"
    Then I should see my message in the chat
    And I should see a professional error message
    And the error message should not mention registration
    And my message should still be saved to the database
    And I should be able to send more messages

  @api_failure
  Scenario: Admin user - Compare endpoint returns 500 error
    Given the FastAPI compare endpoint returns a server error
    And I am signed in as an admin user
    When I send a message "Test compare error"
    Then I should see my message in the chat
    And I should see an error message about comparison failure
    And the error message should be professional and helpful
    And I should not see broken comparison containers
    And I should still be able to send more messages

  @api_failure
  Scenario: Anonymous user - FastAPI returns malformed JSON
    Given the FastAPI backend returns invalid JSON
    And I am on the homepage as an anonymous user
    When I send a message "Test malformed response"
    Then I should see my message in the chat
    And I should see a graceful error message
    And the application should not crash or show JavaScript errors
    And I should be able to continue using the chat

  @api_failure
  Scenario: API timeout handling
    Given the FastAPI backend is very slow (timeout scenario)
    And I am signed in as a regular user
    When I send a message "Test timeout"
    Then I should see my message in the chat
    And after waiting for the timeout period
    And I should see a timeout error message
    And the error should be user-friendly
    And the interface should remain responsive

  Scenario: Validation errors - empty message submission
    Given I am on the homepage as an anonymous user
    When I try to submit an empty message
    Then the message should not be sent
    And I should not see any error messages (silent validation)
    And the form should remain ready for input
    And no API calls should be made

  Scenario: Validation errors - whitespace-only message
    Given I am signed in as a regular user
    When I type only spaces and tabs in the message field
    And I try to send the message
    Then the message should not be sent
    And I should not see whitespace in the chat
    And the form should be cleared appropriately

  Scenario: Very long message handling
    Given I am signed in as a regular user
    When I send a message with 10000 characters
    Then the message should be accepted
    And it should be properly displayed in the chat
    And the backend should handle it appropriately
    And the UI should not break due to length

  Scenario: Special characters and emoji handling
    Given I am on the homepage as an anonymous user
    When I send a message with special characters "Test 🧬💊⚗️ čšžťň ČŠŽŤŇ @#$%^&*()"
    Then the message should display correctly
    And special characters should be preserved
    And emojis should render properly
    And the response should handle the characters correctly

  Scenario: Concurrent session handling
    Given I am signed in as a regular user in one browser
    When I sign in with the same account in another browser
    Then both sessions should work independently
    And I should not see interference between sessions
    And each session should maintain its own state

  Scenario: Session expiry handling
    Given I am signed in as a regular user
    When my session expires
    And I try to send a message
    Then I should be redirected to the sign in page
    And I should see a message about session expiry
    And I should be able to sign in again
    And my chat history should be preserved

  Scenario: Database connection errors
    Given there are database connectivity issues
    When I try to access the application
    Then I should see a graceful error page
    And the error should not expose technical details
    And I should be given guidance on what to do
    And the navigation should remain functional

  Scenario: Non-existent chat access
    Given I am signed in as a regular user
    When I try to access a chat that doesn't exist
    Then I should see "Chat nenájdený" message
    And I should be redirected to the homepage
    And the error should be displayed as a flash message
    And I should be able to continue using the application

  Scenario: Unauthorized chat access
    Given I am signed in as a regular user
    And another user has a private chat
    When I try to access that other user's chat via URL manipulation
    Then I should see "Chat nenájdený" message
    And I should be redirected appropriately
    And I should not see any of the other user's data

  Scenario: Anonymous user accessing authenticated routes
    When I try to access the chats index page as an anonymous user
    Then I should be redirected to the sign in page
    And I should see "Musíte sa prihlásiť alebo zaregistrovať"
    And the redirect should preserve the intended destination
    And I should be able to continue after signing in

  Scenario: JavaScript disabled fallback
    Given JavaScript is disabled in the browser
    When I use the chat interface
    Then basic functionality should still work
    And form submissions should work via standard HTTP
    And I should receive appropriate feedback
    And the experience should degrade gracefully

  Scenario: Slow network conditions
    Given the network connection is slow
    When I send a message
    Then I should see immediate feedback that the message was sent
    And there should be appropriate loading indicators
    And the interface should remain responsive during waits
    And I should eventually receive the response

  Scenario: Browser back/forward button handling
    Given I am signed in as a regular user with multiple chats
    When I navigate between chats using the interface
    And I use the browser back button
    Then I should return to the previous chat
    And the chat should load correctly
    And the browser history should work intuitively

  Scenario: Page refresh during message sending
    Given I am sending a message
    When I refresh the page before receiving a response
    Then the page should reload cleanly
    And my sent message should be preserved
    And I should be able to continue the conversation
    And there should be no duplicate messages

  @javascript
  Scenario: Network connection lost during usage
    Given I am using the chat interface
    When the network connection is lost
    And I try to send a message
    Then I should see an appropriate error message
    And the message should queue for retry when connection returns
    And the interface should handle reconnection gracefully

  Scenario: Malicious input handling
    Given I am on the homepage as an anonymous user
    When I try to send a message with HTML/script tags
    Then the content should be properly sanitized
    And no scripts should execute
    And the message should display safely
    And the application should remain secure

  Scenario: File upload attempts (should be blocked)
    Given I am using the chat interface
    When I try to paste or drag files into the message field
    Then file uploads should not be accepted
    And I should see appropriate feedback
    And the interface should guide me to text-only input

  Scenario: Extremely high message frequency
    Given I am signed in as a regular user
    When I try to send many messages very quickly
    Then the application should handle the load appropriately
    And there should be reasonable rate limiting if needed
    And the user experience should remain smooth
    And no messages should be lost

  Scenario: Browser compatibility issues
    Given I am using an older browser
    When I access the application
    Then I should see a browser compatibility message if needed
    And basic functionality should still work
    And I should be guided to update if necessary

  Scenario: Memory leak prevention during long sessions
    Given I have been using the application for an extended time
    And I have navigated through many chats
    When I continue using the interface
    Then the application should remain responsive
    And memory usage should not grow excessively
    And performance should remain consistent

  Scenario: Recovery from temporary errors
    Given I encountered a temporary API error
    When the backend service recovers
    And I try to send another message
    Then the application should work normally again
    And there should be no lingering error states
    And the user experience should be seamless