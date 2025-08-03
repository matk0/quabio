Feature: Admin User Features
  As an admin user of Miťo
  I want to access advanced features like RAG comparison
  So that I can evaluate different AI response variants and system performance

  Background:
    Given the application is running

  @admin
  Scenario: Admin user can sign in and access the interface
    Given I am signed in as an admin user
    When I visit the homepage
    Then I should see the standard authenticated interface
    And I should see "Všetky konverzácie" in the navigation
    And I should see my email in the user menu
    And I should see the sidebar with chat list

  @admin
  Scenario: Admin user receives comparison responses
    Given I am signed in as an admin user
    And I have an active chat
    When I send a message "Čo je epigenetika?"
    Then I should see my message in the chat
    And I should see comparison responses from both RAG variants
    And I should see "Fixed Size" variant response
    And I should see "Semantic" variant response
    And each variant should show processing time
    And each variant should show its sources

  @admin
  Scenario: Admin comparison response formatting
    Given I am signed in as an admin user
    When I send a message "Aké sú benefity vitamínu D?"
    Then I should see a comparison container
    And I should see exactly 2 comparison variants
    And each variant should have a distinct header
    And each variant should show "🧬 Miťo" branding
    And each variant should have separate response content
    And the variants should be displayed side by side

  @admin
  Scenario: Admin comparison responses show performance metrics
    Given I am signed in as an admin user
    When I send a message "Čo je oxidatívny stres?"
    Then each RAG variant should show processing time
    And processing times should be in seconds format
    And each variant should show the number of sources used
    And performance metrics should be clearly labeled

  @admin
  Scenario: Admin comparison responses handle different content lengths
    Given I am signed in as an admin user
    When I send a complex message requiring detailed responses
    Then both RAG variants should display their full responses
    And content should not be truncated inappropriately
    And both variants should maintain proper formatting
    And longer responses should be properly contained

  @admin
  Scenario: Admin comparison responses show source citations
    Given I am signed in as an admin user
    When I send a message "Vysvetlite mi proces fotosyntézy"
    Then each variant should show its source documents
    And sources should be clearly attributed to each variant
    And source information should include document titles
    And sources should be properly formatted and readable

  @admin
  Scenario: Admin user can create and manage multiple chats normally
    Given I am signed in as an admin user
    When I create a new chat
    And I send multiple messages
    Then each message should trigger comparison responses
    And I should be able to navigate between chats
    And each chat should maintain its comparison history
    And the sidebar should function normally

  @admin
  Scenario: Admin comparison does not create duplicate messages in database
    Given I am signed in as an admin user
    When I send a message "Test question for admin"
    Then I should see comparison responses in the UI
    But only my user message should be saved to the database
    And no assistant messages should be created for comparison responses
    And the chat message count should reflect only user messages

  @admin
  Scenario: Admin comparison responses handle API errors gracefully
    Given the FastAPI comparison endpoint returns an error
    And I am signed in as an admin user
    When I send a message "Test error handling"
    Then I should see my message in the chat
    And I should see an error message about comparison failure
    And the error message should be professional and helpful
    And I should not see broken comparison containers

  @admin
  Scenario: Admin user sees same navigation as regular users
    Given I am signed in as an admin user
    Then I should see "Všetky konverzácie" in the navigation
    And I should see my email in the user menu
    And I should not see any special admin navigation elements
    And the UI should look identical to regular user interface

  @admin
  Scenario: Admin status is not visible in the UI
    Given I am signed in as an admin user
    When I view any page
    Then I should not see any indication that I am an admin
    And there should be no "Admin" badges or labels
    And the admin functionality should be transparent
    And the interface should appear normal to observers

  @admin @javascript
  Scenario: Admin comparison responses update via Turbo Streams
    Given I am signed in as an admin user
    When I send a message using the form
    Then the user message should appear immediately
    And the comparison responses should load without page refresh
    And the comparison container should be properly rendered
    And the page should not reload during the process

  @admin
  Scenario: Admin comparison variants show different content
    Given I am signed in as an admin user
    When I send a message "Popíšte metabolizmus glukózy"
    Then the Fixed Size variant should show its response
    And the Semantic variant should show its response
    And the responses should be different from each other
    And each should reflect the chunking strategy used
    And both should be relevant to the question

  @admin
  Scenario: Admin comparison processing times are realistic
    Given I am signed in as an admin user
    When I send a message "Aký je vplyv stravy na imunitný systém?"
    Then each variant should show a processing time
    And processing times should be positive numbers
    And processing times should be in a reasonable range (0.1-30 seconds)
    And times should be displayed with appropriate precision

  @admin
  Scenario: Admin comparison maintains chat history properly
    Given I am signed in as an admin user
    And I have sent several messages with comparison responses
    When I refresh the page
    Then I should see all my previous messages
    And I should see all previous comparison responses
    And the conversation history should be complete
    And pagination should work if there are many messages

  @admin
  Scenario: Admin comparison responses handle special characters
    Given I am signed in as an admin user
    When I send a message with special characters "Čo je α-tokoferol a β-karotén?"
    Then both variants should handle the special characters correctly
    And the responses should display special characters properly
    And there should be no encoding issues
    And both responses should be readable

  @admin
  Scenario: Admin user switching between admin and regular behavior
    Given I am signed in as an admin user
    When I send a message and see comparison responses
    # Note: In this implementation, admin users always get comparison responses
    # There's no toggle between admin and regular mode
    Then I should consistently receive comparison responses
    And the behavior should be predictable across all messages

  @admin @api_failure
  Scenario: Admin comparison graceful degradation when compare endpoint fails
    Given the FastAPI compare endpoint is unavailable
    But the regular chat endpoint is working
    And I am signed in as an admin user
    When I send a message "Fallback test question"
    Then I should see my message in the chat
    And I should see a comparison error message
    And the system should not crash or show broken UI
    And I should still be able to send more messages

  @admin
  Scenario: Admin comparison variant headers are properly labeled
    Given I am signed in as an admin user
    When I send a message "Test variant labeling"
    Then I should see a header for "Fixed Size" variant
    And I should see a header for "Semantic" variant
    And the headers should be clearly distinguishable
    And each header should include the "🧬 Miťo" branding
    And the variant names should be consistent across messages