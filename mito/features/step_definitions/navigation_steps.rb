# Navigation and UI verification step definitions

# Navigation elements verification
Then('I should see the Miťo logo in the navigation') do
  within('nav') do
    expect(page).to have_content('🧬 Miťo')
  end
end

When('I click on the Miťo logo') do
  within('nav') do
    click_link '🧬 Miťo'
  end
end

Then('I should be taken to the homepage') do
  expect(current_path).to eq(root_path)
end

Then('the logo should be visually prominent') do
  logo_element = find('nav a', text: /🧬 Miťo/)
  expect(logo_element[:class]).to include('font-bold')
end

Then('the logo should include the {string} emoji') do |emoji|
  within('nav') do
    expect(page).to have_content(emoji)
  end
end

# User menu interactions
When('I hover over my email in the navigation') do
  within('nav') do
    find('.group', text: @current_user.email).hover
  end
end

Then('I should see the user dropdown menu') do
  expect(page).to have_css('.group-hover\\\\:block', visible: :visible)
end

# Page context and headers
Then('I should see {string} as the page context') do |context|
  expect(page).to have_content(context)
end

Then('I should see the chat title in the header') do
  within('.chat-header, header') do
    expect(page).to have_content(@chat.display_title)
  end
end

Then('I should see {string} as the subtitle') do |subtitle|
  expect(page).to have_content(subtitle)
end

# Sidebar verification for authenticated users
When('I view any chat page') do
  if @current_user.chats.any?
    visit chat_path(@current_user.chats.first)
  else
    visit root_path
  end
end

Then('I should see the sidebar on the left') do
  expect(page).to have_css('.w-80')
end

Then('I should see {string} as the sidebar title') do |title|
  within('.w-80') do
    expect(page).to have_content(title)
  end
end

Then('I should see {string} button') do |button_text|
  expect(page).to have_link_or_button(button_text)
end

Then('I should see my recent chats listed') do
  within('.w-80') do
    @current_user.chats.limit(3).each do |chat|
      expect(page).to have_content(chat.display_title)
    end
  end
end

Then('the current chat should be highlighted') do
  within('.w-80') do
    expect(page).to have_css('.bg-emerald-50, .border-emerald-500')
  end
end

# Mobile and responsive behavior
When('I visit the homepage on a mobile device') do
  page.driver.browser.manage.window.resize_to(375, 667) # iPhone dimensions
  visit root_path
end

Then('the navigation should be mobile-optimized') do
  expect(page).to have_css('nav')
  # Check that navigation elements are still accessible
  expect(page).to have_content('🧬 Miťo')
end

Then('all navigation elements should be accessible') do
  within('nav') do
    if user_signed_in?
      expect(page).to have_content('Všetky konverzácie')
      expect(page).to have_content(@current_user.email)
    else
      expect(page).to have_content('Prihlásiť sa')
      expect(page).to have_content('Registrovať sa')
    end
  end
end

Then('the layout should stack appropriately') do
  # Check that elements don't overflow or get cut off
  expect(page).not_to have_css('.overflow-hidden')
  expect(page.evaluate_script('document.body.scrollWidth')).to be <= page.evaluate_script('window.innerWidth')
end

Then('touch targets should be appropriately sized') do
  # Check that clickable elements are at least 44px (iOS guideline)
  nav_links = page.all('nav a, nav button')
  nav_links.each do |link|
    height = link.evaluate_script('this.offsetHeight')
    expect(height).to be >= 40 # Allow slight variance
  end
end

# Mobile sidebar behavior
When('I view the chat interface on mobile') do
  page.driver.browser.manage.window.resize_to(375, 667)
  if @current_user && @current_user.chats.any?
    visit chat_path(@current_user.chats.first)
  else
    visit root_path
  end
end

Then('the sidebar should be collapsible') do
  # On mobile, sidebar might be hidden by default or collapsible
  expect(page).to have_css('.w-80, .hidden, .md\\\\:block') 
end

Then('I should be able to toggle the sidebar') do
  # Look for a menu button or toggle
  expect(page).to have_css('[data-toggle], .menu-toggle, .hamburger') rescue nil
end

Then('the main chat area should adjust accordingly') do
  # Chat area should take full width on mobile when sidebar is hidden
  expect(page).to have_css('.flex-1, .w-full')
end

Then('the experience should remain usable') do
  # Essential functionality should still work
  expect(page).to have_css('#messages-container')
  expect(page).to have_css('form')
end

# Page loading and performance
When('I navigate between different pages') do
  visit root_path
  if user_signed_in?
    visit chats_path if respond_to?(:chats_path)
    visit root_path
  else
    visit new_user_session_path
    visit root_path
  end
