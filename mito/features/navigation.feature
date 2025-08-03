Feature: Navigation and UI Design
  As a user of Miťo
  I want intuitive navigation and responsive design
  So that I can easily use the application on any device

  Background:
    Given the application is running

  Scenario: Anonymous user sees appropriate navigation elements
    When I visit the homepage as an anonymous user
    Then I should see the Miťo logo in the navigation
    And I should see "Prihlásiť sa" link in the navigation
    And I should see "Registrovať sa" button in the navigation
    And I should not see "Všetky konverzácie" in the navigation
    And I should not see a user menu
    And the navigation should be fixed at the top

  Scenario: Authenticated user sees enhanced navigation
    Given I am signed in as a regular user
    When I visit any page
    Then I should see the Miťo logo in the navigation
    And I should see "Všetky konverzácie" link in the navigation
    And I should see my email in the user menu
    And I should not see "Prihlásiť sa" link
    And I should not see "Registrovať sa" button
    And the navigation should be consistent across pages

  Scenario: Miťo logo navigation
    When I visit any page
    And I click on the Miťo logo
    Then I should be taken to the homepage
    And the logo should be visually prominent
    And the logo should include the "🧬" emoji

  Scenario: User menu dropdown functionality
    Given I am signed in as a regular user
    When I hover over my email in the navigation
    Then I should see the user dropdown menu
    And I should see "Odhlásiť sa" option
    When I click "Odhlásiť sa"
    Then I should be signed out successfully

  @javascript
  Scenario: User menu dropdown interactive behavior
    Given I am signed in as a regular user
    When I click on my email in the navigation
    Then the dropdown menu should appear
    When I click elsewhere on the page
    Then the dropdown menu should disappear

  Scenario: Navigation breadcrumbs and page titles
    Given I am signed in as a regular user
    When I visit the chats index page
    Then I should see "Konverzácie" as the page context
    When I visit a specific chat
    Then I should see the chat title in the header
    And I should see "Slovenský zdravotný asistent" as the subtitle

  Scenario: Sidebar navigation for authenticated users
    Given I am signed in as a regular user with multiple chats
    When I view any chat page
    Then I should see the sidebar on the left
    And I should see "Konverzácie" as the sidebar title
    And I should see "+ Nová konverzácia" button
    And I should see my recent chats listed
    And the current chat should be highlighted

  Scenario: Sidebar chat list functionality
    Given I am signed in as a regular user with multiple chats
    When I click on a different chat in the sidebar
    Then I should navigate to that chat
    And the selected chat should be visually highlighted
    And the sidebar should remain visible
    And the transition should be smooth

  Scenario: Anonymous users do not see sidebar
    When I visit the homepage as an anonymous user
    Then I should not see any sidebar
    And the chat interface should take full width
    And the layout should be optimized for anonymous usage

  Scenario: Responsive navigation on mobile devices
    When I visit the homepage on a mobile device
    Then the navigation should be mobile-optimized
    And all navigation elements should be accessible
    And the layout should stack appropriately
    And touch targets should be appropriately sized

  @javascript @mobile
  Scenario: Mobile sidebar behavior for authenticated users
    Given I am signed in as a regular user
    When I view the chat interface on mobile
    Then the sidebar should be collapsible
    And I should be able to toggle the sidebar
    And the main chat area should adjust accordingly
    And the experience should remain usable

  Scenario: Page loading and navigation speed
    When I navigate between different pages
    Then page transitions should be fast
    And the navigation should remain responsive
    And there should be no broken links
    And all pages should load within reasonable time

  Scenario: Navigation accessibility
    When I use keyboard navigation
    Then all navigation elements should be focusable
    And focus indicators should be visible
    And tab order should be logical
    And screen readers should work properly

  Scenario: Navigation consistency across user states
    # Test navigation consistency between anonymous and authenticated states
    When I visit the homepage as an anonymous user
    Then the navigation layout should be consistent
    When I sign in as a regular user
    Then the navigation layout should smoothly transition
    And the overall structure should remain familiar

  Scenario: Error page navigation
    When I visit a non-existent page
    Then I should see a 404 error page
    And the navigation should still be functional
    And I should be able to return to the homepage
    And the error page should maintain the site design

  Scenario: Deep linking and URL structure
    Given I am signed in as a regular user with chats
    When I visit a specific chat URL directly
    Then I should see that chat content
    And the URL should be meaningful
    And the page should load correctly
    And navigation should work from that point

  Scenario: Navigation with flash messages
    When I perform an action that triggers a flash message
    Then the flash message should appear appropriately
    And it should not interfere with navigation
    And the message should be dismissible
    And the navigation should remain functional

  Scenario: Chat header navigation elements
    Given I am signed in as a regular user
    When I view a specific chat
    Then I should see the chat title in the header
    And I should see "Slovenský zdravotný asistent" subtitle
    And the header should be visually distinct from the message area
    And the header should provide context about the current view

  Scenario: Sidebar chat ordering and timestamps
    Given I am signed in as a regular user with multiple chats
    When I view the sidebar
    Then chats should be ordered by last activity
    And each chat should show a relative timestamp
    And timestamps should be in Slovak format
    And the most recent activity should be at the top

  Scenario: Navigation performance with many chats
    Given I am signed in as a regular user with many chats
    When I view the sidebar
    Then only recent chats should be displayed (limit 10)
    And the sidebar should load quickly
    And I should be able to access all chats via "Všetky konverzácie"
    And navigation should remain responsive

  Scenario: New chat creation flow
    Given I am signed in as a regular user
    When I click "+ Nová konverzácia" from any page
    Then a new chat should be created
    And I should be navigated to the new chat
    And the new chat should appear in the sidebar
    And I should be ready to start messaging

  Scenario: Navigation state persistence
    Given I am signed in as a regular user
    When I navigate to different sections
    And I refresh the page
    Then I should remain in the same section
    And my authentication state should persist
    And the navigation should reflect my current location

  @javascript
  Scenario: Real-time navigation updates
    Given I am signed in as a regular user
    When I send a message in a chat
    Then the sidebar timestamp should update
    And the chat order might change based on activity
    And these updates should happen without page refresh
    And the navigation should remain smooth

  Scenario: Navigation with long chat titles
    Given I am signed in as a regular user
    And I have a chat with a very long title
    When I view the sidebar
    Then the long title should be properly truncated
    And the full title should be visible in the chat header
    And truncation should not break the layout
    And tooltips should show full titles when appropriate