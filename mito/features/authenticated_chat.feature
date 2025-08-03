Feature: Authenticated User Chat Management
  As a registered user of Miťo
  I want to be able to create, manage, and view my chat conversations
  So that I can maintain a history of my health-related conversations

  Background:
    Given the application is running

  Scenario: Authenticated user sees enhanced interface
    Given I am signed in as a regular user
    When I visit the homepage
    Then I should see the chat interface with sidebar
    And I should see "Konverzácie" in the sidebar
    And I should see "+ Nová konverzácia" button
    And I should see "Všetky konverzácie" in the navigation
    And I should see my email in the user menu

  Scenario: New authenticated user gets automatically created first chat
    Given I am a newly registered user
    When I visit the homepage for the first time
    Then a new chat should be created automatically
    And I should see "Nová konverzácia" as the chat title
    And I should see the welcome message
    And the chat should be listed in my sidebar

  Scenario: Authenticated user can create a new chat
    Given I am signed in as a regular user with existing chats
    When I click "+ Nová konverzácia"
    Then a new chat should be created
    And I should be redirected to the new chat
    And I should see "Nová konverzácia" as the initial title
    And the new chat should appear in my sidebar

  Scenario: Authenticated user can send messages and receive responses
    Given I am signed in as a regular user
    And I have an active chat
    When I send a message "Aké sú benefity meditácie?"
    Then I should see my message in the chat
    And I should receive a response from Miťo
    And the chat title should update to "Aké sú benefity meditácie?"
    And the chat should show the updated timestamp

  Scenario: Authenticated user can switch between chats
    Given I am signed in as a regular user
    And I have multiple chats with different titles
    When I click on a different chat in the sidebar
    Then I should be redirected to that chat
    And I should see the messages from that chat
    And the selected chat should be highlighted in the sidebar

  Scenario: Authenticated user sees chat list in chronological order
    Given I am signed in as a regular user
    And I have multiple chats with different last activity times
    When I view my chat sidebar
    Then the chats should be ordered by most recent activity first
    And each chat should show its title
    And each chat should show "ago" timestamp

  Scenario: Authenticated user chat titles are automatically generated
    Given I am signed in as a regular user
    And I have a new chat with no messages
    When I send my first message "Čo je to oxidatívny stres a ako mu predchádzať?"
    Then the chat title should be updated to "Čo je to oxidatívny stres a ako mu predchádzať?"
    And the title should be visible in the sidebar
    And the title should be truncated if too long

  Scenario: Authenticated user can see full conversation history
    Given I am signed in as a regular user
    And I have a chat with multiple messages
    When I view that chat
    Then I should see all my previous messages
    And I should see all of Miťo's previous responses
    And messages should be in chronological order
    And each message should maintain its formatting

  Scenario: Authenticated user message formatting differs from anonymous
    Given I am signed in as a regular user
    When I send a message "Test authenticated message"
    Then my message should use the authenticated user form
    And the form should have "message[content]" field name
    And I should not see a signup invitation
    And I should not see anonymous user prompts

  Scenario: Authenticated user can access all their chats via navigation
    Given I am signed in as a regular user with multiple chats
    When I click "Všetky konverzácie" in the navigation
    Then I should be on the chats index page
    And I should see a list of all my chats
    And each chat should show its title and last activity
    And I should be able to click on any chat to view it

  Scenario: Authenticated user chats index page functionality
    Given I am signed in as a regular user
    When I visit the chats index page
    Then I should see "Konverzácie" as the page title
    And I should see a list of my chats
    And I should see a "Nová konverzácia" option
    And I should be able to navigate back to individual chats

  @javascript
  Scenario: Authenticated user real-time message updates
    Given I am signed in as a regular user
    And I have an active chat
    When I send a message using the form
    Then the message should appear immediately via Turbo Stream
    And I should not see a page reload
    And the message form should be cleared
    And the chat should scroll to the new message

  Scenario: Authenticated user sidebar shows limited number of recent chats
    Given I am signed in as a regular user
    And I have many chats (more than 10)
    When I view the sidebar
    Then I should see only the 10 most recent chats
    And older chats should not be visible in the sidebar
    But I should be able to access all chats via "Všetky konverzácie"

  Scenario: Authenticated user can continue conversations across sessions
    Given I am signed in as a regular user
    And I have sent messages in a chat
    When I sign out and sign back in
    And I navigate to that chat
    Then I should see all my previous messages
    And I should be able to continue the conversation
    And the chat should maintain its history

  Scenario: Authenticated user cannot access other users' chats
    Given I am signed in as a regular user
    And another user has a chat with ID "other-user-chat-id"
    When I try to access that chat directly via URL
    Then I should see "Chat nenájdený"
    And I should be redirected to the homepage

  Scenario: Authenticated user sees appropriate navigation elements
    Given I am signed in as a regular user
    Then I should see "Všetky konverzácie" in the navigation
    And I should see my email in the user menu
    And I should not see "Prihlásiť sa" link
    And I should not see "Registrovať sa" link
    And I should be able to access the logout option

  Scenario: Authenticated user empty state when no chats exist
    Given I am signed in as a newly registered user
    And I have no chats yet
    When I visit the chats index page
    Then I should see "Žiadne konverzácie"
    And I should see "Začnite novú konverzáciu!"
    And I should see a way to create a new chat

  Scenario: Authenticated user can handle long conversation histories
    Given I am signed in as a regular user
    And I have a chat with many messages
    When I view that chat
    Then all messages should load properly
    And the chat should be scrollable
    And the latest messages should be visible at the bottom

  @api_failure
  Scenario: Authenticated user receives appropriate error handling
    Given the FastAPI backend is unavailable
    And I am signed in as a regular user
    When I send a message "Test question"
    Then I should see my message in the chat
    And I should see a professional error message from Miťo
    And the error message should not mention registration
    And my message should still be saved to the database

  Scenario: Authenticated user data persistence
    Given I am signed in as a regular user
    When I create a new chat and send messages
    Then the chat should be saved to the database
    And the messages should be associated with my user account
    And the chat should have proper timestamps
    And I should be able to retrieve this data in future sessions

  Scenario: Authenticated user display names and formatting
    Given I am signed in as a regular user
    When I view any chat
    Then user messages should show proper styling
    And assistant messages should show "🧬 Miťo" branding
    And timestamps should be properly formatted
    And the interface should be consistent with the authenticated design