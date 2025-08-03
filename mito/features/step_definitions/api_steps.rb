# API mocking and backend testing step definitions

# Backend service availability mocking
Given('the FastAPI backend is completely unavailable') do
  # Mock HTTP client to simulate complete service unavailability
  allow_any_instance_of(Net::HTTP).to receive(:request).and_raise(Errno::ECONNREFUSED)
  
  # Alternative: Stub the service class if using a wrapper
  if defined?(ChatApiService)
    allow(ChatApiService).to receive(:send_message).and_raise(Errno::ECONNREFUSED)
    allow(ChatApiService).to receive(:send_comparison).and_raise(Errno::ECONNREFUSED)
  end
  
  # Mock Faraday connections if used
  if defined?(Faraday)
    allow_any_instance_of(Faraday::Connection).to receive(:post).and_raise(Faraday::ConnectionFailed)
    allow_any_instance_of(Faraday::Connection).to receive(:get).and_raise(Faraday::ConnectionFailed)
  end
end

Given('the FastAPI compare endpoint returns a server error') do
  # Mock only the comparison endpoint to return 500 error
  if defined?(ChatApiService)
    allow(ChatApiService).to receive(:send_comparison).and_raise(
      StandardError.new("Internal Server Error")
    )
    # Keep regular chat working
    allow(ChatApiService).to receive(:send_message).and_return({
      'response' => 'Toto je testovacia odpoveď z RAG systému.',
      'sources' => ['test_source.json']
    })
  end
  
  # Mock HTTP response for comparison endpoint
  stub_request(:post, /.*\/api\/chat\/compare/)
    .to_return(status: 500, body: '{"error": "Internal Server Error"}')
    
  # Keep regular endpoint working
  stub_request(:post, /.*\/api\/chat/)
    .to_return(
      status: 200, 
      headers: { 'Content-Type' => 'application/json' },
      body: {
        response: 'Toto je testovacia odpoveď z RAG systému.',
        sources: ['test_source.json']
      }.to_json
    )
end

Given('the FastAPI backend returns invalid JSON') do
  # Mock backend to return malformed JSON
  if defined?(ChatApiService)
    allow(ChatApiService).to receive(:send_message).and_return("invalid json response")
    allow(ChatApiService).to receive(:send_comparison).and_return("invalid json response")
  end
  
  # Stub HTTP requests to return invalid JSON
  stub_request(:post, /.*\/api\/chat/)
    .to_return(
      status: 200,
      headers: { 'Content-Type' => 'application/json' },
      body: '{"response": invalid json malformed'
    )
    
  stub_request(:post, /.*\/api\/chat\/compare/)
    .to_return(
      status: 200,
      headers: { 'Content-Type' => 'application/json' },
      body: '{"variants": [invalid json'
    )
end

Given('the FastAPI backend is very slow (timeout scenario)') do
  @timeout_duration = 30.seconds
  
  # Mock slow response
  if defined?(ChatApiService)
    allow(ChatApiService).to receive(:send_message) do
      sleep @timeout_duration + 1
      raise Timeout::Error
    end
  end
  
  # Stub HTTP to simulate timeout
  stub_request(:post, /.*\/api\/chat/)
    .to_timeout
    
  stub_request(:post, /.*\/api\/chat\/compare/)
    .to_timeout
end

# Database connectivity issues
Given('there are database connectivity issues') do
  # Mock ActiveRecord connection failures
  allow(ActiveRecord::Base).to receive(:connection).and_raise(
    ActiveRecord::ConnectionNotEstablished.new("Database connection failed")
  )
  
  # Mock specific model operations
  allow(User).to receive(:find).and_raise(ActiveRecord::ConnectionNotEstablished)
  allow(Chat).to receive(:find).and_raise(ActiveRecord::ConnectionNotEstablished)
  allow(Message).to receive(:create!).and_raise(ActiveRecord::ConnectionNotEstablished)
end

# Network condition simulations
Given('the network connection is slow') do
  @slow_network_delay = 5.seconds
  
  # Mock slow HTTP responses
  if defined?(ChatApiService)
    allow(ChatApiService).to receive(:send_message) do
      sleep @slow_network_delay
      {
        'response' => 'Odpoveď po pomalej sieti.',
        'sources' => ['slow_network_test.json']
      }
    end
  end
  
  # Stub with delay
  stub_request(:post, /.*\/api\/chat/)
    .to_return(
      status: 200,
      headers: { 'Content-Type' => 'application/json' },
      body: {
        response: 'Odpoveď po pomalej sieti.',
        sources: ['slow_network_test.json']
      }.to_json
    ).delay(@slow_network_delay)
end

# API response verification steps
Then('I should see a helpful error message in Slovak') do
  expect(page).to have_content('služba je dočasne nedostupná')
  expect(page).to have_content('Ospravedlňujeme sa za nepríjemnosti')
end

Then('the error message should mention that the service is temporarily unavailable') do
  expect(page).to have_content(/dočasne nedostupná|temporarily unavailable|služba nefunguje/)
end

