Feature: User Authentication
  As a visitor to Miťo
  I want to be able to register, login, and manage my account
  So that I can save my chat history and access authenticated features

  Background:
    Given the application is running

  Scenario: User can access registration page
    When I visit the homepage
    And I click "Registrovať sa"
    Then I should be on the sign up page
    And I should see "Registrácia do Miťo"
    And I should see the registration form
    And I should see "E-mailová adresa"
    And I should see "Heslo"

  Scenario: User can register with valid credentials
    Given I am on the sign up page
    When I fill in the registration form with valid details
    And I submit the registration form
    Then I should be signed in
    And I should see "Vitajte v Miťo!"
    And I should be on the homepage
    And I should see "Všetky konverzácie" in the navigation

  Scenario: User cannot register with invalid email
    Given I am on the sign up page
    When I fill in the registration form with an invalid email
    And I submit the registration form
    Then I should see "Email is invalid"
    And I should remain on the sign up page

  Scenario: User cannot register with short password
    Given I am on the sign up page
    When I fill in the registration form with a short password
    And I submit the registration form
    Then I should see "Password is too short"
    And I should remain on the sign up page

  Scenario: User cannot register with mismatched password confirmation
    Given I am on the sign up page
    When I fill in the registration form with mismatched password confirmation
    And I submit the registration form
    Then I should see "Password confirmation doesn't match Password"
    And I should remain on the sign up page

  Scenario: User cannot register with existing email
    Given a user exists with email "existing@example.com"
    And I am on the sign up page
    When I fill in the registration form with email "existing@example.com"
    And I submit the registration form
    Then I should see "Email has already been taken"
    And I should remain on the sign up page

  Scenario: User can access login page
    When I visit the homepage
    And I click "Prihlásiť sa"
    Then I should be on the sign in page
    And I should see "Prihláste sa"
    And I should see the login form

  Scenario: User can login with valid credentials
    Given a user exists with email "user@example.com" and password "password123"
    When I sign in with email "user@example.com" and password "password123"
    Then I should be signed in
    And I should see "Vitajte v Miťo!"
    And I should be on the homepage
    And I should see "Všetky konverzácie" in the navigation

  Scenario: User cannot login with invalid email
    When I sign in with email "nonexistent@example.com" and password "password123"
    Then I should see "Invalid Email or password."
    And I should remain on the sign in page

  Scenario: User cannot login with invalid password
    Given a user exists with email "user@example.com" and password "password123"
    When I sign in with email "user@example.com" and password "wrongpassword"
    Then I should see "Invalid Email or password."
    And I should remain on the sign in page

  Scenario: User can logout
    Given I am signed in as a regular user
    When I click on my user menu
    And I logout
    Then I should be signed out
    And I should see "Úspešne ste sa odhlásili"
    And I should see "Prihlásiť sa" in the navigation
    And I should see "Registrovať sa" in the navigation

  Scenario: User can access password reset page
    When I visit the sign in page
    And I click "Zabudli ste heslo?"
    Then I should be on the forgot password page
    And I should see "Zabudnuté heslo"
    And I should see the password reset form

  Scenario: User can request password reset
    Given a user exists with email "user@example.com"
    When I request password reset for "user@example.com"
    Then I should see "O niekoľko minút dostanete email s inštrukciami na obnovenie hesla"
    And a password reset email should be sent to "user@example.com"

  Scenario: User cannot request password reset for non-existent email
    When I request password reset for "nonexistent@example.com"
    Then I should see "Email nenájdený"

  Scenario: Signed in user accessing sign in page is redirected
    Given I am signed in as a regular user
    When I visit the sign in page
    Then I should be redirected to the homepage

  Scenario: Signed in user accessing sign up page is redirected
    Given I am signed in as a regular user
    When I visit the sign up page
    Then I should be redirected to the homepage

  Scenario: User navigation changes based on authentication state
    # Anonymous user
    When I visit the homepage
    Then I should see "Prihlásiť sa" in the navigation
    And I should see "Registrovať sa" in the navigation
    And I should not see "Všetky konverzácie" in the navigation
    And I should not see a user menu

    # Authenticated user
    When I sign in as a regular user
    Then I should see "Všetky konverzácie" in the navigation
    And I should see my email in the user menu
    And I should not see "Prihlásiť sa" in the navigation
    And I should not see "Registrovať sa" in the navigation

  @javascript
  Scenario: User menu dropdown works correctly
    Given I am signed in as a regular user
    When I click on my user menu
    Then I should see the user dropdown menu
    And I should see "Odhlásiť sa" in the dropdown
    When I click elsewhere on the page
    Then the user dropdown menu should be hidden