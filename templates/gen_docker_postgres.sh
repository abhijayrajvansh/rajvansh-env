GREEN='\033[0;32m'
RESET='\033[0m'
alias greentick='echo -n ${GREEN}✔ ${RESET}'

echo 'services:
  db:
    image: postgres:latest
    container_name: docker-postgres
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: postgres
    ports:
      - "5432:5432"
' >> docker-compose.yaml

greentick; echo 'postgres service added to docker-compose.yaml.'
echo 'DATABASE_URL="postgresql://postgres:postgres@localhost:5432/postgres"'