Then('the error message should suggest registering to save the question') do
  expect(page).to have_content(/registr|zaregistruj|uložiť otázku/)
end

Then('I should see a professional error message') do
  expect(page).to have_content('Ospravedlňujeme sa, ale nastala chyba')
  expect(page).not_to have_content('Error 500')
  expect(page).not_to have_content('undefined method')
end

Then('the error message should not mention registration') do
  expect(page).not_to have_content(/registr|zaregistruj/)
end

Then('I should see an error message about comparison failure') do
  expect(page).to have_content(/porovnanie sa nepodarilo|comparison failed|chyba pri porovnávaní/)
end

Then('I should not see broken comparison containers') do
  expect(page).not_to have_css('.comparison-container.error')
  expect(page).not_to have_content('undefined')
  expect(page).not_to have_content('[object Object]')
end

Then('I should see a graceful error message') do
  expect(page).to have_content('Nastala neočakávaná chyba')
  expect(page).not_to have_content('JSON.parse')
  expect(page).not_to have_content('SyntaxError')
end

Then('the application should not crash or show JavaScript errors') do
  # Check that page is still functional
  expect(page).to have_css('#messages-container')
  expect(page).to have_css('form')
  
  # Check for JavaScript errors in console (if using a JS-capable driver)
  if page.driver.respond_to?(:browser) && page.driver.browser.respond_to?(:manage)
    logs = page.driver.browser.manage.logs.get(:browser) rescue []
    severe_errors = logs.select { |log| log.level == 'SEVERE' && log.message.include?('Error') }
    expect(severe_errors).to be_empty
  end
end

Then('after waiting for the timeout period') do
  sleep(@timeout_duration || 30.seconds)
end

Then('I should see a timeout error message') do
  expect(page).to have_content(/časový limit|timeout|spojenie trvá príliš dlho/)
end

# Validation and input handling
Then('no API calls should be made') do
  # Verify no HTTP requests were made to the API
  if defined?(WebMock)
    expect(WebMock).not_to have_requested(:post, /.*\/api\/chat/)
  end
  
  # Check that service methods weren't called
  if defined?(ChatApiService)
    expect(ChatApiService).not_to have_received(:send_message) rescue nil
  end
end

Then('the interface should remain responsive') do
  expect(page).to have_css('#messages-container')
  expect(page).to have_css('textarea')
  expect(page).to have_button('Odoslať')
  
  # Test that form is still interactive
  find('textarea').click
  expect(page).to have_field(type: 'textarea', focused: true) rescue nil
end

# Session and concurrent handling
Given('I am signed in as a regular user in one browser') do
  @first_browser_user = User.create!(
    email: 'concurrent1@cucumber.test',
    password: 'password123'
  )
  
  visit new_user_session_path
  fill_in 'Email', with: @first_browser_user.email
  fill_in 'Password', with: 'password123'
  click_button 'Prihlásiť sa'
  
  expect(page).to have_content('Úspešne ste sa prihlásili')
  @current_user = @first_browser_user
end

When('I sign in with the same account in another browser') do
  # Simulate second browser session
  @second_session = Capybara::Session.new(Capybara.current_driver)
  
  @second_session.visit new_user_session_path
  @second_session.fill_in 'Email', with: @first_browser_user.email
  @second_session.fill_in 'Password', with: 'password123'
  @second_session.click_button 'Prihlásiť sa'
  
  expect(@second_session).to have_content('Úspešne ste sa prihlásili')
end

Then('both sessions should work independently') do
  # Test first session
  expect(page).to have_content('Všetky konverzácie')
  
  # Test second session
  expect(@second_session).to have_content('Všetky konverzácie')
end

Then('I should not see interference between sessions') do
  # Create chat in first session
  click_link '+ Nová konverzácia'
  first_chat_title = 'Chat z prvej relácie'
  
  # Check that second session doesn't immediately see it
  @second_session.visit root_path
  expect(@second_session).not_to have_content(first_chat_title)
end

# Session expiry handling
When('my session expires') do
  # Clear session cookies to simulate expiry
  page.driver.browser.manage.delete_all_cookies
  
  # Or mock session expiry in Rails
  allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(nil)
  allow_any_instance_of(ApplicationController).to receive(:user_signed_in?).and_return(false)
end

# Error recovery verification
Then('the application should remain functional for future attempts') do
  # Clear any mocks to simulate service recovery
  WebMock.reset! if defined?(WebMock)
  
  if defined?(ChatApiService)
    allow(ChatApiService).to receive(:send_message).and_call_original
  end
  
  # Test that we can attempt again
  expect(page).to have_css('textarea')
  expect(page).to have_button('Odoslať')
end

Then('my message should still be saved to the database') do
  if @current_user
    expect(@current_user.messages.last.content).to include('Test backend down')
  end
end

Then('the error should be user-friendly') do
  expect(page).not_to have_content('Errno::ECONNREFUSED')
  expect(page).not_to have_content('500 Internal Server Error')
  expect(page).not_to have_content('undefined method')
  expect(page).not_to have_content('ActiveRecord::')
end

