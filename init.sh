#!/bin/bash
set -o errexit

# Set current working directory to script directory
script_dir="$(dirname "$(realpath "$0")")"
cd "$script_dir"

# Amend initial commit message
git commit --amend --message 'chore: clone template repository'
git push --force

# Enable GitHub workflows
mkdir .github
mv workflows .github

# Prompt for repository name
read -rp 'Enter repository name: ' repo_name

# Validate repository name with regex
if [[ ! "$repo_name" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
  >&2 echo 'Error: Invalid repository name'
  >&2 echo 'Use kebab-case (e.g. hello-world)'
  exit 1
fi

# Perform in-place text substitutions
perl -i -pe "s/2024/$(date +%Y)/" LICENSE.txt
perl -i -pe "s/¤REPO_NAME¤/${repo_name}/" vercel.json

# Install Prettier with Tailwind CSS plugin
npm install --save-dev --save-exact prettier prettier-plugin-tailwindcss

# Install ESLint with TypeScript support
npm install --save-dev eslint @eslint/js @types/eslint__js typescript typescript-eslint

### START CLIENT SETUP ########################################################
# Init Angular client (CLI will prompt for SSR)
ng new --skip-git --skip-tests --directory=client --inline-style --style=css "$repo_name"
cd client

# Configure Angular project
ng config "projects.${repo_name}.schematics.@schematics/angular:component.displayBlock" true
ng config "projects.${repo_name}.schematics.@schematics/angular:component.changeDetection" OnPush

# Add Angular environments
ng generate environments

# Install Tailwind CSS
npm install --save-dev tailwindcss postcss autoprefixer

# Add Tailwind CSS configuration
cat > tailwind.config.ts << EOF
import type { Config } from "tailwindcss";

export default {
  content: ["./src/**/*.{html,ts}"],
  theme: {
    extend: {},
  },
  plugins: [],
} satisfies Config;
EOF

# Reset global styles with Tailwind CSS
cat > src/styles.css << EOF
@tailwind base;
@tailwind components;
@tailwind utilities;
EOF

# Reset root component template
cat > src/app/app.component.html << EOF
<p>Deployment successful!</p>
<router-outlet />
EOF

# Add Vercel deployment npm script
# shellcheck disable=SC2016
npm pkg set scripts.vercel:build='ng version && ng build --configuration \"$VERCEL_ENV\"'

cd "$script_dir"
### END CLIENT SETUP ##########################################################

### START SERVER SETUP ########################################################
cd server

# Install TypeScript with Node.js v20 configuration
npm install --save-dev typescript @types/node@20 @tsconfig/node20

# Install Express
npm install express
npm install --save-dev @types/express

# Install CORS middleware
npm install cors
npm install --save-dev @types/cors

cd "$script_dir"
### END SERVER SETUP ##########################################################

# Commit changes
git add .
git commit -m 'build: initialize project'

echo 'Project initialized successfully!'
