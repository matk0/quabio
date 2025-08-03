Feature: Chat functionality
  As a user of Miťo
  I want to be able to chat with the health assistant
  So that I can get answers about health, epigenetics and quantum biology

  Background:
    Given the application is running

  Scenario: Anonymous user can access the chat
    When I visit the homepage
    Then I should see the chat interface
    And I should see "Vitajte v Miťo!"
    And I should see a message input field

  Scenario: Anonymous user can send a message
    Given I am on the homepage
    When I fill in the message field with "Čo sú to mitochondrie?"
    And I click the send button
    Then I should see my message in the chat
    And I should see a response from Miťo

  Scenario: User can sign up from homepage
    Given I am on the homepage
    When I click "Registrovať sa"
    Then I should be on the sign up page
    And I should see "Zaregistrujte sa"

  @admin
  Scenario: Admin user sees comparison responses
    Given I am signed in as an admin user
    And I am on the homepage
    When I fill in the message field with "Čo je epigenetika?"
    And I click the send button
    Then I should see my message in the chat
    And I should see comparison responses from both RAG variants
    And I should see "Fixed Size" and "Semantic" variants