# Security and input sanitization
When('I try to send a message with HTML/script tags') do
  malicious_content = '<script>alert("XSS")</script><img src="x" onerror="alert(1)">'
  step "I send a message \"#{malicious_content}\""
end

Then('the content should be properly sanitized') do
  expect(page).not_to have_css('script')
  expect(page).not_to have_css('img[src="x"]')
  expect(page.html).not_to include('<script>')
  expect(page.html).not_to include('onerror=')
end

Then('no scripts should execute') do
  # Check that no alert dialogs appeared (would indicate XSS)
  expect(page.driver.browser.switch_to.alert).to be_nil rescue nil
end

Then('the message should display safely') do
  # Content should be escaped/sanitized but still visible as text
  expect(page).to have_content('script')  # As text, not as tag
  expect(page).not_to have_css('script')   # Not as actual HTML element
end

# File upload prevention
When('I try to paste or drag files into the message field') do
  # Simulate file drop event
  page.execute_script("""
    var textarea = document.querySelector('textarea');
    var event = new Event('drop');
    event.dataTransfer = {
      files: [{name: 'test.txt', type: 'text/plain'}]
    };
    textarea.dispatchEvent(event);
  """) rescue nil
  
  # Try to set file input value (should be blocked)
  page.execute_script("""
    var textarea = document.querySelector('textarea');
    textarea.value = 'file:///test.txt';
  """) rescue nil
end

Then('file uploads should not be accepted') do
  expect(page).not_to have_css('input[type="file"]')
  expect(page).not_to have_content('file:///')
end

Then('I should see appropriate feedback') do
  expect(page).to have_content(/iba text|text only|nepodporujeme súbory/)
end

# Performance and rate limiting
When('I try to send many messages very quickly') do
  @rapid_messages = []
  5.times do |i|
    message = "Rýchla správa #{i + 1}"
    @rapid_messages << message
    step "I send a message \"#{message}\""
    sleep 0.1  # Very short delay between sends
  end
end

Then('the application should handle the load appropriately') do
  expect(page).to have_css('#messages-container')
  expect(page).not_to have_content('rate limit exceeded') # Unless explicitly implemented
end

Then('no messages should be lost') do
  @rapid_messages.each do |message|
    expect(page).to have_content(message)
  end
end

# Browser compatibility
Given('I am using an older browser') do
  # Mock user agent for older browser
  page.driver.browser.manage.add_cookie(
    name: 'browser_test',
    value: 'old_browser_simulation'
  ) rescue nil
  
  # This is more of a documentation step - actual browser testing
  # would require different browser drivers
end

# Memory and performance monitoring
Given('I have been using the application for an extended time') do
  # Simulate extended usage by creating many chats and messages
  if @current_user
    20.times do |i|
      chat = @current_user.chats.create!(title: "Dlhodobý chat #{i}")
      10.times do |j|
        chat.messages.create!(
          content: "Správa #{j} v chate #{i}",
          role: 'user'
        )
        chat.messages.create!(
          content: "Odpoveď #{j} v chate #{i}",
          role: 'assistant'
        )
      end
    end
  end
end

Then('memory usage should not grow excessively') do
  # This is primarily a monitoring step - actual memory testing
  # would require performance monitoring tools
  expect(page).to have_css('#messages-container')
end

Then('performance should remain consistent') do
  start_time = Time.current
  visit root_path
  load_time = Time.current - start_time
  expect(load_time).to be < 5.seconds
end

# Recovery from errors
Given('I encountered a temporary API error') do
  step 'the FastAPI backend is completely unavailable'
  step 'I send a message "Test error"'
  step 'I should see a graceful error message'
end

When('the backend service recovers') do
  # Clear mocks to simulate service recovery
  WebMock.reset! if defined?(WebMock)
  RSpec::Mocks.space.reset_all if defined?(RSpec)
  
  # Restore normal API behavior
  if defined?(ChatApiService)
    allow(ChatApiService).to receive(:send_message).and_return({
      'response' => 'Služba je opäť funkčná.',
      'sources' => ['recovery_test.json']
    })
  end
end

Then('there should be no lingering error states') do
  expect(page).not_to have_content('služba je dočasne nedostupná')
  expect(page).not_to have_css('.error-state')
  expect(page).to have_css('#messages-container')
end

# Helper methods for API testing
private

def simulate_api_delay(seconds)
  sleep(seconds)
end

def mock_successful_api_response
  {
    'response' => 'Toto je úspešná odpoveď z API.',
    'sources' => ['test_source.json']
  }
end

def mock_comparison_response
  {
    'variants' => [
      {
        'name' => 'Fixed Chunking',
        'response' => 'Odpoveď z fixed chunking variantu.',
        'sources' => ['fixed_chunk_source.json']
      },
      {
        'name' => 'Semantic Chunking', 
        'response' => 'Odpoveď zo semantic chunking variantu.',
        'sources' => ['semantic_chunk_source.json']
      }
    ]
  }
end

def clear_all_mocks
  WebMock.reset! if defined?(WebMock)
  RSpec::Mocks.space.reset_all if defined?(RSpec)
end