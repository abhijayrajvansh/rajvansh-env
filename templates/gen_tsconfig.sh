GREEN='\033[0;32m'
RESET='\033[0m'
alias greentick='echo -n ${GREEN}✔ ${RESET}'

echo '
{
  "compilerOptions": {
      "module": "commonjs",
      "esModuleInterop": true,
      "allowSyntheticDefaultImports": true,
      "target": "es6",
      "noImplicitAny": true,
      "moduleResolution": "node",
      "sourceMap": true,
      "outDir": "dist",
      "baseUrl": ".",
      "paths": {
          "*": [
              "node_modules/*",
              "src/types/*"
          ]
      }
  },
  "include": [
      "src/**/*"
  ]
}
' >> tsconfig.json

greentick; echo 'tsconfig.json file generated.'