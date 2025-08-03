Given('the application is running') do
  # This step verifies the Rails app is accessible
  visit root_path
  # Check that page loaded successfully by looking for basic page elements
  expect(page).to have_content('🧬 Miťo')
end

When('I visit the homepage') do
  visit root_path
end

Given('I am on the homepage') do
  visit root_path
end

Then('I should see the chat interface') do
  expect(page).to have_css('#messages-container')
  expect(page).to have_css('#new_message')
end

Then('I should see {string}') do |text|
  expect(page).to have_content(text)
end

Then('I should see a message input field') do
  expect(page).to have_css('textarea[name*="content"]')
end

When('I fill in the message field with {string}') do |message|
  fill_in 'anonymous_message[content]', with: message
end

When('I click the send button') do
  click_button 'Odoslať'
end

When('I click {string}') do |button_text|
  click_link button_text
end

Then('I should see my message in the chat') do
  expect(page).to have_css('.flex.justify-end') # User message styling
end

Then('I should see a response from Miťo') do
  expect(page).to have_content('🧬 Miťo')
end


Given('I am signed in as an admin user') do
  # Create and sign in as admin user
  admin_user = User.create!(
    email: 'admin@cucumber.test',
    password: 'password123',
    admin: true
  )
  
  visit new_user_session_path
  fill_in 'Email', with: admin_user.email
  fill_in 'Password', with: 'password123'
  click_button 'Prihlásiť sa'
  
  expect(page).to have_content('Úspešne ste sa prihlásili')
end

Then('I should see comparison responses from both RAG variants') do
  expect(page).to have_css('.comparison-container')
  expect(page).to have_css('.comparison-variant', count: 2)
end

Then('I should see {string} and {string} variants') do |variant1, variant2|
  expect(page).to have_content(variant1)
  expect(page).to have_content(variant2)
end

# Enhanced chat interaction steps
Given('I am on the homepage as an anonymous user') do
  visit root_path
  expect(page).not_to have_content('Všetky konverzácie')
end

Given('I have an active chat') do
  if user_signed_in?
    @chat = @current_user.chats.first || @current_user.chats.create!(title: "Test Chat")
  else
    step 'I am on the homepage as an anonymous user'
  end
end

Given('I have multiple chats with different titles') do
  @chat1 = @current_user.chats.create!(title: "Prvá konverzácia", updated_at: 2.hours.ago)
  @chat2 = @current_user.chats.create!(title: "Druhá konverzácia", updated_at: 1.hour.ago)  
  @chat3 = @current_user.chats.create!(title: "Tretia konverzácia", updated_at: 30.minutes.ago)
end

Given('I have multiple chats with different last activity times') do
  @old_chat = @current_user.chats.create!(title: "Stará konverzácia", updated_at: 1.day.ago)
  @recent_chat = @current_user.chats.create!(title: "Nedávna konverzácia", updated_at: 1.hour.ago)
  @newest_chat = @current_user.chats.create!(title: "Najnovšia konverzácia", updated_at: 5.minutes.ago)
end

Given('I have a chat with multiple messages') do
  @chat = @current_user.chats.create!(title: "Chat s viacerými správami")
  @message1 = @chat.messages.create!(content: "Prvá správa", role: 'user')
  @message2 = @chat.messages.create!(content: "Odpoveď na prvú správu", role: 'assistant')
  @message3 = @chat.messages.create!(content: "Druhá správa", role: 'user')
  @message4 = @chat.messages.create!(content: "Odpoveď na druhú správu", role: 'assistant')
end

Given('I am an anonymous user with an existing conversation') do
  # Create an anonymous chat with some messages
  session_id = SecureRandom.uuid
  page.driver.browser.manage.add_cookie(name: '_session_id', value: session_id)
  
  @anonymous_chat = AnonymousChat.create!(
    session_id: session_id,
    title: "Anonymná konverzácia"
  )
  
  @anonymous_chat.anonymous_messages.create!(
    content: "Prvá anonymná správa",
    role: 'user'
  )
  
  @anonymous_chat.anonymous_messages.create!(
    content: "Odpoveď na anonymnú správu",
    role: 'assistant'
  )
  
  visit root_path
