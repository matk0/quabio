/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./src/**/*.{js,jsx,ts,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        'mito-blue': '#2563eb',
        'mito-blue-dark': '#1d4ed8',
        'mito-gray': '#f8fafc',
        'mito-gray-dark': '#64748b',
      },
      fontFamily: {
        'sans': ['Inter', 'system-ui', 'sans-serif'],
      },
    },
  },
  plugins: [],
}