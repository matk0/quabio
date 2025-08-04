# Seed model pricing data
ModelPricing.set_pricing('gpt-4-turbo-preview', 0.01, 0.03)
ModelPricing.set_pricing('gpt-4-turbo', 0.01, 0.03)
ModelPricing.set_pricing('gpt-4', 0.03, 0.06)
ModelPricing.set_pricing('gpt-3.5-turbo', 0.0015, 0.002)

puts "Seeded model pricing data"