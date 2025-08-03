Feature: UI Interactions and User Experience
  As a user of Miťo
  I want smooth and intuitive UI interactions
  So that I can efficiently communicate with the health assistant

  Background:
    Given the application is running

  @javascript
  Scenario: Keyboard shortcuts work in message input
    Given I am on the homepage as an anonymous user
    When I focus on the message input field
    And I type "Prvý riadok otázky"
    And I press Enter
    Then my message should be sent immediately
    And I should see "Prvý riadok otázky" in the chat
    And the input field should be cleared

  @javascript
  Scenario: Shift+Enter creates new lines without sending
    Given I am signed in as a regular user
    When I focus on the message input field
    And I type "Prvý riadok"
    And I press Shift+Enter
    And I type "Druhý riadok"
    And I press Shift+Enter
    And I type "Tretí riadok"
    Then I should see all three lines in the textarea
    And the message should not be sent yet
    When I press Enter
    Then the multiline message should be sent
    And I should see all three lines in the chat message

  @javascript
  Scenario: Textarea auto-resizes with content
    Given I am on the homepage as an anonymous user
    When I focus on the message input field
    And I type a short message
    Then the textarea should have minimum height
    When I type a very long message that spans multiple lines
    Then the textarea should grow to accommodate the content
    And the textarea should not exceed maximum height
    When I clear the content
    Then the textarea should return to minimum height

  @javascript
  Scenario: Textarea shows scrollbar when content exceeds maximum height
    Given I am signed in as a regular user
    When I type an extremely long message that exceeds the maximum textarea height
    Then the textarea should show a scrollbar
    And the textarea should remain at maximum height
    And I should be able to scroll within the textarea

  @javascript
  Scenario: Enter key validation - no empty message submission
    Given I am on the homepage as an anonymous user
    When I focus on the message input field
    And I press Enter without typing anything
    Then no message should be sent
    And no API calls should be made
    And the input field should remain focused
    When I type only spaces and press Enter
    Then no message should be sent
    And the input field should be cleared

  Scenario: Flash messages appear and auto-dismiss
    When I perform an action that triggers a success message
    Then I should see a flash message slide in from the right
    And the flash message should have appropriate styling
    And the flash message should show a progress bar
    And after 4 seconds the flash message should slide out automatically

  @javascript
  Scenario: Flash messages can be manually dismissed
    When I trigger a flash message
    Then I should see the flash message with a close button
    When I click the close button
    Then the flash message should slide out immediately
    And the message should be removed from the DOM

  @javascript
  Scenario: Multiple flash messages stack properly
    When I trigger multiple flash messages in succession
    Then each message should appear in its own container
    And messages should be stacked vertically
    And each message should auto-dismiss independently
    And the stack should not overlap with other UI elements

  @javascript
  Scenario: Flash message types have different styling
    When I trigger a success notification
    Then I should see a green-themed flash message
    And I should see a success icon
    When I trigger an error notification
    Then I should see a red-themed flash message
    And I should see an error icon

  @javascript
  Scenario: Real-time message updates via Turbo Streams
    Given I am signed in as a regular user
    When I send a message using the form
    Then my message should appear immediately without page reload
    And the message should have proper styling
    And the form should be reset for the next message
    And the chat should scroll to show the new message

  @javascript
  Scenario: Chat auto-scroll behavior
    Given I am in a chat with multiple messages
    When a new message is added
    Then the chat should automatically scroll to the bottom
    And the latest message should be visible
    When I manually scroll up to view older messages
    And a new message is added
    Then the chat should scroll back to the bottom

  @javascript
  Scenario: Form submission states and feedback
    Given I am signed in as a regular user
    When I start typing a message
    Then the send button should be enabled
    When I submit the message
    Then the send button should show loading state
    And the form should be disabled during processing
    When the response is received
    Then the form should be re-enabled
    And the send button should return to normal state

  @javascript
  Scenario: Responsive design interactions on mobile
    Given I am viewing the application on a mobile device
    When I tap on the message input field
    Then the virtual keyboard should appear
    And the textarea should remain visible above the keyboard
    And the send button should remain accessible
    When I rotate the device
    Then the layout should adapt appropriately
    And all interactive elements should remain functional

  @javascript
  Scenario: Focus management and accessibility
    Given I am on the homepage
    When I navigate using only keyboard
    Then I should be able to tab through all interactive elements
    And focus indicators should be clearly visible
    And the tab order should be logical
    When I reach the message input field
    Then I should be able to type immediately
    And keyboard shortcuts should work as expected

  @javascript
  Scenario: Copy and paste functionality in message input
    Given I am signed in as a regular user
    When I copy text from another source
    And I paste it into the message input field
    Then the pasted content should appear correctly
    And formatting should be preserved appropriately
    And the textarea should auto-resize if needed
    When I select text in the input field and copy it
    Then I should be able to paste it elsewhere

  @javascript
  Scenario: Input field placeholder behavior
    Given I am on the homepage as an anonymous user
    Then I should see helpful placeholder text in the message field
    And the placeholder should mention keyboard shortcuts
    When I focus on the input field
    Then the placeholder should remain visible until I start typing
    When I type and then clear the content
    Then the placeholder should reappear

  @javascript
  Scenario: Message input field character limits and validation
    Given I am signed in as a regular user
    When I type an extremely long message
    Then the input should accept the content
    And the character count should be reasonable
    And there should be no arbitrary limits that break user experience

  @javascript
  Scenario: Smooth transitions and animations
    Given I am navigating through the application
    When I perform various actions like sending messages
    Then transitions should be smooth and non-jarring
    And animations should enhance rather than hinder the experience
    And performance should remain good during animations

  @javascript
  Scenario: Browser history integration with AJAX interactions
    Given I am signed in as a regular user with multiple chats
    When I navigate between chats using the sidebar
    Then the browser URL should update appropriately
    And I should be able to use browser back/forward buttons
    And the page state should be preserved correctly
    And bookmarking specific chats should work

  @javascript
  Scenario: Error state recovery in UI
    Given I am in a chat interface
    When a network error occurs during message sending
    Then the UI should show an appropriate error state
    And I should be able to retry the action
    When the network recovers
    Then the UI should return to normal functioning
    And any queued actions should be processed

  @javascript
  Scenario: Loading states and progress indicators
    Given I am sending a message that takes time to process
    When I submit the message
    Then I should see immediate feedback that it was sent
    And there should be loading indicators for the response
    And the interface should remain responsive during waiting
    When the response arrives
    Then loading indicators should be cleared appropriately

  @javascript
  Scenario: Sidebar interactions for authenticated users
    Given I am signed in as a regular user with multiple chats
    When I hover over a chat in the sidebar
    Then there should be appropriate hover effects
    When I click on a chat
    Then the selection should be immediate
    And the selected chat should be visually highlighted
    And the transition should be smooth

  @javascript
  Scenario: User menu dropdown interactions
    Given I am signed in as a regular user
    When I click on my email in the navigation
    Then the dropdown menu should appear smoothly
    And clicking outside should close the menu
    And pressing Escape should close the menu
    And the menu should be accessible via keyboard navigation

  @javascript
  Scenario: Form validation feedback
    Given I am on a registration or login form
    When I enter invalid data
    Then validation errors should appear immediately
    And error styling should be applied to relevant fields
    And errors should clear when I correct the input
    And the overall experience should be helpful not punitive

  @javascript
  Scenario: Turbo Stream error handling
    Given I am using features that rely on Turbo Streams
    When a Turbo Stream fails to load or process
    Then the application should handle it gracefully
    And I should not see broken or inconsistent UI states
    And fallback mechanisms should maintain functionality

  @javascript
  Scenario: Performance with many UI elements
    Given I have a chat with many messages
    When I scroll through the conversation history
    Then scrolling should remain smooth
    And memory usage should not grow excessively
    And the interface should not become sluggish
    When I interact with various UI elements
    Then response times should remain consistent