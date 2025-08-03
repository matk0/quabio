Feature: Anonymous Chat Functionality
  As a visitor to Miťo
  I want to be able to chat immediately without registration
  So that I can quickly get answers to my health questions

  Background:
    Given the application is running

  Scenario: Anonymous user can access chat interface immediately
    When I visit the homepage
    Then I should see the chat interface
    And I should see "Vitajte v Miťo!"
    And I should see "Váš slovenský asistent pre zdravie, epigenetiku a kvantovú biológiu"
    And I should see a message input field
    And I should see the send button
    And I should not see the sidebar
    And I should not see "Všetky konverzácie"

  Scenario: Anonymous user can send their first message
    Given I am on the homepage as an anonymous user
    When I type "Čo sú to mitochondrie?" in the message field
    And I click the send button
    Then I should see my message "Čo sú to mitochondrie?" in the chat
    And I should see a loading indicator
    And I should eventually see a response from Miťo
    And the chat title should be updated to "Čo sú to mitochondrie?"

  Scenario: Anonymous user sees signup invitation after first response
    Given I am on the homepage as an anonymous user
    When I send my first message "Aké sú benefity exercízie?"
    And I receive a response from Miťo
    Then I should see a signup invitation
    And I should see "Zaregistrujte sa na uloženie konverzácie"
    And I should see a "Registrovať sa" button in the invitation

  Scenario: Anonymous user can continue chatting after first response
    Given I am an anonymous user with an existing conversation
    When I send a follow-up message "Môžete mi povedať viac?"
    Then I should see my follow-up message in the chat
    And I should receive another response from Miťo
    And I should not see the signup invitation again

  Scenario: Anonymous user session persistence
    Given I am an anonymous user with an existing conversation
    When I refresh the page
    Then I should see my previous messages
    And I should see Miťo's previous responses
    And the chat should maintain my session

  Scenario: Anonymous user can send multiple messages in sequence
    Given I am on the homepage as an anonymous user
    When I send the message "Čo je to DNA?"
    And I wait for the response
    And I send the message "A čo RNA?"
    And I wait for the response
    And I send the message "Aký je rozdiel medzi nimi?"
    Then I should see all three of my messages in chronological order
    And I should see three responses from Miťo
    And each message should be properly formatted

  Scenario: Anonymous user cannot send empty messages
    Given I am on the homepage as an anonymous user
    When I try to send an empty message
    Then the message should not be sent
    And I should not see an empty message in the chat

  Scenario: Anonymous user cannot send whitespace-only messages
    Given I am on the homepage as an anonymous user
    When I type only spaces in the message field
    And I click the send button
    Then the message should not be sent
    And I should not see a whitespace message in the chat

  Scenario: Anonymous user can send messages with special characters
    Given I am on the homepage as an anonymous user
    When I send a message with special characters "Čo je to α-tokoferol? Má účinky na ❤️?"
    Then I should see my message with special characters in the chat
    And I should receive a response from Miťo

  Scenario: Anonymous user can send long messages
    Given I am on the homepage as an anonymous user
    When I send a very long message about health concerns
    Then I should see my full long message in the chat
    And I should receive a response from Miťo
    And the message should be properly formatted without truncation

  @javascript
  Scenario: Anonymous user can use keyboard shortcuts
    Given I am on the homepage as an anonymous user
    When I type "Čo je vitamín D?" in the message field
    And I press Enter
    Then my message should be sent
    And I should see "Čo je vitamín D?" in the chat

  @javascript
  Scenario: Anonymous user can create new lines with Shift+Enter
    Given I am on the homepage as an anonymous user
    When I type "Prvý riadok" in the message field
    And I press Shift+Enter
    And I type "Druhý riadok"
    Then I should see both lines in the textarea
    When I press Enter
    Then I should see a multiline message in the chat

  Scenario: Anonymous user sees helpful placeholder text
    Given I am on the homepage as an anonymous user
    Then I should see placeholder text "Napíšte svoju otázku o zdraví... (Enter na odoslanie, Shift+Enter pre nový riadok)"

  Scenario: Anonymous user message formatting
    Given I am on the homepage as an anonymous user
    When I send a message "Test message"
    Then my message should appear on the right side of the chat
    And my message should have user message styling
    When I receive a response from Miťo
    Then Miťo's response should appear on the left side of the chat
    And Miťo's response should have assistant message styling
    And Miťo's response should include the "🧬 Miťo" identifier

  Scenario: Anonymous user chat scrolling behavior
    Given I am an anonymous user with multiple messages
    When I send a new message
    Then the chat should scroll to show the latest message
    And the newest messages should be visible at the bottom

  Scenario: Multiple anonymous users get separate sessions
    Given I am an anonymous user in one browser session
    And I send a message "Moja otázka"
    When I open a new incognito session
    And I visit the homepage
    Then I should see a fresh chat interface
    And I should not see messages from the other session

  Scenario: Anonymous user clicking signup invitation goes to registration
    Given I am an anonymous user who has received a response
    And I can see the signup invitation
    When I click "Registrovať sa" in the invitation
    Then I should be on the sign up page
    And I should see "Zaregistrujte sa"

  Scenario: Anonymous user navigation is limited
    Given I am on the homepage as an anonymous user
    Then I should see "Prihlásiť sa" in the navigation
    And I should see "Registrovať sa" in the navigation
    And I should not see "Všetky konverzácie" in the navigation
    And I should not see a user menu

  Scenario: Anonymous user cannot access authenticated routes
    When I visit the chats index page as an anonymous user
    Then I should be redirected to the sign in page
    And I should see "Musíte sa prihlásiť alebo zaregistrovať"

  @api_failure
  Scenario: Anonymous user receives helpful error when API is down
    Given the FastAPI backend is unavailable
    And I am on the homepage as an anonymous user
    When I send a message "Test otázka"
    Then I should see my message in the chat
    And I should see a helpful error message from Miťo
    And the error message should mention registering to save the question
    And the error message should be in Slovak