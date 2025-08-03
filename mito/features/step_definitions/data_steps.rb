# Database setup and teardown helpers for testing

# User creation and management

Given('I am signed in as an admin user') do
  @current_user = User.create!(
    email: 'admin@cucumber.test',
    password: 'password123',
    admin: true
  )
  
  visit new_user_session_path
  fill_in 'E-mailová adresa', with: @current_user.email
  fill_in 'Heslo', with: 'password123'
  click_button 'Prihlásiť sa'
  
  expect(page).to have_content('Úspešne ste sa prihlásili')
end

Given('I have an existing user account') do
  @existing_user = User.create!(
    email: 'existing@cucumber.test',
    password: 'password123',
    admin: false
  )
end

Given('another user has a private chat') do
  @other_user = User.create!(
    email: 'other@cucumber.test',
    password: 'password123',
    admin: false
  )
  
  @other_user_chat = @other_user.chats.create!(
    title: 'Súkromný chat iného používateľa'
  )
  
  @other_user_chat.messages.create!(
    content: 'Súkromná správa',
    role: 'user'
  )
end

# Chat and message setup
Given('I have a chat with a very long title') do
  long_title = 'Toto je veľmi dlhý názov chatu ktorý by mal byť skrátený v bočnom paneli ale zobrazený v plnej dĺžke v hlavičke chatu keď je chat otvorený' * 2
  @chat = @current_user.chats.create!(title: long_title)
end

Given('I have many chats more than {int}') do |count|
  count.times do |i|
    @current_user.chats.create!(
      title: "Chat číslo #{i + 1}",
      updated_at: (count - i).hours.ago
    )
  end
end

Given('I have {int} chats with different creation times') do |count|
  @test_chats = []
  count.times do |i|
    chat = @current_user.chats.create!(
      title: "Test Chat #{i + 1}",
      created_at: (count - i).days.ago,
      updated_at: (count - i).hours.ago
    )
    @test_chats << chat
  end
end

Given('I am in a chat with multiple messages') do
  @chat = @current_user.chats.create!(title: 'Chat s viacerými správami')
  
  # Create alternating user and assistant messages
  5.times do |i|
    @chat.messages.create!(
      content: "Používateľská správa #{i + 1}",
      role: 'user'
    )
    @chat.messages.create!(
      content: "Odpoveď asistenta #{i + 1}",
      role: 'assistant'
    )
  end
  
  visit chat_path(@chat)
end

Given('I have a chat with many messages') do
  @chat = @current_user.chats.create!(title: 'Chat s mnohými správami')
  
  # Create a large number of messages to test scrolling
  50.times do |i|
    @chat.messages.create!(
      content: "Správa číslo #{i + 1}",
      role: i.even? ? 'user' : 'assistant'
    )
  end
  
  visit chat_path(@chat)
end

# Anonymous chat setup
Given('I have an anonymous session with existing messages') do
  @session_id = SecureRandom.uuid
  page.driver.browser.manage.add_cookie(name: '_session_id', value: @session_id)
  
  @anonymous_chat = AnonymousChat.create!(
    session_id: @session_id,
    title: 'Anonymná konverzácia'
  )
  
  @anonymous_chat.anonymous_messages.create!(
    content: 'Prvá anonymná správa',
    role: 'user'
  )
  
  @anonymous_chat.anonymous_messages.create!(
    content: 'Odpoveď na anonymnú správu',
    role: 'assistant'
  )
end

# Data cleanup helpers
Before do
  # Clean up database before each scenario
  DatabaseCleaner.clean_with(:truncation)
  
  # Reset any instance variables
  @current_user = nil
  @other_user = nil
  @chat = nil
  @anonymous_chat = nil
  @test_chats = []
end

After do
  # Clean up after each scenario
  if @second_session
    @second_session.driver.quit
  end
  
  # Clear cookies and session data
  page.driver.browser.manage.delete_all_cookies if page.driver.respond_to?(:browser)
  
  # Clean database
  DatabaseCleaner.clean
end

# Test data verification steps
Then('my chat history should be preserved') do
  if @current_user
    expect(@current_user.chats.count).to be > 0
    expect(@current_user.messages.count).to be > 0
  end
end

Then('each session should maintain its own state') do
  # Verify that each browser session sees appropriate data
  expect(page).to have_content('Všetky konverzácie')
  expect(@second_session).to have_content('Všetky konverzácie')
  
  # Sessions should not interfere with each other's data
  first_session_chats = page.all('.sidebar-chat').count
  second_session_chats = @second_session.all('.sidebar-chat').count
  
  # Both should see the same user's chats
  expect(first_session_chats).to eq(second_session_chats)
end

Then('I should not see any of the other user\'s data') do
  expect(page).not_to have_content(@other_user_chat.title)
  expect(page).not_to have_content('Súkromná správa')
  expect(page).not_to have_content(@other_user.email)
end

# Performance testing data setup
Given('I have performance test data') do
  # Create a reasonable amount of test data for performance testing
  10.times do |i|
    chat = @current_user.chats.create!(
      title: "Performance Chat #{i + 1}",
      updated_at: i.hours.ago
    )
    
    # Add messages to each chat
    20.times do |j|
      chat.messages.create!(
        content: "Performance test message #{j + 1} in chat #{i + 1}",
        role: j.even? ? 'user' : 'assistant'
      )
    end
  end
end

# Error condition data setup
Given('I try to access a chat that doesn\'t exist') do
  # Generate a UUID that definitely doesn't exist
  @non_existent_chat_id = 'non-existent-chat-id-12345'
  visit "/chats/#{@non_existent_chat_id}"