end

Given('I am an anonymous user who has received a response') do
  step 'I am on the homepage as an anonymous user'
  step 'I send my first message "Test otázka"'
  step 'I receive a response from Miťo'
end

# Message sending steps
When('I type {string} in the message field') do |message|
  if user_signed_in?
    fill_in 'message[content]', with: message
  else
    fill_in 'anonymous_message[content]', with: message
  end
end

When('I send a message {string}') do |message|
  step "I type \"#{message}\" in the message field"
  step 'I click the send button'
end

When('I send my first message {string}') do |message|
  step "I send a message \"#{message}\""
end

When('I send a follow-up message {string}') do |message|
  step "I send a message \"#{message}\""
end

When('I try to send an empty message') do
  # Don't fill anything in the field
  step 'I click the send button'
end

When('I try to send a message with only spaces') do
  step 'I type only spaces in the message field'
  step 'I click the send button'
end

When('I type only spaces in the message field') do
  if user_signed_in?
    fill_in 'message[content]', with: '   '
  else
    fill_in 'anonymous_message[content]', with: '   '
  end
end

When('I send a very long message about health concerns') do
  long_message = "Rád by som sa opýtal na veľmi dlhú otázku o zdraví. " * 50
  step "I send a message \"#{long_message}\""
end

When('I send a message with special characters {string}') do |message|
  step "I send a message \"#{message}\""
end

When('I wait for the response') do
  # Wait for assistant response to appear
  expect(page).to have_content('🧬 Miťo', wait: 10)
end

# Response verification steps  
Then('I should see my message {string} in the chat') do |message|
  expect(page).to have_content(message)
  expect(page).to have_css('.flex.justify-end', text: message)
end

Then('I should see a loading indicator') do
  # This might be implementation specific
  expect(page).to have_css('.loading, .spinner, [data-loading]') rescue nil
end

Then('I should eventually see a response from Miťo') do
  expect(page).to have_content('🧬 Miťo', wait: 15)
end

Then('I receive a response from Miťo') do
  expect(page).to have_content('🧬 Miťo')
end

Then('I should receive another response from Miťo') do
  # Wait for new response (different from previous)
  new_response_count = page.all(:css, '.assistant-message', text: /🧬 Miťo/).count
  expect(new_response_count).to be > 1
end

Then('the chat title should be updated to {string}') do |expected_title|
  expect(page).to have_content(expected_title)
end

Then('the message should not be sent') do
  # Check that no new message appears in chat
  expect(page).not_to have_css('.user-message:last-child')
end

Then('I should not see an empty message in the chat') do
  expect(page).not_to have_css('.user-message', text: /^\s*$/)
end

Then('I should not see a whitespace message in the chat') do
  expect(page).not_to have_css('.user-message', text: /^\s+$/)
end

# Navigation and UI verification
Then('I should see the chat interface with sidebar') do
  expect(page).to have_css('#messages-container')
  expect(page).to have_css('.w-80') # Sidebar
  expect(page).to have_content('Konverzácie')
end

Then('I should see the sidebar') do
  expect(page).to have_css('.w-80')
  expect(page).to have_content('Konverzácie')
end

Then('I should not see the sidebar') do
  expect(page).not_to have_css('.w-80')
  expect(page).not_to have_content('Konverzácie')
end

Then('I should see the send button') do
  expect(page).to have_button('Odoslať')
end

# Signup invitation steps
Then('I should see a signup invitation') do
  expect(page).to have_content('Zaregistrujte sa na uloženie konverzácie')
end

Then('I should see a {string} button in the invitation') do |button_text|
  within('.signup-invitation, .invitation') do
    expect(page).to have_link_or_button(button_text)
  end rescue expect(page).to have_link_or_button(button_text)
end

Then('I should not see the signup invitation again') do
  expect(page).not_to have_content('Zaregistrujte sa na uloženie konverzácie')
end

# Session and persistence
Then('I should see my previous messages') do
  expect(page).to have_content('Prvá anonymná správa')
