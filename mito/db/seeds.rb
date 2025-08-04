# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Create admin user
admin_email = "admin@mito.sk"
admin_password = "admin123"

admin_user = User.find_or_create_by!(email: admin_email) do |user|
  user.password = admin_password
  user.password_confirmation = admin_password
  user.admin = true
end

if admin_user.persisted?
  puts " Admin user created/found:"
  puts "   Email: #{admin_user.email}"
  puts "   Admin: #{admin_user.admin?}"
  puts "   Password: #{admin_password}"
else
  puts "L Failed to create admin user:"
  puts admin_user.errors.full_messages
end

# Create model pricing for GPT-4 Turbo
gpt4_turbo_pricing = ModelPricing.find_or_create_by!(
  model: "gpt-4-turbo-preview",
  is_active: true
) do |pricing|
  pricing.input_cost_per_1k_tokens = 0.01   # $0.01 per 1K input tokens
  pricing.output_cost_per_1k_tokens = 0.03  # $0.03 per 1K output tokens
  pricing.effective_date = Date.current
end

if gpt4_turbo_pricing.persisted?
  puts " GPT-4 Turbo pricing created/found:"
  puts "   Model: #{gpt4_turbo_pricing.model}"
  puts "   Input cost: $#{gpt4_turbo_pricing.input_cost_per_1k_tokens}/1K tokens"
  puts "   Output cost: $#{gpt4_turbo_pricing.output_cost_per_1k_tokens}/1K tokens"
else
  puts "L Failed to create GPT-4 Turbo pricing:"
  puts gpt4_turbo_pricing.errors.full_messages
end

puts "\n<1 Seeding completed!"