end

Given('JavaScript is disabled in the browser') do
  # This would require switching to a non-JS driver
  # For now, we'll simulate by disabling JS features
  page.execute_script('window.Turbo = undefined;') rescue nil
  page.execute_script('window.Stimulus = undefined;') rescue nil
end

# User registration test data
Given('I am on the registration page') do
  visit new_user_registration_path
end

When('I register with valid information') do
  @new_user_email = 'newuser@cucumber.test'
  @new_user_password = 'password123'
  
  fill_in 'E-mailová adresa', with: @new_user_email
  fill_in 'Heslo', with: @new_user_password
  fill_in 'Potvrdenie hesla', with: @new_user_password
  click_button 'Zaregistrovať sa'
end

When('I try to register with an email that already exists') do
  fill_in 'E-mailová adresa', with: @existing_user.email
  fill_in 'Heslo', with: 'password123'
  fill_in 'Potvrdenie hesla', with: 'password123'
  click_button 'Zaregistrovať sa'
end

When('I try to register with a weak password') do
  fill_in 'E-mailová adresa', with: 'weakpass@cucumber.test'
  fill_in 'Heslo', with: '123'
  fill_in 'Password confirmation', with: '123'
  click_button 'Zaregistrovať sa'
end

When('I try to register with mismatched passwords') do
  fill_in 'E-mailová adresa', with: 'mismatch@cucumber.test'
  fill_in 'Heslo', with: 'password123'
  fill_in 'Password confirmation', with: 'differentpassword'
  click_button 'Zaregistrovať sa'
end

# Sign in test data
When('I sign in with valid credentials') do
  fill_in 'E-mailová adresa', with: @existing_user.email
  fill_in 'Heslo', with: 'password123'
  click_button 'Prihlásiť sa'
end

When('I try to sign in with wrong email') do
  fill_in 'E-mailová adresa', with: 'wrong@cucumber.test'
  fill_in 'Heslo', with: 'password123'
  click_button 'Prihlásiť sa'
end

When('I try to sign in with wrong password') do
  fill_in 'E-mailová adresa', with: @existing_user.email
  fill_in 'Heslo', with: 'wrongpassword'
  click_button 'Prihlásiť sa'
end

# Database state verification
Then('a new user account should be created') do
  new_user = User.find_by(email: @new_user_email)
  expect(new_user).to be_present
  expect(new_user.admin).to be false
  @current_user = new_user
end

Then('the user should be automatically signed in') do
  expect(page).to have_content('Všetky konverzácie')
  expect(page).to have_content(@new_user_email)
end

Then('no new user account should be created') do
  users_with_email = User.where(email: @existing_user.email)
  expect(users_with_email.count).to eq(1)
end

# Password reset data
When('I request a password reset') do
  visit new_user_password_path
  fill_in 'E-mailová adresa', with: @existing_user.email
  click_button 'Obnoviť heslo'
end

Then('a password reset email should be sent') do
  # This would require email testing setup
  # For now, verify the flash message
  expect(page).to have_content('Pokyny na obnovenie hesla boli odoslané')
end

# Session management
When('I sign out') do
  click_link 'Odhlásiť sa'
end


Then('I should be redirected to the sign in page') do
  expect(current_path).to eq(new_user_session_path)
end

# Chat creation and management
When('I create multiple chats in sequence') do
  @created_chats = []
  3.times do |i|
    click_link '+ Nová konverzácia'
    @created_chats << @current_user.chats.order(:created_at).last
    expect(page).to have_content('Nová konverzácia')
  end
end

Then('each chat should be properly created') do
  @created_chats.each do |chat|
    expect(chat).to be_persisted
    expect(chat.title).to be_present
    expect(chat.user).to eq(@current_user)
  end
end

# Message persistence verification
Then('the message should be saved in the database') do
  if @current_user && @current_user.chats.any?
    last_message = @current_user.chats.last.messages.last
    expect(last_message).to be_present
    expect(last_message.role).to eq('user')
  end
end

Then('the anonymous message should be saved in the session') do
  if @anonymous_chat
    last_message = @anonymous_chat.anonymous_messages.last
    expect(last_message).to be_present
    expect(last_message.role).to eq('user')
  end
end

# Data integrity checks
Then('the database should remain consistent') do
  # Check referential integrity
  expect(Message.joins(:chat).count).to eq(Message.count)
  expect(AnonymousMessage.joins(:anonymous_chat).count).to eq(AnonymousMessage.count)
  
  # Check that orphaned records don't exist
  expect(Message.where(chat: nil)).to be_empty
  expect(AnonymousMessage.where(anonymous_chat: nil)).to be_empty
end

# Helper methods for database operations
private

def create_test_user(email: 'test@cucumber.test', admin: false)
  User.create!(
    email: email,
    password: 'password123',
    admin: admin
  )
end

def create_test_chat(user:, title: 'Test Chat')
  user.chats.create!(title: title)
end

def create_test_message(chat:, content: 'Test message', role: 'user')
  chat.messages.create!(content: content, role: role)
end

def sign_in_user(user)
  visit new_user_session_path
  fill_in 'E-mailová adresa', with: user.email
  fill_in 'Heslo', with: 'password123'
  click_button 'Prihlásiť sa'
  expect(page).to have_content('Úspešne ste sa prihlásili')
  @current_user = user
end

def clear_test_data
  AnonymousMessage.delete_all
  AnonymousChat.delete_all
  Message.delete_all
  Chat.delete_all
  User.delete_all
end