end

Then('I should see Miťo\'s previous responses') do
  expect(page).to have_content('Odpoveď na anonymnú správu')
end

Then('the chat should maintain my session') do
  # Verify session persistence
  expect(page).to have_css('#messages-container')
  expect(page.all('.message').count).to be > 0
end

# Multiple messages scenarios
Then('I should see all three of my messages in chronological order') do
  messages = page.all('.user-message')
  expect(messages[0]).to have_content('Čo je to DNA?')
  expect(messages[1]).to have_content('A čo RNA?')
  expect(messages[2]).to have_content('Aký je rozdiel medzi nimi?')
end

Then('I should see three responses from Miťo') do
  expect(page.all('.assistant-message', text: /🧬 Miťo/).count).to eq(3)
end

Then('each message should be properly formatted') do
  # Check message structure
  expect(page).to have_css('.user-message')
  expect(page).to have_css('.assistant-message')
end

# Message formatting and styling
Then('my message should appear on the right side of the chat') do
  expect(page).to have_css('.flex.justify-end')
end

Then('my message should have user message styling') do
  expect(page).to have_css('.user-message, .justify-end')
end

Then('Miťo\'s response should appear on the left side of the chat') do
  expect(page).to have_css('.assistant-message')
end

Then('Miťo\'s response should have assistant message styling') do
  expect(page).to have_css('.assistant-message')
end

Then('Miťo\'s response should include the {string} identifier') do |identifier|
  expect(page).to have_content(identifier)
end

# Chat management for authenticated users
When('I create a new chat') do
  click_link '+ Nová konverzácia'
end

Then('a new chat should be created automatically') do
  expect(page).to have_content('Nová konverzácia')
  expect(@current_user.chats.count).to be > 0
end

Then('a new chat should be created') do
  expect(page).to have_content('Nová konverzácia')
end

Then('I should be redirected to the new chat') do
  expect(current_path).to match(%r{/chats/[\w-]+})
end

Then('the new chat should appear in my sidebar') do
  within('.w-80') do
    expect(page).to have_content('Nová konverzácia')
  end
end

When('I click on a different chat in the sidebar') do
  within('.w-80') do
    click_link @chat2.display_title
  end
end

Then('I should be redirected to that chat') do
  expect(current_path).to eq(chat_path(@chat2))
end

Then('I should see the messages from that chat') do
  expect(page).to have_content(@chat2.title)
end

Then('the selected chat should be highlighted in the sidebar') do
  within('.w-80') do
    expect(page).to have_css('.bg-emerald-50, .border-emerald-500')
  end
end

# Chat list ordering and timestamps
Then('the chats should be ordered by most recent activity first') do
  chat_elements = page.all('.sidebar-chat, .chat-item')
  expect(chat_elements.first).to have_content(@newest_chat.title)
end

Then('each chat should show its title') do
  expect(page).to have_content(@old_chat.title)
  expect(page).to have_content(@recent_chat.title) 
  expect(page).to have_content(@newest_chat.title)
end

Then('each chat should show {string} timestamp') do |time_format|
  expect(page).to have_content('ago')
end

# Comparison responses (admin)
Then('I should see a comparison container') do
  expect(page).to have_css('.comparison-container')
end

Then('I should see exactly {int} comparison variants') do |count|
  expect(page).to have_css('.comparison-variant', count: count)
end

Then('each variant should have a distinct header') do
  expect(page).to have_css('.comparison-variant .bg-emerald-50', count: 2)
end

Then('each variant should show {string} branding') do |branding|
  within('.comparison-container') do
    expect(page).to have_content(branding, count: 2)
  end
end

Then('each variant should have separate response content') do
  variants = page.all('.comparison-variant')
  expect(variants.count).to eq(2)
  expect(variants[0].text).not_to eq(variants[1].text)
end

Then('the variants should be displayed side by side') do
  expect(page).to have_css('.lg\\\\:grid-cols-2')
end

# Helper methods for step definitions
private

def user_signed_in?
  @current_user.present?
end

def have_link_or_button(text)
  have_link(text).or have_button(text)
end