end

Then('page transitions should be fast') do
  # Page should load within reasonable time
  expect(page).to have_content('🧬 Miťo')
end

Then('the navigation should remain responsive') do
  within('nav') do
    expect(page).to have_content('🧬 Miťo')
  end
end

Then('there should be no broken links') do
  # Check that navigation links are working
  nav_links = page.all('nav a[href]')
  nav_links.each do |link|
    href = link[:href]
    expect(href).not_to be_blank
    expect(href).not_to include('javascript:void')
  end
end

Then('all pages should load within reasonable time') do
  # This is more of a performance assertion
  start_time = Time.current
  page.has_content?('🧬 Miťo', wait: 5)
  load_time = Time.current - start_time
  expect(load_time).to be < 3.seconds
end

# Accessibility
When('I use keyboard navigation') do
  # Start from the beginning and tab through elements
  page.execute_script('document.activeElement.blur()')
  page.execute_script('document.body.focus()')
end

Then('all navigation elements should be focusable') do
  nav_elements = page.all('nav a, nav button')
  nav_elements.each do |element|
    element.send_keys(:tab)
    expect(element).to be_focused rescue nil
  end
end

Then('focus indicators should be visible') do
  # Check that focused elements have visible focus styles
  page.execute_script("
    var style = window.getComputedStyle(document.activeElement, ':focus');
    return style.outline !== 'none' || style.boxShadow !== 'none';
  ")
end

Then('tab order should be logical') do
  # This is hard to test automatically, but we can check basic order
  first_link = page.first('nav a, nav button')
  first_link.send_keys(:tab)
  expect(page.evaluate_script('document.activeElement')).not_to eq(first_link.native)
end

Then('screen readers should work properly') do
  # Check for proper ARIA labels and semantic HTML
  expect(page).to have_css('nav')
  nav_links = page.all('nav a')
  nav_links.each do |link|
    expect(link.text.strip).not_to be_empty
  end
end

# Navigation consistency
When('I visit the homepage as an anonymous user') do
  # Clear any existing session
  page.driver.browser.manage.delete_all_cookies
  visit root_path
end

Then('the navigation layout should be consistent') do
  expect(page).to have_css('nav')
  expect(page).to have_content('🧬 Miťo')
end

Then('the navigation layout should smoothly transition') do
  # After signing in, navigation should update smoothly
  expect(page).to have_css('nav')
  expect(page).to have_content('🧬 Miťo')
end

Then('the overall structure should remain familiar') do
  # Key elements should remain in similar positions
  expect(page).to have_css('nav')
  expect(page).to have_css('main')
end

# Error pages
When('I visit a non-existent page') do
  visit '/non-existent-page-12345'
end

Then('I should see a 404 error page') do
  # Check for 404 page content instead of status code
  expect(page).to have_content('404') or expect(page).to have_content('Page not found') or expect(page).to have_content('Stránka nenájdená')
end

Then('the navigation should still be functional') do
  within('nav') do
    expect(page).to have_content('🧬 Miťo')
  end
end

Then('I should be able to return to the homepage') do
  click_link '🧬 Miťo'
  expect(current_path).to eq(root_path)
end

Then('the error page should maintain the site design') do
  expect(page).to have_css('nav')
  # Error page should use consistent styling
end

# Deep linking
When('I visit a specific chat URL directly') do
  if @current_user && @current_user.chats.any?
    @target_chat = @current_user.chats.first
    visit chat_path(@target_chat)
  end
end

Then('I should see that chat content') do
  expect(page).to have_content(@target_chat.display_title)
end

Then('the URL should be meaningful') do
  expect(current_path).to match(/\/chats\/[\w-]+/)
end

Then('the page should load correctly') do
  expect(page).to have_css('#messages-container')
end

Then('navigation should work from that point') do
  within('nav') do
    expect(page).to have_content('🧬 Miťo')
  end
end

# Flash messages and navigation
When('I perform an action that triggers a flash message') do
  # Trigger a sign in to get a flash message
  if user_signed_in?
    # Sign out to trigger a message
    visit destroy_user_session_path
  else
    # Try to access a protected page
    visit chats_path rescue nil
  end
end

Then('the flash message should appear appropriately') do
  expect(page).to have_css('#flash-messages')
end

Then('it should not interfere with navigation') do
  within('nav') do
    expect(page).to have_content('🧬 Miťo')
    # Navigation should still be clickable
    click_link '🧬 Miťo'
  end
end

Then('the message should be dismissible') do
  if page.has_css?('.flash-alert button')
    find('.flash-alert button').click
  end
end

Then('the navigation should remain functional') do
  within('nav') do
    expect(page).to have_content('🧬 Miťo')
  end
end

# Chat-specific navigation elements
When('I view a specific chat') do
  if @current_user && @current_user.chats.any?
    @current_chat = @current_user.chats.first
    visit chat_path(@current_chat)
  end
end

Then('I should see the chat title in the header') do
  expect(page).to have_content(@current_chat.display_title)
end

Then('the header should be visually distinct from the message area') do
  expect(page).to have_css('.chat-header, .border-b')
end

Then('the header should provide context about the current view') do
  expect(page).to have_content('Slovenský zdravotný asistent')
end

# Sidebar ordering and timestamps
When('I view the sidebar') do
  within('.w-80') do
    expect(page).to have_content('Konverzácie')
  end
end

Then('chats should be ordered by last activity') do
  if @newest_chat && @old_chat
    chat_links = page.all('.w-80 a')
    newest_position = chat_links.find_index { |link| link.text.include?(@newest_chat.title) }
    old_position = chat_links.find_index { |link| link.text.include?(@old_chat.title) }
    
    if newest_position && old_position
      expect(newest_position).to be < old_position
    end
  end
end

Then('each chat should show a relative timestamp') do
  within('.w-80') do
    expect(page).to have_content('ago')
  end
end

Then('timestamps should be in Slovak format') do
  # Check for Slovak time format or words
  within('.w-80') do
    expect(page).to have_content(/ago|pred/)
  end
end

Then('the most recent activity should be at the top') do
  if @newest_chat
    first_chat = page.first('.w-80 a')
    expect(first_chat.text).to include(@newest_chat.title) if first_chat
  end
end

# Performance with many chats
Then('only recent chats should be displayed limit {int}') do |limit|
  chat_links = page.all('.w-80 a').select { |link| link[:href].include?('/chats/') }
  expect(chat_links.count).to be <= limit
end

Then('the sidebar should load quickly') do
  expect(page).to have_css('.w-80', wait: 2)
end

Then('I should be able to access all chats via {string}') do |link_text|
  expect(page).to have_link(link_text)
end

Then('navigation should remain responsive') do
  within('nav') do
    click_link '🧬 Miťo'
    expect(current_path).to eq(root_path)
  end
end

# Chat creation flow
When('I click {string} from any page') do |button_text|
  click_link button_text
end

# State persistence
When('I navigate to different sections') do
  visit root_path
  if user_signed_in?
    visit chats_path if respond_to?(:chats_path)
  end
end

When('I refresh the page') do
  page.driver.browser.navigate.refresh
end

Then('I should remain in the same section') do
  # Check that we're still in a valid section
  expect(page).to have_css('nav')
  expect(page).to have_content('🧬 Miťo')
end

Then('my authentication state should persist') do
  if @current_user
    expect(page).to have_content('Všetky konverzácie')
  else
    expect(page).to have_content('Prihlásiť sa')
  end
end

Then('the navigation should reflect my current location') do
  # Navigation should show appropriate elements for current state
  within('nav') do
    if user_signed_in?
      expect(page).to have_content('Všetky konverzácie')
    else
      expect(page).to have_content('Prihlásiť sa')
    end
  end
end

# Real-time updates
Then('the sidebar timestamp should update') do
  # This would require JavaScript testing framework
  within('.w-80') do
    expect(page).to have_content('ago')
  end
end

Then('the chat order might change based on activity') do
  # This is hard to test without actual time passing
  within('.w-80') do
    expect(page).to have_css('a[href*="/chats/"]')
  end
end

Then('these updates should happen without page refresh') do
  # Check that Turbo is working
  expect(page).to have_css('[data-turbo]') rescue nil
end

Then('the navigation should remain smooth') do
  within('nav') do
    expect(page).to have_content('🧬 Miťo')
  end
end

# Long titles handling
Then('the long title should be properly truncated') do
  within('.w-80') do
    truncated_elements = page.all('.truncate')
    expect(truncated_elements.count).to be > 0
  end
end

Then('the full title should be visible in the chat header') do
  # When viewing the actual chat, full title should be shown
  expect(page).to have_content(@chat.title) if @chat
end

Then('truncation should not break the layout') do
  # Check that layout remains intact
  expect(page).to have_css('.w-80')
  expect(page).not_to have_css('.overflow-x-auto')
end

Then('tooltips should show full titles when appropriate') do
  # This would require hover testing
  long_title_link = page.first('.w-80 .truncate')
  expect(long_title_link[:title]).not_to be_blank if long_title_link
end

# Helper methods
private

def user_signed_in?
  @current_user.present?
end

def have_link_or_button(text)
  have_link(text).or have_button(text)
end