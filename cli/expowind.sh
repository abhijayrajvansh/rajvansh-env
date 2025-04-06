#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "Enter the name of your new Expo project:"
read PROJECT_NAME

# Step 1: Initialize Expo app
npx create-expo-app@latest "$PROJECT_NAME"
cd "$PROJECT_NAME"

# Step 2: Reset project (auto-confirm 'y' to prompt)
echo "Running reset-project script..."
echo "y" | npm run reset-project

# Step 3: Install NativeWind and related packages
echo "Installing NativeWind-related dependencies..."
npm install nativewind tailwindcss react-native-reanimated react-native-safe-area-context

# Step 4: Initialize TailwindCSS
echo "Initializing TailwindCSS..."
npx tailwindcss init

# Step 5: Configure tailwind.config.js
cat > tailwind.config.js <<EOL
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["./app/**/*.{js,jsx,ts,tsx}", "./components/**/*.{js,jsx,ts,tsx}"],
  presets: [require("nativewind/preset")],
  theme: {
    extend: {},
  },
  plugins: [],
}
EOL

# Step 6: Create global styles
mkdir -p styles
cat > styles/global.css <<EOL
@tailwind base;
@tailwind components;
@tailwind utilities;
EOL

# Step 7: Create babel.config.js
cat > babel.config.js <<EOL
module.exports = function (api) {
  api.cache(true);
  return {
    presets: [
      ["babel-preset-expo", { jsxImportSource: "nativewind" }],
      "nativewind/babel",
    ],
  };
};
EOL

# Step 8: Create metro.config.js
cat > metro.config.js <<EOL
const { getDefaultConfig } = require("expo/metro-config");
const { withNativeWind } = require('nativewind/metro');

const config = getDefaultConfig(__dirname);

module.exports = withNativeWind(config, { input: './styles/global.css' });
EOL

# Step 9: Update app/_layout.tsx
mkdir -p app
cat > app/_layout.tsx <<EOL
import { Stack } from "expo-router";
import "../styles/global.css";

export default function RootLayout() {
  return <Stack />;
}
EOL

# Step 10: Create nativewind-env.d.ts
cat > nativewind-env.d.ts <<EOL
/// <reference types="nativewind/types" />
EOL

# Step 11: Update app/index.tsx
cat > app/index.tsx <<EOL
import { Text, View } from "react-native";

export default function Index() {
  return (
    <View className="flex-1 items-center justify-center">
      <Text className="text-3xl font-medium text-black">welcome back mr. rajvansh</Text>
    </View>
  );
}
EOL

# Step 12: Cleanup app-example directory if it exists
if [ -d "app-example" ]; then
  echo "Removing app-example directory..."
  rm -rf app-example
fi

echo "✅ Expo project with NativeWind and TailwindCSS has been successfully set up!"

